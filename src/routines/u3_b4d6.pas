{@decls}
type
  TOrderLine = String[40];
  TOrderTable = record
    Reserved: Byte;
    Rows: array[0..299] of TOrderLine;
  end;
var
  d_37E8: TOrderTable;
  d_6EC5: Byte;
{@stubs}
procedure u3_079e;
function u3_1601(Flag: Byte): Byte;
procedure u3_acdd;
{@body}
procedure u3_b4d6;
var
  Row: Word;
  ModeResult: Word;
begin
  u3_079e;
  Row := 0;
  Inc(Row);
  d_37E8.Rows[Row] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(Row);
  d_37E8.Rows[Row][0] := #0;
  Inc(Row);
  d_37E8.Rows[Row] := '     Order now and receive:';
  Inc(Row);
  d_37E8.Rows[Row][0] := #0;
  Inc(Row);
  d_37E8.Rows[Row] := '  * All three devious missions';
  Inc(Row);
  d_37E8.Rows[Row] := '  * The hints and tricks sheet';
  Inc(Row);
  d_37E8.Rows[Row] := '  * The secret cheat password';
  Inc(Row);
  d_37E8.Rows[Row] := '  * Exciting new bonus game';
  Inc(Row);
  d_37E8.Rows[Row][0] := #0;
  Inc(Row);
  d_37E8.Rows[Row] := '    To order, call toll free:';
  Inc(Row);
  d_37E8.Rows[Row] := '         1-800-426-3123';
  Inc(Row);
  d_37E8.Rows[Row] := '  (Visa and MasterCard Welcome)';
  Inc(Row);
  d_37E8.Rows[Row][0] := #0;
  Inc(Row);
  d_37E8.Rows[Row] := 'Foreign orders:  Please read the';
  Inc(Row);
  d_37E8.Rows[Row] := '  "Foreign Orders" menu option.';
  Inc(Row);
  d_37E8.Rows[Row][0] := #0;
  Inc(Row);
  d_37E8.Rows[Row] := '    Continued...Press Any Key';
  Inc(Row);
  d_37E8.Rows[Row] := 'END OF WINDOW';
  MemW[0:$041C] := MemW[0:$041A];
  ModeResult := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
end;











