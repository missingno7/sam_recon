unit SAMSOUND;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  SoundBankOne: PSpeakerSoundBank;
  SoundBankTwo: PSpeakerSoundBank;
  SoundBankThree: PSpeakerSoundBank;
  SoundResourceFile: file of TSpeakerSoundBank;
  CurrentSoundEffect: integer;
  SoundSampleIndex: integer;
  SoundPlaying: byte;
  SoundEnabled: byte;
procedure StartSoundEffect(EffectNumber: Integer);
implementation
uses Dos, PROGRPHX, Crt;
{$F+}
{ Sets active sound number/sample=1/playing flag. }
procedure StartSoundEffect(EffectNumber: Integer);
var
  SoundPriorityWork: Integer;
  UninitializedPriority: Integer;
begin
  if SoundPlaying <> 0 then
  begin
    case EffectNumber of
      1..12: SoundPriorityWork := SoundBankOne^[EffectNumber, 301];
      13..24: SoundPriorityWork := SoundBankTwo^[EffectNumber - 12, 301];
      25..36: SoundPriorityWork := SoundBankThree^[EffectNumber - 24, 301];
    end;

    case CurrentSoundEffect of
      1..12: SoundPriorityWork := SoundBankOne^[CurrentSoundEffect, 301];
      13..24: SoundPriorityWork := SoundBankTwo^[CurrentSoundEffect - 12, 301];
      25..36: SoundPriorityWork := SoundBankThree^[CurrentSoundEffect - 24, 301];
    end;

    if SoundPriorityWork >= UninitializedPriority then
    begin
      SoundSampleIndex := 1;
      SoundPlaying := 1;
      CurrentSoundEffect := EffectNumber;
    end;
  end
  else
  begin
    SoundSampleIndex := 1;
    SoundPlaying := 1;
    CurrentSoundEffect := EffectNumber;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ Empty begin/end unit initialization body. }
begin
end.
