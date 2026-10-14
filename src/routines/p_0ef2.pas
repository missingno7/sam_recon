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
  d_70BA: Word;
  d_70BC: Word;
  d_70BE: Word;
  d_70C0: Word;
  d_70C2: Word;
  d_70C4: Word;
  d_70C6: Word;
  d_70C8: Word;
{@stubs}
{@body}
procedure p_0ef2;
var
  f: TConfigFile;
begin
  d_6B44.old_mode := d_34AF;
  d_6B44.old_70BA := d_70BA;
  d_6B44.old_70BC := d_70BC;
  d_6B44.old_70BE := d_70BE;
  d_6B44.old_70C0 := d_70C0;
  d_6B44.old_70C4 := d_70C4;
  d_6B44.old_70C2 := d_70C2;
  d_6B44.old_70C6 := d_70C6;
  d_6B44.old_70C8 := d_70C8;
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

