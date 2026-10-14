{@decls}
type
  TConfig = packed record
    prefix: array[0..449] of Byte;
    old_mode: Byte;
    old_70BA: Word;
    old_70BC: Word;
    old_70BE: Word;
    old_70C0: Word;
    old_70C4: Word;
    old_70C2: Word;
    old_70C6: Word;
    old_70C8: Word;
  end;
  TConfigFile = file of TConfig;
var
  d_6B44: TConfig;
  d_34AF: Byte;
  d_341C: Boolean;
  d_70BA: Word;
  d_70BC: Word;
  d_70BE: Word;
  d_70C0: Word;
  d_70C2: Word;
  d_70C4: Word;
  d_70C6: Word;
  d_70C8: Word;
{@stubs}
function u6_0000: Boolean;
{@body}
procedure p_0f75;
var
  f: TConfigFile;
  OK: Boolean;
begin
{$I-}
{$IFDEF SAM1}
  Assign(f, 'SAM1.CFG');
{$ENDIF}
{$IFDEF SAM2}
  Assign(f, 'SAM2.CFG');
{$ENDIF}
{$IFDEF SAM3}
  Assign(f, 'SAM3.CFG');
{$ENDIF}
  Reset(f);
  OK := IOResult = 0;
  Reset(f);
  OK := IOResult = 0;

  if OK then
  begin
    Read(f, d_6B44);
    Close(f);
    d_34AF := d_6B44.old_mode;
    d_70BA := d_6B44.old_70BA;
    d_70BC := d_6B44.old_70BC;
    d_70BE := d_6B44.old_70BE;
    d_70C0 := d_6B44.old_70C0;
    d_70C4 := d_6B44.old_70C4;
    d_70C2 := d_6B44.old_70C2;
    d_70C6 := d_6B44.old_70C6;
    d_70C8 := d_6B44.old_70C8;
    if d_70C8 = 1 then
      d_341C := u6_0000
    else
      d_341C := False;
  end
  else
  begin
    d_34AF := 1;
    d_70BA := $48;
    d_70BC := $50;
    d_70BE := $4B;
    d_70C0 := $4D;
    d_70C4 := $1D;
    d_70C2 := $38;
    d_70C6 := 0;
    d_70C8 := 0;
    d_341C := False;
  end;
{$I+}
end;

