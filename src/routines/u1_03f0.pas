{@decls}
type
  TLine = array[0..159] of Byte;
  TBuffer = array[1..200] of TLine;
  PBuffer = ^TBuffer;
  TItem = packed record
    f34cc: Integer;
    f34ce: Integer;
    f34d0: Integer;
    f34d2: Integer;
    f34d4: Integer;
    f34d6: Integer;
    f34d8: Integer;
    f34da: Integer;
    pad: array[0..3] of Byte;
    f34e0: Integer;
    f34e2: Integer;
    f34e4: Integer;
    f34e6: Integer;
    f34e8: Integer;
    f34ea: Byte;
    f34eb: Byte;
  end;
var
  d_34CC: array[0..64] of TItem;
  d_6D96: PBuffer;
{@stubs}
procedure u9_19f9(var source: Byte; xoff, count: Integer);
{@body}
procedure u1_03f0(param1, param2: Integer; param3: Word);
var
  idx: Word;
  found: String[4];
begin
  idx := 0;
  found[1] := #0;
  repeat
    Inc(idx);
    if d_34CC[idx].f34ea = 1 then
    begin
      d_34CC[idx].f34cc := 0;
      d_34CC[idx].f34ce := param1;
      d_34CC[idx].f34d0 := param2;
      d_34CC[idx].f34d2 := param1;
      d_34CC[idx].f34d4 := param2;
      d_34CC[idx].f34e4 := 0;
      d_34CC[idx].f34e6 := 0;
      d_34CC[idx].f34d8 := 0;
      d_34CC[idx].f34da := $10;
      d_34CC[idx].f34ea := 0;
      d_34CC[idx].f34eb := 0;
      d_34CC[idx].f34e8 := $1389;
      d_34CC[idx].f34e0 := param3 + $96;
      d_34CC[idx].f34d6 := 1;
      d_34CC[idx].f34e6 := 0;
      d_34CC[idx].f34e2 := 1;
      u9_19f9(d_6D96^[param3][3],
        d_34CC[idx].f34ce, Word((LongInt(d_34CC[idx].f34d0 + 8) and $fff0) + $10));
      u9_19f9(d_6D96^[param3][3],
        d_34CC[idx].f34ce, Word((LongInt(d_34CC[idx].f34d0 + 8) and $fff0) + $1a0));
      found[1] := #1;
    end;
  until (found[1] <> #0) or (idx = $19);
end;
