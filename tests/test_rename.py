"""Semantic renaming, scope/type resolution and proof gating; no DOS tools."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import rename as rn
import progbuild as pb
import standalone as st
import tpmap


def row(name, confidence="high", **extra):
    return dict(name=name, confidence=confidence, evidence="Observed behavior.", **extra)


def names(**categories):
    result = {k: {} for k in rn.CATEGORIES}
    result.update(categories)
    return result


def proof():
    return dict(ok=True, status="OK", equal_bytes=3, image_size=4,
                differing_bytes=1, residue_bytes_differing=1,
                allowed_residue_bytes=1, outside_residue_count=0,
                checks={"layout": True}, object_holes=[dict(
                    unit="p", original_range=[1, 2], candidate_range=[1, 2])])


class MergeNames(unittest.TestCase):
    def test_confidence_then_owner_then_a_case_insensitively(self):
        a = names(globals={"d_0000": row("AOwner"), "d_0002": row("AHigher"),
                           "d_0004": row("AFallback")},
                  routines={"u3_0000": row("ARoutine"), "p_0000": row("AMain")})
        b = names(globals={"D_0000": row("BOwner"), "d_0002": row("BLower", "medium"),
                           "d_0004": row("BFallback")},
                  routines={"u3_0000": row("BRoutine"), "p_0000": row("BMain")})
        source = {"U8.PAS": "unit U8; interface var d_0000,d_0002: Word; implementation end."}
        merged = rn.merge_proposals(a, b, source)
        self.assertEqual(merged["globals"]["D_0000"]["name"], "BOwner")
        self.assertEqual(merged["globals"]["d_0002"]["name"], "AHigher")
        self.assertEqual(merged["globals"]["d_0004"]["name"], "AFallback")
        self.assertEqual(merged["routines"]["u3_0000"]["name"], "BRoutine")
        self.assertEqual(merged["routines"]["p_0000"]["name"], "AMain")
        self.assertEqual(merged["globals"]["D_0000"]["evidence"], "Observed behavior.")

    def test_duplicates_and_program_wide_collision_qualification(self):
        a = names(globals={"d_0000": row("SharedRole")}, routines={
            "p_0000": row("DoFirst", params={"a": "SharedRole"}, locals={"i": "IndexValue"}),
            "p_0001": row("DoSecond", locals={"i": "IndexValue", "j": "Random"})})
        b = names(globals={"D_0000": row("SharedRole")})
        merged = rn.merge_proposals(a, b, {})
        self.assertEqual(len(merged["globals"]), 1)
        all_names = rn.validate_names(merged)
        self.assertEqual(len(all_names), 7)
        self.assertEqual(merged["globals"]["d_0000"]["name"], "SharedRole")
        self.assertNotEqual(merged["routines"]["p_0000"]["params"]["a"], "SharedRole")
        self.assertNotEqual(merged["routines"]["p_0001"]["locals"]["j"], "Random")
        self.assertFalse(merged["merge"]["decisions"])

    def test_lifted_type_instances_remain_distinct(self):
        a = names(types={"TFile": row("TLevelFile")})
        b = names()
        src = {"U8.PAS": "unit U8; interface type t_p_0000_tfile=file of Byte; "
               "t_p_0001_tfile=file of Byte; implementation end."}
        merged = rn.merge_proposals(a, b, src)
        self.assertEqual(set(merged["types"]), {"t_p_0000_tfile", "t_p_0001_tfile"})
        self.assertNotEqual(*[v["name"] for v in merged["types"].values()])
        self.assertTrue(all(v["proposal_key"] == "TFile" for v in merged["types"].values()))

    def test_fields_use_their_own_confidence_and_evidence(self):
        a = names(types={"TActor": row("TGameActor", fields={"State": "FlashFrames", "X": "WorldX"},
            field_confidence={"State": "high", "X": "high"},
            field_evidence={"State": "Counts flashing frames.", "X": "Horizontal position."})})
        b = names(types={"TActor": row("TGameActor", fields={"State": "ActorState", "X": "ActorWorldX"},
            field_details={"State": dict(confidence="medium", evidence="Kind-dependent state."),
                           "X": dict(confidence="high", evidence="Actor horizontal position.")})})
        src = {"U8.PAS": "unit U8; interface type TActor=record State,X:Word;end; implementation end."}
        merged = rn.merge_proposals(a, b, src)
        actor = merged["types"]["TActor"]
        self.assertEqual(actor["fields"]["State"], "FlashFrames")
        self.assertEqual(actor["field_details"]["State"]["evidence"], "Counts flashing frames.")
        self.assertEqual(actor["fields"]["X"], "ActorWorldX")

    def test_invalid_reserved_duplicate_and_long_unit_rejected(self):
        for invalid in ("ReadLn", "begin", "TextAttr", "DosError", "9Invalid", "Has-Dash", "a" * 32):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                rn.validate_names(names(globals={"d_0000": row(invalid)}))
        with self.assertRaises(ValueError):
            rn.validate_names(names(units={"u1": row("TooLongUnit")}))
        with self.assertRaises(ValueError):
            rn.validate_names(names(units={"u1": row("CON")}))
        with self.assertRaises(ValueError):
            rn.validate_names(names(globals={"a": row("Same"), "b": row("same")}))


class TokenRename(unittest.TestCase):
    def transform(self, source, mapping):
        return rn.Renamer(mapping, source).transform()

    def test_strings_comments_directives_and_numeric_asm_operands_preserved(self):
        mapping = names(routines={"p_0000": row("ReadClock")}, globals={"d_0000": row("ClockValue")})
        source = {"SAM.PAS": "program SAM; {$L OLD.OBJ}\nvar d_0000:Word;\n"
                  "{ p_0000 d_0000 } (* d_0000 *)\nprocedure p_0000;\nbegin\n"
                  "d_0000:=1; WriteLn('p_0000 d_0000 isn''t code');\nend;\nbegin p_0000 end.\n",
                  "TEST.ASM": "public p_0000 ; p_0000 stays in comment\n"
                  "p_0000 proc far\n mov ax,0d_0000h\n db 'd_0000',\"p_0000\"\n"
                  " mov ax,d_0000\n ret\np_0000 endp\n"}
        output, report = self.transform(source, mapping)
        self.assertIn("{$L OLD.OBJ}", output["SAM.PAS"])
        self.assertIn("{ p_0000 d_0000 } (* d_0000 *)", output["SAM.PAS"])
        self.assertIn("'p_0000 d_0000 isn''t code'", output["SAM.PAS"])
        self.assertIn("procedure ReadClock;", output["SAM.PAS"])
        self.assertIn("public ReadClock ; p_0000 stays in comment", output["TEST.ASM"])
        self.assertIn("0d_0000h", output["TEST.ASM"])
        self.assertIn("db 'd_0000',\"p_0000\"", output["TEST.ASM"])
        self.assertIn("mov ax,ClockValue", output["TEST.ASM"])
        self.assertEqual(report["comments"], 2)

    def test_scoped_parameters_locals_nested_shadow_and_parent_capture(self):
        mapping = names(routines={
            "p_0000": row("OuterRoutine", params={"A": "InputValue"}, locals={"i": "OuterIndex"}),
            "p_0001": row("InnerRoutine", locals={"i": "InnerIndex"})})
        src = {"SAM.PAS": "program SAM;\nprocedure p_0000(A: Word);\nvar i:Word;\n"
               "procedure p_0001;\nvar i:Word;\nbegin i:=A end;\n"
               "procedure UnmappedChild;\nvar i:Word;\nbegin i:=A end;\n"
               "begin i:=A; p_0001 end;\nbegin p_0000(1) end.\n"}
        output, _ = self.transform(src, mapping)
        text = output["SAM.PAS"]
        self.assertIn("OuterRoutine(InputValue: Word)", text)
        self.assertIn("begin InnerIndex:=InputValue end", text)
        self.assertIn("begin OuterIndex:=InputValue; InnerRoutine end", text)
        self.assertIn("var i:Word;\nbegin i:=InputValue end", text)

    def test_record_receivers_aliases_arrays_casts_variants_and_constants(self):
        mapping = names(types={
            "TA": row("TFirstRecord", fields={"X": "FirstValue"}),
            "TB": row("TSecondRecord", fields={"X": "SecondValue"}),
            "PArray": row("PRecordArray")},
            globals={"d_0000": row("FirstArray"), "d_0002": row("SecondRecord")},
            routines={"p_0000": row("RecordWorker", locals={"X": "LoopValue"})})
        src = {"SAM.PAS": "program SAM;\ntype TA=record X:Word; end;\n"
               "TB=record case Byte of 0:(X:Word); end;\nPArray=^TArr; TArr=array[0..2] of TA;\n"
               "const d_0002:TB=(X:7);\nvar d_0000:PArray;\n"
               "procedure p_0000; var X:Word;\nbegin X:=d_0000^[1].X; X:=TB(d_0002).X end;\n"
               "begin p_0000 end.\n"}
        output, report = self.transform(src, mapping)
        text = output["SAM.PAS"]
        self.assertIn("TFirstRecord=record FirstValue:Word", text)
        self.assertIn("0:(SecondValue:Word)", text)
        self.assertIn("SecondRecord:TSecondRecord=(SecondValue:7)", text)
        self.assertIn("LoopValue:=FirstArray^[1].FirstValue", text)
        self.assertIn("LoopValue:=TSecondRecord(SecondRecord).SecondValue", text)
        self.assertFalse(report["blocked_field_types"])

    def test_ambiguous_field_preserves_whole_types_and_reports(self):
        mapping = names(types={"TA": row("TLeftRecord", fields={"X": "LeftValue"}),
                               "TB": row("TRightRecord", fields={"X": "RightValue"})})
        src = {"SAM.PAS": "program SAM; type TA=record X:Word;end; TB=record X:Word;end;\n"
               "var a:TA; unknown:UnknownRecord;\nbegin a.X:=unknown.X end.\n"}
        output, report = self.transform(src, mapping)
        self.assertIn("TLeftRecord=record X:Word", output["SAM.PAS"])
        self.assertIn("a.X:=unknown.X", output["SAM.PAS"])
        self.assertEqual(report["blocked_field_types"], ["ta", "tb"])
        self.assertEqual(report["skipped"][0]["field"], "X")

    def test_interface_formal_aliases_external_and_unit_filenames(self):
        mapping = names(units={"u1": row("GAMEUNIT"), "p": row("MAINPROG")},
                        routines={"u1_0000": row("DecodeAsset", params={"Buffer": "AssetBytes"},
                                                param_aliases={"Data": "Buffer"})})
        src = {"U1.PAS": "unit U1; interface procedure u1_0000(var Data);\nimplementation\n"
               "{$L OLD.OBJ}\nprocedure u1_0000; external;\nbegin end.\n",
               "SAM.PAS": "program SAM; uses U1; begin u1_0000(1) end.\n",
               "BUILD.BAT": "if exist U1.TPU del U1.TPU\ntpc SAM.PAS\n"}
        output, _ = self.transform(src, mapping)
        self.assertIn("GAMEUNIT.PAS", output)
        self.assertNotIn("U1.PAS", output)
        self.assertIn("unit GAMEUNIT", output["GAMEUNIT.PAS"])
        self.assertIn("DecodeAsset(var AssetBytes)", output["GAMEUNIT.PAS"])
        self.assertIn("{$L OLD.OBJ}", output["GAMEUNIT.PAS"])
        self.assertIn("program MAINPROG; uses GAMEUNIT", output["SAM.PAS"])
        self.assertIn("GAMEUNIT.TPU", output["BUILD.BAT"])
        again, _ = self.transform(output, mapping)
        self.assertEqual(output, again)

    def test_wrapping_preserves_tokens_and_one_line_comments(self):
        src = "  CallThing(" + ",".join("ValueName" + str(i) for i in range(22)) + ");\n"
        text = rn.wrap_pascal(src)
        self.assertTrue(all(len(line) <= 126 for line in text.splitlines()))
        self.assertEqual([t.text for t in rn.lex(src)], [t.text for t in rn.lex(text)])
        literal = "x:='" + "identifier " * 9 + "'; { untouched }\n"
        wrapped = rn.wrap_pascal(literal, 110)
        self.assertIn("'" + "identifier " * 9 + "'", wrapped)
        self.assertIn("{ untouched }", wrapped)

    def test_main_body_comment_is_idempotent_without_inventing_a_routine(self):
        mapping = names(routines={"p_1148": row("RunSecretAgent")})
        src = {"SAM.PAS": "program SAM;\nbegin WriteLn('game') end.\n"}
        output, report = self.transform(src, mapping)
        self.assertEqual(report["comments"], 1)
        self.assertNotIn("procedure", output["SAM.PAS"])
        again, report = self.transform(output, mapping)
        self.assertEqual(output, again)
        self.assertEqual(report["comments"], 0)


class ComparisonAliases(unittest.TestCase):
    def test_map_segment_public_and_module_names_translate_without_addresses_changing(self):
        mapping = names(units={"p": row("SAMMAIN"), "u1": row("SAMPLAY")},
                        routines={"u1_0000": row("MovePlayer")},
                        globals={"d_0000": row("PlayerValue")})
        text = ("00000H 0000FH 00010H SAMPLAY CODE\n"
                "Publics by Value\n0000:0005 MovePlayer\n0001:0007 PlayerValue\n"
                "Line numbers for SAMPLAY(SAMPLAY.PAS) segment SAMPLAY\n"
                "5 0000:0005\nProgram entry point at 0000:0005\n")
        result = tpmap.parse(pb.canonical_map(text, mapping))
        self.assertEqual(result.segment("U1").start, 0)
        self.assertEqual(result.publics["U1_0000"], (0, 5))
        self.assertEqual(result.publics["D_0000"], (1, 7))
        self.assertEqual(result.lines["U1"], [(5, 0, 5)])
        self.assertEqual(pb.canonical_map("SAMMAIN", mapping), "SAM")

    def test_build_batch_accepts_only_names_and_rejects_command_changes(self):
        import mergeeps
        mapping = names(units={"u1": row("SAMPLAY")})
        options = ["/$S-", "/$I-", "/$R-", "/$B-"]
        batch = mergeeps.build_batch(options).replace("U1.TPU", "SAMPLAY.TPU")
        with patch.object(pb, "semantic_names", return_value=mapping):
            self.assertTrue(st.build_steps(batch, "sam1", options))
            with self.assertRaises(ValueError):
                st.build_steps(batch + "\ndel SAM.PAS\n", "sam1", options)


class ProofGate(unittest.TestCase):
    def tree(self, directory):
        tree = Path(directory) / "source"
        tree.mkdir()
        (tree / "SAM.PAS").write_text("program SAM; procedure p_0000; begin end; begin p_0000 end.\n")
        return tree

    def test_failed_build_never_replaces_input(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = self.tree(directory)
            original = (tree / "SAM.PAS").read_bytes()
            def builder(source, ep, dest):
                r = proof()
                if source.name == "game":
                    r["ok"], r["status"] = False, "FAIL"
                return r
            with self.assertRaises(ValueError):
                rn.apply_verified(tree, names(routines={"p_0000": row("RenamedProcedure")}),
                                  Path(directory) / "work", builder)
            self.assertEqual((tree / "SAM.PAS").read_bytes(), original)

    def test_equal_builds_replace_only_after_all_episodes(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = self.tree(directory)
            original = (tree / "SAM.PAS").read_bytes()
            calls = []
            def builder(source, ep, dest):
                self.assertEqual((tree / "SAM.PAS").read_bytes(), original)
                calls.append((source.name, ep))
                return proof()
            work = Path(directory) / "work"
            rn.apply_verified(tree, names(routines={"p_0000": row("RenamedProcedure")}), work, builder)
            self.assertEqual(len(calls), 6)
            self.assertIn("procedure RenamedProcedure", (tree / "SAM.PAS").read_text())
            self.assertEqual((work / "original/SAM.PAS").read_bytes(), original)
            self.assertEqual(json.loads((work / "result.json").read_text())["status"], "EQUAL")

    def test_same_proof_rejects_counts_ranges_and_failed_checks(self):
        before = {ep: proof() for ep in ("sam1", "sam2", "sam3")}
        for mutate in (lambda r: r.update(equal_bytes=2),
                       lambda r: r["object_holes"][0].update(candidate_range=[2, 3]),
                       lambda r: r["checks"].update(layout=False)):
            after = copy.deepcopy(before)
            mutate(after["sam2"])
            with self.assertRaises(ValueError):
                rn.same_proof(before, after)


if __name__ == "__main__":
    unittest.main()
