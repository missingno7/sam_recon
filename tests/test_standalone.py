"""Merge boundaries, round trips and standalone acceptance; no DOS tools."""
import copy
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import mergeeps as me
import standalone as st

WORKER = me.ROOT / "build/workers/sol-standalone"


class EpisodeMerge(unittest.TestCase):
    def assert_roundtrip(self, variants, language="pas"):
        merged = me.merge_text(*variants, language=language)
        for ep, variant in zip(me.EPISODES, variants):
            self.assertEqual(me.select_episode(merged, ep, language),
                             me.select_episode(variant, ep, language))
        return merged

    def test_identical_file_appears_once(self):
        text = "program SAM;\nbegin\n  WriteLn('same');\nend.\n"
        self.assertEqual(me.merge_text(text, text, text), text)

    def test_two_equal_episodes_use_one_else_branch(self):
        variants = ["var\n  d_1234: " + typ + ";\n" for typ in ("Byte", "Word", "Word")]
        merged = self.assert_roundtrip(variants)
        self.assertEqual(merged.count("d_1234: Word"), 1)
        self.assertEqual(merged.count("{$IFDEF SAM1}"), 1)
        self.assertIn("{$ELSE}", merged)
        self.assertEqual(merged.count("var\n"), 1)

    def test_three_way_difference_and_distinct_insertions(self):
        variants = ["var\n  a: Byte;\n  " + decl + "\n  z: Word;\n"
                    for decl in ("x: Byte;", "y: Integer;", "w: LongInt;")]
        merged = self.assert_roundtrip(variants)
        for ep in me.EPISODES:
            self.assertIn("{$IFDEF " + ep.upper() + "}", merged)
        self.assertEqual(merged.count("a: Byte;"), 1)
        self.assertEqual(merged.count("z: Word;"), 1)

    def test_insert_delete_at_start_and_end(self):
        variants = ("type\n  A = Byte;\n", "type\n  A = Byte;\n  B = Word;\n", "var\n  Z: Word;\n")
        self.assert_roundtrip(variants)

    def test_parameter_semicolons_and_multiline_record_are_indivisible(self):
        record = "type\n  T = record\n    X: Word;\n    Y: Byte;\n  end;\n"
        atoms = me.pascal_atoms(record + "procedure P(A: Word; B: Byte);\n")
        self.assertIn("  T = record\n    X: Word;\n    Y: Byte;\n  end;\n", atoms)
        self.assertIn("procedure P(A: Word; B: Byte);\n", atoms)
        variants = [record.replace("Y: Byte", "Y: " + typ) for typ in ("Byte", "Word", "LongInt")]
        merged = self.assert_roundtrip(variants)
        # Every branch contains the complete declaration, not a record fragment.
        for ep in me.EPISODES:
            branch = merged.split("{$IFDEF " + ep.upper() + "}\n")[1].split("{$ENDIF}")[0]
            self.assertIn("T = record", branch)
            self.assertIn("end;", branch)

    def test_typed_record_constants_and_variant_records(self):
        text = "type\n  T = record\n    case Byte of\n      0: (A: Word);\n      1: (B: Byte);\n  end;\nconst\n  d_0000: T = (A: 1; B: 2);\n"
        atoms = me.pascal_atoms(text)
        self.assertIn("  d_0000: T = (A: 1; B: 2);\n", atoms)
        self.assert_roundtrip([text, text.replace("A: 1", "A: 3"), text.replace("A: 1", "A: 4")])

    def test_repeat_case_and_if_else_stay_complete_statements(self):
        stmts = ("repeat\n  A := 1;\n  B := 2;\nuntil A = B;\n"
                 "case A of\n  1: B := 3;\n  2: begin B := 4; end;\nend;\n"
                 "if A = 0 then\nbegin\n B := 5;\nend\nelse B := 6;\n")
        self.assertEqual(len(me.pascal_atoms(stmts)), 3)

    def test_different_body_refines_to_whole_statements(self):
        variants = ["begin\n  A := 1;\n  WriteLn('" + v + "');\n  Z := 2;\nend.\n"
                    for v in ("one", "two", "three")]
        merged = self.assert_roundtrip(variants)
        self.assertEqual(merged.count("A := 1;"), 1)
        self.assertEqual(merged.count("Z := 2;"), 1)
        self.assertEqual(merged.count("begin\n"), 1)

    def test_added_routine_does_not_capture_previous_end(self):
        common = "procedure P;\nbegin\n  X := 1;\nend;\n"
        added = "procedure Q;\nbegin\n  X := 2;\nend;\n"
        tail = "begin\n  P;\nend.\n"
        merged = self.assert_roundtrip([common + tail, common + added + tail, common + added + tail])
        self.assertTrue(merged.startswith(common))
        self.assertEqual(merged.count("procedure Q;"), 1)

    def test_comments_strings_and_escaped_quotes_cannot_contain_inserted_directives(self):
        text = "{ comment\n  contains begin; end;\n}\nconst\n  S = 'it''s {$IFDEF SAM1} ; begin';\n"
        changed = text.replace("it's", "it's").replace("it''s", "that''s")
        self.assert_roundtrip([text, changed, changed])
        self.assertIn("{ comment\n  contains begin; end;\n}\n", me.pascal_atoms(text))
        self.assertIn("{$IFDEF SAM1}", me.select_episode(text, "sam2"))

    def test_existing_nested_episode_directives_survive(self):
        body = "begin\n{$IFDEF SAM1}\n  X := 1;\n{$ELSE}\n{$IFDEF SAM2}\n  X := 2;\n{$ELSE}\n  X := 3;\n{$ENDIF}\n{$ENDIF}\nend.\n"
        self.assert_roundtrip(["var\n  Y: Byte;\n" + body, "var\n  Y: Word;\n" + body, "var\n  Y: Word;\n" + body])
        self.assertIn("X := 2;", me.select_episode(body, "sam2"))
        self.assertNotIn("X := 3;", me.select_episode(body, "sam2"))

    def test_crlf_and_asm_continuations(self):
        variants = ["CODE segment byte public\r\n    mov ax," + v + "\r\nCODE ends\r\nend\r\n"
                    for v in ("1", "2", "2")]
        merged = self.assert_roundtrip(variants, "asm")
        self.assertEqual(merged.count("CODE segment"), 1)
        self.assertIn("IFDEF SAM1\n", merged)
        self.assertEqual(me.asm_atoms("db 1,\\\n   2\nend\n"), ["db 1,\\\n   2\n", "end\n"])

    def test_invalid_conditionals_rejected(self):
        for text in ("{$ENDIF}\n", "{$IFDEF SAM1}\n", "{$IFDEF UNKNOWN}\n{$ENDIF}\n"):
            with self.assertRaises(ValueError):
                me.select_episode(text, "sam1")
        with self.assertRaises(ValueError):
            me.pascal_atoms("type T = record X: Word;\n")


