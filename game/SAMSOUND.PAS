{ Sound unit: selects PC-speaker effects from the shared sound bank.
  The program timer interrupt advances the selected effect. }
unit SAMSOUND;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  SoundBankOne: PSpeakerSoundBank;
  SoundBankTwo: PSpeakerSoundBank;
  SoundBankThree: PSpeakerSoundBank;
  SoundResourceFile: file of TSpeakerSoundBank;
  CurrentSoundEffect: Integer;
  SoundSampleIndex: Integer;
  SoundPlaying: Byte;
  SoundEnabled: Byte;
procedure StartSoundEffect(EffectNumber: Integer);
implementation
uses Dos, PROGRPHX, Crt;
const
  { One-based effect ranges within the three twelve-effect banks. }
  SoundBankTwoFirstEffect = 13;
  SoundBankTwoLastEffect = 24;
  SoundBankThreeFirstEffect = 25;
  SoundBankThreeLastEffect = 36;
  SoundBankTwoIndexBias = 12;
  SoundBankThreeIndexBias = 24;

{ PC-speaker effect selection. }
{$F+}
{ Selects an effect at sample 1. Original priority bug preserved for exactness:
  the requested priority is overwritten by the current effect's priority, then
  compared with an uninitialized local. Do not repair this comparison here. }
procedure StartSoundEffect(EffectNumber: Integer);
var
  SoundPriorityScratch: Integer;
  UninitializedPriority: Integer;
begin
  if SoundPlaying <> 0 then
  begin
    case EffectNumber of
      1..GameSoundEffectsPerBank:
        SoundPriorityScratch := SoundBankOne^[EffectNumber, GameSoundPriorityColumn];
      SoundBankTwoFirstEffect..SoundBankTwoLastEffect:
        SoundPriorityScratch := SoundBankTwo^[EffectNumber - SoundBankTwoIndexBias, GameSoundPriorityColumn];
      SoundBankThreeFirstEffect..SoundBankThreeLastEffect:
        SoundPriorityScratch := SoundBankThree^[EffectNumber - SoundBankThreeIndexBias,
          GameSoundPriorityColumn];
    end;
    case CurrentSoundEffect of
      1..GameSoundEffectsPerBank:
        SoundPriorityScratch := SoundBankOne^[CurrentSoundEffect, GameSoundPriorityColumn];
      SoundBankTwoFirstEffect..SoundBankTwoLastEffect:
        SoundPriorityScratch := SoundBankTwo^[CurrentSoundEffect - SoundBankTwoIndexBias,
          GameSoundPriorityColumn];
      SoundBankThreeFirstEffect..SoundBankThreeLastEffect:
        SoundPriorityScratch := SoundBankThree^[CurrentSoundEffect - SoundBankThreeIndexBias,
          GameSoundPriorityColumn];
    end;
    if SoundPriorityScratch >= UninitializedPriority then
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
