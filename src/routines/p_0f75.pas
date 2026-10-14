{@decls}
type
  TConfigFile = file of TConfig;
{@stubs}

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
    d_34AF := d_6B44.OldMode;
    d_70BA := d_6B44.Old70BA;
    d_70BC := d_6B44.Old70BC;
    d_70BE := d_6B44.Old70BE;
    d_70C0 := d_6B44.Old70C0;
    d_70C4 := d_6B44.Old70C4;
    d_70C2 := d_6B44.Old70C2;
    d_70C6 := d_6B44.Old70C6;
    d_70C8 := d_6B44.Old70C8;
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