class StandaloneRecipe(unittest.TestCase):
    def test_batch_steps_use_same_defines_and_pinned_flags(self):
        options = ["/$S-", "/$I-", "/$R-", "/$B-"]
        batch = me.build_batch(options)
        steps = st.build_steps(batch, "sam3", options)
        self.assertEqual(len(steps), 9)
        self.assertEqual([c for c, _ in steps], ["tasm"] * 6 + ["tpc", "copy", "lzexe"])
        self.assertTrue(all(a[0] == "/DSAM3" for c, a in steps if c == "tasm"))
        self.assertEqual(steps[6][1], ["/M", "/GD", "/DSAM3", *options, "SAM.PAS"])
        self.assertEqual(steps[-1], ("lzexe", ["SAM3.EXE"]))
        for i in range(1, 10):
            self.assertIn(f"if exist U{i}.TPU del U{i}.TPU", batch)

    def test_changed_batch_cannot_silently_build_a_different_recipe(self):
        batch = me.build_batch(["/$S-"])
        for altered in (batch.replace("/$S-", "/$S+"), batch + "patch SAM.EXE\n", batch.replace("/DSAM%1", "")):
            with self.assertRaises(ValueError):
                st.build_steps(altered, "sam1", ["/$S-"])

    def test_source_copy_rejects_prebuilt_tpu(self):
        WORKER.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=WORKER) as d:
            base = Path(d)
            tree, work = base / "game", base / "scratch"
            tree.mkdir(); work.mkdir()
            (tree / "U9.TPU").write_bytes(b"stale")
            with self.assertRaisesRegex(ValueError, "source text only"):
                st.copy_sources(tree, work)

    def test_generated_tree_uses_named_objects_and_no_binary_inputs(self):
        WORKER.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=WORKER) as d:
            base = Path(d)
            variants, asm, game = base / "variants", base / "asm", base / "game"
            asm.mkdir()
            for unit in me.OBJECT_NAMES:
                (asm / (unit + ".asm")).write_text("CODE segment byte public\nCODE ends\nend\n")
            for ep in me.EPISODES:
                directory = variants / ep
                directory.mkdir(parents=True)
                for name in me.PASCAL_FILES:
                    unit = "p" if name == "SAM.PAS" else name[:-4].lower()
                    obj = ("P" if unit == "p" else unit.upper()) + ".OBJ"
                    (directory / name).write_text(("{$L " + obj + "}\n" if unit in me.OBJECT_NAMES else "") + "begin\nend.\n")
            # Exercise a genuinely episode-specific generated ASM variant.
            for ep in me.EPISODES:
                (variants / ep / "U6.ASM").write_text("mov ax," + ep[-1] + "\n")
            manifest = me.make_tree(variants, game, asm)
            self.assertEqual(len(manifest["files"]), 18)
            for unit, obj in me.OBJECT_NAMES.items():
                pas = "SAM.PAS" if unit == "p" else unit.upper() + ".PAS"
                self.assertIn("{$L " + obj + ".OBJ}", (game / pas).read_text())
            for ep in me.EPISODES:
                self.assertEqual(me.select_episode((game / "JOYSTICK.ASM").read_text(), ep, "asm"),
                                 "mov ax," + ep[-1] + "\n")
            self.assertTrue(all(p.suffix.upper() not in (".OBJ", ".EXE", ".TPU") for p in game.iterdir()))


