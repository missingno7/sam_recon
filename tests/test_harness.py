"""Unit tests for candidate parsing, skeleton fillers and the map parser (no DOS tools)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import harness  # noqa: E402
import tpmap  # noqa: E402

CAND = """{ comment }
{@decls}
type
  TRec = record
    A: Integer;
    B: array[1..3] of Byte;
  end;
const
  K = 5;
var
  d_02A4: Word;
  d_3812: array[1..299] of TRec;
const
  d_01C6: array[0..1] of Word = (1, 2);
{@stubs}
procedure u3_1a2b(X: Integer;
  Y: Word);
function u5_0f9b: Byte;
{@body}
procedure u3_6ea9;
  procedure Inner;
  begin
  end;
begin
  Inner;
end;
"""

MAP = """
 Start  Stop   Length Name               Class

 00000H 00026H 00027H H                  CODE
 00030H 00048H 00019H U3                 CODE
 00690H 00B6BH 004DCH SYSTEM             CODE
 00B70H 00E13H 002A4H DATA               DATA
 00E20H 04E1FH 04000H STACK              STACK

  Address         Publics by Value

 0000:0000       U3_6EA9
 0000:0021       @
 0003:0000       @
 0003:0005       U3_1A2B
 00B7:0000       D_01C6

Line numbers for H(H.PAS) segment H

     3 0000:0000     4 0000:0013     5 0000:0021

Program entry point at 0000:0021
"""


class CandidateParsing(unittest.TestCase):
    def test_sections_and_decls(self):
        sec = harness.split_sections(CAND)
        d = harness.parse_decls(sec["decls"])
        self.assertEqual(set(d.globals), {"D_02A4", "D_3812", "D_01C6"})
        self.assertIn("D_01C6", d.typed_const)
        kinds = [k for k, _ in d.shared]
        self.assertEqual(kinds, ["type", "const"])
        self.assertIn("record", d.shared[0][1])

    def test_stubs_and_target(self):
        sec = harness.split_sections(CAND)
        stubs = harness.parse_stubs(sec["stubs"])
        self.assertEqual([n for n, _ in stubs], ["u3_1a2b", "u5_0f9b"])
        self.assertEqual(harness.target_name(sec["body"]), "u3_6ea9")
        self.assertEqual(harness._stub_def(stubs[0][1]), "procedure u3_1a2b;")

    def test_bad_global_name(self):
        with self.assertRaises(harness.HarnessError):
            harness.parse_decls("var Foo: Word;")


class Fillers(unittest.TestCase):
    def test_odd_offset_splits(self):
        t = harness._pad_decl("d_01cd", 5, False, 0x1CD)
        self.assertTrue(t.startswith("d_01cd: Byte;"))
        self.assertIn("pad_01CE: array[0..3] of Byte;", t)

    def test_typed_filler_values(self):
        t = harness._pad_decl("pad_0000", 3, True, 0)
        self.assertTrue(t.startswith("pad_0000: array[0..2] of Byte = ("))
        self.assertEqual(t.split("= (", 1)[1].replace(" ", "").replace("\n", ""), "0,0,0);")


class MapParsing(unittest.TestCase):
    def test_parse(self):
        m = tpmap.parse(MAP)
        self.assertEqual([s.name for s in m.segments][:3], ["H", "U3", "SYSTEM"])
        self.assertEqual(m.data().para, 0xB7)
        self.assertEqual(m.publics["U3_1A2B"], (3, 5))
        self.assertEqual(sorted(m.inits), [(0, 0x21), (3, 0)])
        self.assertEqual(m.lines["H"][1], (4, 0, 0x13))
        self.assertEqual(m.entry, (0, 0x21))


if __name__ == "__main__":
    unittest.main()
