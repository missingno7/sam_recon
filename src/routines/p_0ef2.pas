{@decls}
type
  TConfigFile = file of TConfig;
{@stubs}

{@body}
procedure p_0ef2;
var
  f: TConfigFile;
begin
  d_6B44.OldMode := d_34AF;
  d_6B44.Old70BA := d_70BA;
  d_6B44.Old70BC := d_70BC;
  d_6B44.Old70BE := d_70BE;
  d_6B44.Old70C0 := d_70C0;
  d_6B44.Old70C4 := d_70C4;
  d_6B44.Old70C2 := d_70C2;
  d_6B44.Old70C6 := d_70C6;
  d_6B44.Old70C8 := d_70C8;
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
  Rewrite(f);
  Write(f, d_6B44);
  Close(f);
{$I+}
end;