class StandaloneAcceptance(unittest.TestCase):
    def fixture(self):
        comparison = {"data_length": {"actual": 17, "expected": 32},
                      "header": {k: {"equal": True} for k in st.KNOWN_HEADER},
                      "relocations": {"equal": True}, "link_order": {"equal": True},
                      "init_chain": {"equal": True}, "unexpected_segments": ["HEAP"],
                      "zero_length_heap": True, "overlay_size": 0,
                      "segments": [{"original_para": 0, "candidate_para": 0,
                                    "original_size": 4, "candidate_size": 4}],
                      "anchors": [{"equal": True}], "routine_entries": [{"equal": True}]}
        holes = [{"unit": "p", "original_range": [1, 2], "candidate_range": [1, 2],
                  "candidate_bytes": "ff"}]
        return comparison, holes, {"p": {"start": 0}}

    def test_only_documented_residue_is_permitted(self):
        c, holes, segments = self.fixture()
        r = st.verify_comparison(b"abcd", b"aXcd", holes, c, segments)
        self.assertTrue(r["ok"])
        self.assertEqual(r["residue_bytes_differing"], 1)
        self.assertFalse(st.verify_comparison(b"abcd", b"aXcY", holes, c, segments)["ok"])
        self.assertFalse(st.verify_comparison(b"abcd", b"aXc", holes, c, segments)["ok"])

    def test_layout_header_relocations_and_heap_checks_fail_closed(self):
        c, holes, segments = self.fixture()
        for mutate in (lambda x: x["header"]["sp"].update(equal=False),
                       lambda x: x["relocations"].update(equal=False),
                       lambda x: x["init_chain"].update(equal=False),
                       lambda x: x["link_order"].update(equal=False),
                       lambda x: x.update(zero_length_heap=False),
                       lambda x: x.update(unexpected_segments=["OTHER"]),
                       lambda x: x["segments"][0].update(candidate_para=1)):
            bad = copy.deepcopy(c)
            mutate(bad)
            self.assertFalse(st.verify_comparison(b"abcd", b"aXcd", holes, bad, segments)["ok"])

    def test_hole_relocation_or_overlap_cannot_enlarge_exemption(self):
        c, holes, segments = self.fixture()
        changed = copy.deepcopy(holes)
        changed[0]["candidate_range"] = [2, 3]
        for bad in (changed, holes + holes):
            with self.assertRaises(ValueError):
                st.verify_comparison(b"abcd", b"aXcd", bad, c, segments)


if __name__ == "__main__":
    unittest.main()
