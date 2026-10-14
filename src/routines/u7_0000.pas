{@decls}
type
  TScoreRecord = record
    Padding: array[1..600] of Byte;
    Score: Integer;
    Tail: array[1..8] of Byte;
  end;
  TScoreTable = array[1..12] of TScoreRecord;
  PScoreTable = ^TScoreTable;
var
  d_341E: PScoreTable;
  d_3422: PScoreTable;
  d_3426: PScoreTable;
  d_34AA: Integer;
  d_34AC: Integer;
  d_34AE: Byte;
{@stubs}
{@body}
procedure u7_0000(N: Integer);
var
  Value: Integer;
  Uninitialized: Integer;
begin
  if d_34AE <> 0 then
  begin
    case N of
      1..12: Value := d_341E^[N].Score;
      13..24: Value := d_3422^[N - 12].Score;
      25..36: Value := d_3426^[N - 24].Score;
    end;

    case d_34AA of
      1..12: Value := d_341E^[d_34AA].Score;
      13..24: Value := d_3422^[d_34AA - 12].Score;
      25..36: Value := d_3426^[d_34AA - 24].Score;
    end;

    if Value >= Uninitialized then
    begin
      d_34AC := 1;
      d_34AE := 1;
      d_34AA := N;
    end;
  end
  else
  begin
    d_34AC := 1;
    d_34AE := 1;
    d_34AA := N;
  end;
end;


