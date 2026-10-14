{@decls}
type
  TMapObject = record
    F00: Integer;
    F02: Integer;
    F04: Integer;
    F06: Integer;
    F08: Integer;
    F0A: Integer;
    F0C: Integer;
    F0E: Integer;
    F10: Integer;
    F12: Integer;
    F14: Integer;
    F16: Integer;
    F18: Integer;
    F1A: Integer;
    F1C: Integer;
    F1E, F1F: Byte;
  end;
  TSpriteBytes = array[0..32767] of Byte;
  PSpriteBytes = ^TSpriteBytes;
var
  d_34EC: array[1..25] of TMapObject;
  d_682E: Integer;
  d_6D76: PSpriteBytes;
  d_6D7E: PSpriteBytes;
  d_6D82: PSpriteBytes;
  d_6D86: PSpriteBytes;
  d_6D96: PSpriteBytes;
  d_6D9E: PSpriteBytes;
  d_6DA6: PSpriteBytes;
  d_6DAE: PSpriteBytes;
{@stubs}
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D: Byte; Foreground: Byte);
procedure u9_19f9(var Sprite; X, Y: Integer);
{@body}
procedure u2_3a91(X, Y: Integer; Symbol: String; Foreground: Byte);
begin
  if Symbol = #174 then { 3ABC }
  begin { 3ABC }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 3ADC }
    Inc(d_682E); { 3ADF }
    u9_19f9(d_6DA6^[1923], (X * 16), ((Y * 16) + 16)); { 3B02 }
    u9_19f9(d_6DA6^[1923], (X * 16), ((Y * 16) + 416)); { 3B26 }
    u9_19f9(d_6DA6^[1283], ((X + 1) * 16), ((Y * 16) + 16)); { 3B4B }
    u9_19f9(d_6DA6^[1283], ((X + 1) * 16), ((Y * 16) + 416)); { 3B70 }
    d_34EC[d_682E].F00 := 0; { 3B7F }
    d_34EC[d_682E].F14 := 851; { 3B8B }
    d_34EC[d_682E].F02 := (X * 16); { 3BA1 }
    d_34EC[d_682E].F04 := (Y * 16); { 3BB5 }
    d_34EC[d_682E].F06 := (X * 16); { 3BC9 }
    d_34EC[d_682E].F08 := (Y * 16); { 3BDD }
    if Random(2) > 0 then { 3BEC }
    begin { 3BEC }
      d_34EC[d_682E].F16 := 1; { 3BF6 }
    end { 3BFC }
    else { 3BFC }
    begin { 3BFE }
      d_34EC[d_682E].F16 := -1; { 3C06 }
    end; { 3C0C }
    d_34EC[d_682E].F18 := 0; { 3C16 }
    if d_34EC[d_682E].F16 = 1 then { 3C27 }
    begin { 3C27 }
      d_34EC[d_682E].F0A := 1; { 3C31 }
    end { 3C37 }
    else { 3C37 }
    begin { 3C39 }
      d_34EC[d_682E].F0A := 41; { 3C41 }
    end; { 3C47 }
    d_34EC[d_682E].F1A := 2; { 3C4F }
    d_34EC[d_682E].F0C := 0; { 3C5F }
    d_34EC[d_682E].F0E := 0; { 3C6D }
    d_34EC[d_682E].F10 := 3; { 3C79 }
    d_34EC[d_682E].F1C := 42; { 3C87 }
    d_34EC[d_682E].F1E := 0; { 3C95 }
    d_34EC[d_682E].F1F := 0; { 3CA2 }
  end; { 3CA7 }
  if Symbol = '8' then { 3CB7 }
  begin { 3CB7 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 3CD7 }
    Inc(d_682E); { 3CDA }
    u9_19f9(d_6DAE^[3], (X * 16), ((Y * 16) + 16)); { 3CFD }
    u9_19f9(d_6DAE^[3], (X * 16), ((Y * 16) + 416)); { 3D21 }
    d_34EC[d_682E].F00 := 0; { 3D30 }
    d_34EC[d_682E].F14 := 351; { 3D3C }
    d_34EC[d_682E].F02 := (X * 16); { 3D52 }
    d_34EC[d_682E].F04 := (Y * 16); { 3D66 }
    d_34EC[d_682E].F06 := (X * 16); { 3D7A }
    d_34EC[d_682E].F08 := (Y * 16); { 3D8E }
    if Random(2) > 0 then { 3D9D }
    begin { 3D9D }
      d_34EC[d_682E].F16 := 1; { 3DA7 }
    end { 3DAD }
    else { 3DAD }
    begin { 3DAF }
      d_34EC[d_682E].F16 := -1; { 3DB7 }
    end; { 3DBD }
    d_34EC[d_682E].F18 := 0; { 3DC7 }
    if d_34EC[d_682E].F16 = 1 then { 3DD8 }
    begin { 3DD8 }
      d_34EC[d_682E].F0A := 1; { 3DE2 }
    end { 3DE8 }
    else { 3DE8 }
    begin { 3DEA }
      d_34EC[d_682E].F0A := 21; { 3DF2 }
    end; { 3DF8 }
    d_34EC[d_682E].F1A := 1; { 3E00 }
    d_34EC[d_682E].F0C := 0; { 3E10 }
    d_34EC[d_682E].F0E := 0; { 3E1E }
    d_34EC[d_682E].F1C := 1; { 3E2A }
    d_34EC[d_682E].F1E := 0; { 3E38 }
    d_34EC[d_682E].F1F := 0; { 3E45 }
  end; { 3E4A }
  if Symbol = '9' then { 3E5A }
  begin { 3E5A }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 3E7A }
    Inc(d_682E); { 3E7D }
    u9_19f9(d_6DAE^[1283], (X * 16), ((Y * 16) + 16)); { 3EA0 }
    u9_19f9(d_6DAE^[1283], (X * 16), ((Y * 16) + 416)); { 3EC4 }
    d_34EC[d_682E].F00 := 0; { 3ED3 }
    d_34EC[d_682E].F14 := 359; { 3EDF }
    d_34EC[d_682E].F02 := (X * 16); { 3EF5 }
    d_34EC[d_682E].F04 := (Y * 16); { 3F09 }
    d_34EC[d_682E].F06 := (X * 16); { 3F1D }
    d_34EC[d_682E].F08 := (Y * 16); { 3F31 }
    if Random(2) > 0 then { 3F40 }
    begin { 3F40 }
      d_34EC[d_682E].F16 := 1; { 3F4A }
    end { 3F50 }
    else { 3F50 }
    begin { 3F52 }
      d_34EC[d_682E].F16 := -1; { 3F5A }
    end; { 3F60 }
    d_34EC[d_682E].F18 := 0; { 3F6A }
    if d_34EC[d_682E].F16 = 1 then { 3F7B }
    begin { 3F7B }
      d_34EC[d_682E].F0A := 1; { 3F85 }
    end { 3F8B }
    else { 3F8B }
    begin { 3F8D }
      d_34EC[d_682E].F0A := 21; { 3F95 }
    end; { 3F9B }
    d_34EC[d_682E].F1A := 1; { 3FA3 }
    d_34EC[d_682E].F0C := 0; { 3FB3 }
    d_34EC[d_682E].F1C := 2; { 3FBF }
    d_34EC[d_682E].F1E := 0; { 3FCD }
    d_34EC[d_682E].F1F := 0; { 3FDA }
  end; { 3FDF }
  if Symbol = '0' then { 3FEF }
  begin { 3FEF }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 400F }
    Inc(d_682E); { 4012 }
    u9_19f9(d_6DAE^[2563], (X * 16), ((Y * 16) + 16)); { 4035 }
    u9_19f9(d_6DAE^[2563], (X * 16), ((Y * 16) + 416)); { 4059 }
    d_34EC[d_682E].F00 := 0; { 4068 }
    d_34EC[d_682E].F14 := 367; { 4074 }
    d_34EC[d_682E].F02 := (X * 16); { 408A }
    d_34EC[d_682E].F04 := (Y * 16); { 409E }
    d_34EC[d_682E].F06 := (X * 16); { 40B2 }
    d_34EC[d_682E].F08 := (Y * 16); { 40C6 }
    if Random(2) > 0 then { 40D5 }
    begin { 40D5 }
      d_34EC[d_682E].F16 := 1; { 40DF }
    end { 40E5 }
    else { 40E5 }
    begin { 40E7 }
      d_34EC[d_682E].F16 := -1; { 40EF }
    end; { 40F5 }
    d_34EC[d_682E].F18 := 0; { 40FF }
    if d_34EC[d_682E].F16 = 1 then { 4110 }
    begin { 4110 }
      d_34EC[d_682E].F0A := 1; { 411A }
    end { 4120 }
    else { 4120 }
    begin { 4122 }
      d_34EC[d_682E].F0A := 21; { 412A }
    end; { 4130 }
    d_34EC[d_682E].F1A := 2; { 4138 }
    d_34EC[d_682E].F0C := 0; { 4148 }
    d_34EC[d_682E].F1C := 3; { 4154 }
    d_34EC[d_682E].F1E := 0; { 4162 }
    d_34EC[d_682E].F1F := 0; { 416F }
  end; { 4174 }
  if Symbol = 'g' then { 4184 }
  begin { 4184 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 41A4 }
    Inc(d_682E); { 41A7 }
    u9_19f9(d_6DAE^[3843], (X * 16), ((Y * 16) + 16)); { 41CA }
    u9_19f9(d_6DAE^[3843], (X * 16), ((Y * 16) + 416)); { 41EE }
    d_34EC[d_682E].F00 := 0; { 41FD }
    d_34EC[d_682E].F14 := 375; { 4209 }
    d_34EC[d_682E].F02 := (X * 16); { 421F }
    d_34EC[d_682E].F04 := (Y * 16); { 4233 }
    d_34EC[d_682E].F06 := (X * 16); { 4247 }
    d_34EC[d_682E].F08 := (Y * 16); { 425B }
    if Random(2) > 0 then { 426A }
    begin { 426A }
      d_34EC[d_682E].F16 := 1; { 4274 }
    end { 427A }
    else { 427A }
    begin { 427C }
      d_34EC[d_682E].F16 := -1; { 4284 }
    end; { 428A }
    d_34EC[d_682E].F18 := 0; { 4294 }
    if d_34EC[d_682E].F16 = 1 then { 42A5 }
    begin { 42A5 }
      d_34EC[d_682E].F0A := 1; { 42AF }
    end { 42B5 }
    else { 42B5 }
    begin { 42B7 }
      d_34EC[d_682E].F0A := 21; { 42BF }
    end; { 42C5 }
    d_34EC[d_682E].F1A := 2; { 42CD }
    d_34EC[d_682E].F0C := (Random(50) + 50); { 42E7 }
    d_34EC[d_682E].F0E := 0; { 42F5 }
    d_34EC[d_682E].F1C := 4; { 4301 }
    d_34EC[d_682E].F1E := 0; { 430F }
    d_34EC[d_682E].F1F := 0; { 431C }
  end; { 4321 }
  if Symbol = 'G' then { 4331 }
  begin { 4331 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4351 }
    Inc(d_682E); { 4354 }
    u9_19f9(d_6DAE^[5123], (X * 16), ((Y * 16) + 16)); { 4377 }
    u9_19f9(d_6DAE^[5123], (X * 16), ((Y * 16) + 416)); { 439B }
    d_34EC[d_682E].F00 := 0; { 43AA }
    d_34EC[d_682E].F14 := 383; { 43B6 }
    d_34EC[d_682E].F02 := (X * 16); { 43CC }
    d_34EC[d_682E].F04 := (Y * 16); { 43E0 }
    d_34EC[d_682E].F06 := (X * 16); { 43F4 }
    d_34EC[d_682E].F08 := (Y * 16); { 4408 }
    if Random(2) > 0 then { 4417 }
    begin { 4417 }
      d_34EC[d_682E].F16 := 1; { 4421 }
    end { 4427 }
    else { 4427 }
    begin { 4429 }
      d_34EC[d_682E].F16 := -1; { 4431 }
    end; { 4437 }
    d_34EC[d_682E].F18 := 0; { 4441 }
    if d_34EC[d_682E].F16 = 1 then { 4452 }
    begin { 4452 }
      d_34EC[d_682E].F0A := 1; { 445C }
    end { 4462 }
    else { 4462 }
    begin { 4464 }
      d_34EC[d_682E].F0A := 21; { 446C }
    end; { 4472 }
    d_34EC[d_682E].F1A := 2; { 447A }
    d_34EC[d_682E].F0C := (Random(20) + 30); { 4494 }
    d_34EC[d_682E].F0E := 0; { 44A2 }
    d_34EC[d_682E].F1C := 5; { 44AE }
    d_34EC[d_682E].F1E := 0; { 44BC }
    d_34EC[d_682E].F1F := 0; { 44C9 }
  end; { 44CE }
  if Symbol = 'V' then { 44DE }
  begin { 44DE }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 44FE }
    Inc(d_682E); { 4501 }
    u9_19f9(d_6D9E^[3], (X * 16), (((Y * 16) + 16) - 16)); { 4527 }
    u9_19f9(d_6D9E^[3], (X * 16), (((Y * 16) + 416) - 16)); { 454E }
    u9_19f9(d_6D9E^[643], (X * 16), ((Y * 16) + 16)); { 4572 }
    u9_19f9(d_6D9E^[643], (X * 16), ((Y * 16) + 416)); { 4596 }
    d_34EC[d_682E].F00 := 0; { 45A5 }
    d_34EC[d_682E].F14 := 801; { 45B1 }
    d_34EC[d_682E].F02 := (X * 16); { 45C7 }
    d_34EC[d_682E].F04 := (Y * 16); { 45DB }
    d_34EC[d_682E].F06 := (X * 16); { 45EF }
    d_34EC[d_682E].F08 := (Y * 16); { 4603 }
    if Random(2) > 0 then { 4612 }
    begin { 4612 }
      d_34EC[d_682E].F16 := 1; { 461C }
    end { 4622 }
    else { 4622 }
    begin { 4624 }
      d_34EC[d_682E].F16 := -1; { 462C }
    end; { 4632 }
    d_34EC[d_682E].F18 := 0; { 463C }
    if d_34EC[d_682E].F16 = 1 then { 464D }
    begin { 464D }
      d_34EC[d_682E].F0A := 1; { 4657 }
    end { 465D }
    else { 465D }
    begin { 465F }
      d_34EC[d_682E].F0A := 41; { 4667 }
    end; { 466D }
    d_34EC[d_682E].F1A := 2; { 4675 }
    d_34EC[d_682E].F0C := (Random(20) + 30); { 468F }
    d_34EC[d_682E].F0E := 0; { 469D }
    d_34EC[d_682E].F10 := 3; { 46A9 }
    d_34EC[d_682E].F1C := 30; { 46B7 }
    d_34EC[d_682E].F1E := 0; { 46C5 }
    d_34EC[d_682E].F1F := 0; { 46D2 }
  end; { 46D7 }
  if Symbol = 'X' then { 46E7 }
  begin { 46E7 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4707 }
    Inc(d_682E); { 470A }
    u9_19f9(d_6D9E^[2563], (X * 16), (((Y * 16) + 16) - 16)); { 4730 }
    u9_19f9(d_6D9E^[2563], (X * 16), (((Y * 16) + 416) - 16)); { 4757 }
    u9_19f9(d_6D9E^[3203], (X * 16), ((Y * 16) + 16)); { 477B }
    u9_19f9(d_6D9E^[3203], (X * 16), ((Y * 16) + 416)); { 479F }
    d_34EC[d_682E].F00 := 0; { 47AE }
    d_34EC[d_682E].F14 := 817; { 47BA }
    d_34EC[d_682E].F02 := (X * 16); { 47D0 }
    d_34EC[d_682E].F04 := (Y * 16); { 47E4 }
    d_34EC[d_682E].F06 := (X * 16); { 47F8 }
    d_34EC[d_682E].F08 := (Y * 16); { 480C }
    if Random(2) > 0 then { 481B }
    begin { 481B }
      d_34EC[d_682E].F16 := 1; { 4825 }
    end { 482B }
    else { 482B }
    begin { 482D }
      d_34EC[d_682E].F16 := -1; { 4835 }
    end; { 483B }
    d_34EC[d_682E].F18 := 0; { 4845 }
    if d_34EC[d_682E].F16 = 1 then { 4856 }
    begin { 4856 }
      d_34EC[d_682E].F0A := 61; { 4860 }
    end { 4866 }
    else { 4866 }
    begin { 4868 }
      d_34EC[d_682E].F0A := 1; { 4870 }
    end; { 4876 }
    d_34EC[d_682E].F1A := 2; { 487E }
    d_34EC[d_682E].F0C := 60; { 488C }
    d_34EC[d_682E].F0E := 0; { 489C }
    d_34EC[d_682E].F10 := 3; { 48A8 }
    d_34EC[d_682E].F12 := (Random(20) + 60); { 48C2 }
    d_34EC[d_682E].F1C := 31; { 48CE }
    d_34EC[d_682E].F1E := 0; { 48DC }
    d_34EC[d_682E].F1F := 0; { 48E9 }
  end; { 48EE }
  if Symbol = '#' then { 48FE }
  begin { 48FE }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 491E }
    Inc(d_682E); { 4921 }
    u9_19f9(d_6D96^[3], (X * 16), ((Y * 16) + 16)); { 4944 }
    u9_19f9(d_6D96^[3], (X * 16), ((Y * 16) + 416)); { 4968 }
    d_34EC[d_682E].F00 := 0; { 4977 }
    d_34EC[d_682E].F14 := 151; { 4983 }
    d_34EC[d_682E].F02 := (X * 16); { 4999 }
    d_34EC[d_682E].F04 := (Y * 16); { 49AD }
    d_34EC[d_682E].F06 := (X * 16); { 49C1 }
    d_34EC[d_682E].F08 := (Y * 16); { 49D5 }
    d_34EC[d_682E].F16 := 1; { 49E1 }
    d_34EC[d_682E].F18 := 0; { 49F1 }
    d_34EC[d_682E].F0A := 1; { 49FD }
    d_34EC[d_682E].F1A := 0; { 4A0D }
    d_34EC[d_682E].F0C := 3; { 4A19 }
    d_34EC[d_682E].F1C := 32; { 4A27 }
    d_34EC[d_682E].F1E := 0; { 4A35 }
    d_34EC[d_682E].F1F := 0; { 4A42 }
  end; { 4A47 }
  if Symbol = 'c' then { 4A57 }
  begin { 4A57 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4A77 }
    Inc(d_682E); { 4A7A }
    u9_19f9(d_6D9E^[6403], (X * 16), (((Y * 16) + 16) - 16)); { 4AA0 }
    u9_19f9(d_6D9E^[6403], (X * 16), (((Y * 16) + 416) - 16)); { 4AC7 }
    u9_19f9(d_6D9E^[6403], (X * 16), ((Y * 16) + 16)); { 4AEB }
    u9_19f9(d_6D9E^[6403], (X * 16), ((Y * 16) + 416)); { 4B0F }
    d_34EC[d_682E].F00 := 0; { 4B1E }
    d_34EC[d_682E].F14 := 837; { 4B2A }
    d_34EC[d_682E].F02 := (X * 16); { 4B40 }
    d_34EC[d_682E].F04 := (Y * 16); { 4B54 }
    d_34EC[d_682E].F06 := (X * 16); { 4B68 }
    d_34EC[d_682E].F08 := (Y * 16); { 4B7C }
    if Random(2) > 0 then { 4B8B }
    begin { 4B8B }
      d_34EC[d_682E].F16 := 1; { 4B95 }
    end { 4B9B }
    else { 4B9B }
    begin { 4B9D }
      d_34EC[d_682E].F16 := -1; { 4BA5 }
    end; { 4BAB }
    d_34EC[d_682E].F18 := 0; { 4BB5 }
    if d_34EC[d_682E].F16 = 1 then { 4BC6 }
    begin { 4BC6 }
      d_34EC[d_682E].F0A := 1; { 4BD0 }
    end { 4BD6 }
    else { 4BD6 }
    begin { 4BD8 }
      d_34EC[d_682E].F0A := 21; { 4BE0 }
    end; { 4BE6 }
    d_34EC[d_682E].F1A := 2; { 4BEE }
    d_34EC[d_682E].F0C := (Random(20) + 30); { 4C08 }
    d_34EC[d_682E].F0E := 0; { 4C16 }
    d_34EC[d_682E].F10 := 3; { 4C22 }
    d_34EC[d_682E].F1C := 33; { 4C30 }
    d_34EC[d_682E].F1E := 0; { 4C3E }
    d_34EC[d_682E].F1F := 0; { 4C4B }
  end; { 4C50 }
  if Symbol = 'e' then { 4C60 }
  begin { 4C60 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4C80 }
    Inc(d_682E); { 4C83 }
    u9_19f9(d_6D76^[2563], (X * 16), ((Y * 16) + 16)); { 4CA6 }
    u9_19f9(d_6D76^[2563], (X * 16), ((Y * 16) + 416)); { 4CCA }
    d_34EC[d_682E].F00 := 0; { 4CD9 }
    d_34EC[d_682E].F14 := 117; { 4CE5 }
    d_34EC[d_682E].F02 := (X * 16); { 4CFB }
    d_34EC[d_682E].F04 := (Y * 16); { 4D0F }
    d_34EC[d_682E].F06 := (X * 16); { 4D23 }
    d_34EC[d_682E].F08 := (Y * 16); { 4D37 }
    if Random(2) > 0 then { 4D46 }
    begin { 4D46 }
      d_34EC[d_682E].F16 := 1; { 4D50 }
    end { 4D56 }
    else { 4D56 }
    begin { 4D58 }
      d_34EC[d_682E].F16 := -1; { 4D60 }
    end; { 4D66 }
    d_34EC[d_682E].F18 := 0; { 4D70 }
    if d_34EC[d_682E].F16 = 1 then { 4D81 }
    begin { 4D81 }
      d_34EC[d_682E].F0A := 1; { 4D8B }
    end { 4D91 }
    else { 4D91 }
    begin { 4D93 }
      d_34EC[d_682E].F0A := 21; { 4D9B }
    end; { 4DA1 }
    d_34EC[d_682E].F1A := 2; { 4DA9 }
    d_34EC[d_682E].F0C := 0; { 4DB9 }
    d_34EC[d_682E].F0E := 0; { 4DC7 }
    d_34EC[d_682E].F10 := 3; { 4DD3 }
    d_34EC[d_682E].F1C := 34; { 4DE1 }
    d_34EC[d_682E].F1E := 0; { 4DEF }
    d_34EC[d_682E].F1F := 0; { 4DFC }
  end; { 4E01 }
  if Symbol = 'u' then { 4E11 }
  begin { 4E11 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4E31 }
    Inc(d_682E); { 4E34 }
    u9_19f9(d_6D76^[1283], (X * 16), ((Y * 16) + 16)); { 4E57 }
    u9_19f9(d_6D76^[1283], (X * 16), ((Y * 16) + 416)); { 4E7B }
    d_34EC[d_682E].F00 := 0; { 4E8A }
    d_34EC[d_682E].F14 := 109; { 4E96 }
    d_34EC[d_682E].F02 := (X * 16); { 4EAC }
    d_34EC[d_682E].F04 := (Y * 16); { 4EC0 }
    d_34EC[d_682E].F06 := (X * 16); { 4ED4 }
    d_34EC[d_682E].F08 := (Y * 16); { 4EE8 }
    d_34EC[d_682E].F16 := 1; { 4EF4 }
    d_34EC[d_682E].F18 := 0; { 4F04 }
    d_34EC[d_682E].F0A := 1; { 4F10 }
    d_34EC[d_682E].F1A := 0; { 4F20 }
    d_34EC[d_682E].F0C := 0; { 4F2E }
    d_34EC[d_682E].F0E := 0; { 4F3C }
    d_34EC[d_682E].F10 := 3; { 4F48 }
    d_34EC[d_682E].F1C := 35; { 4F56 }
    d_34EC[d_682E].F1E := 0; { 4F64 }
    d_34EC[d_682E].F1F := 0; { 4F71 }
  end; { 4F76 }
  if Symbol = 'v' then { 4F86 }
  begin { 4F86 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4FA6 }
    Inc(d_682E); { 4FA9 }
    u9_19f9(d_6D76^[1923], (X * 16), ((Y * 16) + 16)); { 4FCC }
    u9_19f9(d_6D76^[1923], (X * 16), ((Y * 16) + 416)); { 4FF0 }
    d_34EC[d_682E].F00 := 0; { 4FFF }
    d_34EC[d_682E].F14 := 113; { 500B }
    d_34EC[d_682E].F02 := (X * 16); { 5021 }
    d_34EC[d_682E].F04 := (Y * 16); { 5035 }
    d_34EC[d_682E].F06 := (X * 16); { 5049 }
    d_34EC[d_682E].F08 := (Y * 16); { 505D }
    d_34EC[d_682E].F16 := 1; { 5069 }
    d_34EC[d_682E].F18 := 0; { 5079 }
    d_34EC[d_682E].F0A := 1; { 5085 }
    d_34EC[d_682E].F1A := 0; { 5095 }
    d_34EC[d_682E].F0C := 0; { 50A3 }
    d_34EC[d_682E].F0E := 10; { 50AF }
    d_34EC[d_682E].F10 := 10; { 50BD }
    d_34EC[d_682E].F1C := 36; { 50CB }
    d_34EC[d_682E].F1E := 0; { 50D9 }
    d_34EC[d_682E].F1F := 0; { 50E6 }
  end; { 50EB }
  if Symbol = 'n' then { 50FB }
  begin { 50FB }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 511B }
    Inc(d_682E); { 511E }
    u9_19f9(d_6D76^[5123], (X * 16), ((Y * 16) + 16)); { 5141 }
    u9_19f9(d_6D76^[5123], (X * 16), ((Y * 16) + 416)); { 5165 }
    d_34EC[d_682E].F00 := 0; { 5174 }
    d_34EC[d_682E].F14 := 133; { 5180 }
    d_34EC[d_682E].F02 := (X * 16); { 5196 }
    d_34EC[d_682E].F04 := (Y * 16); { 51AA }
    d_34EC[d_682E].F06 := (X * 16); { 51BE }
    d_34EC[d_682E].F08 := (Y * 16); { 51D2 }
    if Random(2) > 0 then { 51E1 }
    begin { 51E1 }
      d_34EC[d_682E].F16 := 1; { 51EB }
    end { 51F1 }
    else { 51F1 }
    begin { 51F3 }
      d_34EC[d_682E].F16 := -1; { 51FB }
    end; { 5201 }
    d_34EC[d_682E].F18 := 0; { 520B }
    d_34EC[d_682E].F0A := 1; { 5217 }
    d_34EC[d_682E].F1A := 2; { 5225 }
    d_34EC[d_682E].F0C := (Random(20) + 30); { 523F }
    d_34EC[d_682E].F0E := 0; { 524D }
    d_34EC[d_682E].F10 := 3; { 5259 }
    d_34EC[d_682E].F12 := (Random(50) + 100); { 5273 }
    d_34EC[d_682E].F1C := 38; { 527F }
    d_34EC[d_682E].F1E := 0; { 528D }
    d_34EC[d_682E].F1F := 0; { 529A }
  end; { 529F }
  if Symbol = '$' then { 52AF }
  begin { 52AF }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 52CF }
    Inc(d_682E); { 52D2 }
    u9_19f9(d_6D76^[3], (X * 16), (((Y * 16) + 16) - 16)); { 52F8 }
    u9_19f9(d_6D76^[3], (X * 16), (((Y * 16) + 416) - 16)); { 531F }
    u9_19f9(d_6D76^[643], (X * 16), ((Y * 16) + 16)); { 5343 }
    u9_19f9(d_6D76^[643], (X * 16), ((Y * 16) + 416)); { 5367 }
    d_34EC[d_682E].F00 := 0; { 5376 }
    d_34EC[d_682E].F14 := 101; { 5382 }
    d_34EC[d_682E].F02 := (X * 16); { 5398 }
    d_34EC[d_682E].F04 := (Y * 16); { 53AC }
    d_34EC[d_682E].F06 := (X * 16); { 53C0 }
    d_34EC[d_682E].F08 := (Y * 16); { 53D4 }
    if Random(2) > 0 then { 53E3 }
    begin { 53E3 }
      d_34EC[d_682E].F16 := 1; { 53ED }
    end { 53F3 }
    else { 53F3 }
    begin { 53F5 }
      d_34EC[d_682E].F16 := -1; { 53FD }
    end; { 5403 }
    d_34EC[d_682E].F18 := 0; { 540D }
    if d_34EC[d_682E].F16 = 1 then { 541E }
    begin { 541E }
      d_34EC[d_682E].F0A := 201; { 5428 }
    end { 542E }
    else { 542E }
    begin { 5430 }
      d_34EC[d_682E].F0A := 1; { 5438 }
    end; { 543E }
    d_34EC[d_682E].F1A := 2; { 5446 }
    d_34EC[d_682E].F0C := 60; { 5454 }
    d_34EC[d_682E].F0E := 0; { 5464 }
    d_34EC[d_682E].F10 := 3; { 5470 }
    d_34EC[d_682E].F12 := (Random(20) + 60); { 548A }
    d_34EC[d_682E].F1C := 39; { 5496 }
    d_34EC[d_682E].F1E := 0; { 54A4 }
    d_34EC[d_682E].F1F := 0; { 54B1 }
  end; { 54B6 }
  if Symbol = '[' then { 54C6 }
  begin { 54C6 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 54E6 }
    Inc(d_682E); { 54E9 }
    d_34EC[d_682E].F00 := 0; { 54F7 }
    d_34EC[d_682E].F14 := 435; { 5503 }
    d_34EC[d_682E].F02 := (X * 16); { 5519 }
    d_34EC[d_682E].F04 := (Y * 16); { 552D }
    d_34EC[d_682E].F06 := (X * 16); { 5541 }
    d_34EC[d_682E].F08 := (Y * 16); { 5555 }
    d_34EC[d_682E].F16 := 0; { 5563 }
    d_34EC[d_682E].F18 := 0; { 5571 }
    d_34EC[d_682E].F0A := 1; { 557D }
    d_34EC[d_682E].F1A := 0; { 558D }
    d_34EC[d_682E].F0C := 0; { 559B }
    d_34EC[d_682E].F0E := 0; { 55A9 }
    d_34EC[d_682E].F10 := 0; { 55B7 }
    d_34EC[d_682E].F12 := 0; { 55C5 }
    d_34EC[d_682E].F1C := 41; { 55D1 }
    d_34EC[d_682E].F1E := 0; { 55DF }
    d_34EC[d_682E].F1F := 0; { 55EC }
  end; { 55F1 }
  if Symbol = #127 then { 5601 }
  begin { 5601 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 5621 }
    Inc(d_682E); { 5624 }
    u9_19f9(d_6D86^[1283], (X * 16), ((Y * 16) + 16)); { 5647 }
    u9_19f9(d_6D86^[1283], (X * 16), ((Y * 16) + 416)); { 566B }
    d_34EC[d_682E].F00 := 0; { 567A }
    d_34EC[d_682E].F14 := 609; { 5686 }
    d_34EC[d_682E].F02 := (X * 16); { 569C }
    d_34EC[d_682E].F04 := (Y * 16); { 56B0 }
    d_34EC[d_682E].F06 := (X * 16); { 56C4 }
    d_34EC[d_682E].F08 := (Y * 16); { 56D8 }
    if Random(2) > 0 then { 56E7 }
    begin { 56E7 }
      d_34EC[d_682E].F16 := 1; { 56F1 }
    end { 56F7 }
    else { 56F7 }
    begin { 56F9 }
      d_34EC[d_682E].F16 := -1; { 5701 }
    end; { 5707 }
    d_34EC[d_682E].F18 := 0; { 5711 }
    d_34EC[d_682E].F0A := 1; { 571D }
    d_34EC[d_682E].F1A := 2; { 572B }
    d_34EC[d_682E].F0C := 2; { 5739 }
    d_34EC[d_682E].F0E := 11; { 5747 }
    d_34EC[d_682E].F1C := 6; { 5755 }
    d_34EC[d_682E].F1E := 0; { 5763 }
    d_34EC[d_682E].F1F := 0; { 5770 }
  end; { 5775 }
  if Symbol = 'R' then { 5785 }
  begin { 5785 }
    u2_2c6e(X, Y, 2, 464, 0, 0, 0, Foreground); { 57A6 }
    Inc(d_682E); { 57A9 }
    u9_19f9(d_6D82^[2083], (X * 16), ((Y * 16) + 16)); { 57CC }
    u9_19f9(d_6D82^[2083], (X * 16), ((Y * 16) + 416)); { 57F0 }
    d_34EC[d_682E].F00 := 0; { 57FF }
    d_34EC[d_682E].F14 := 464; { 580B }
    d_34EC[d_682E].F02 := (X * 16); { 5821 }
    d_34EC[d_682E].F04 := (Y * 16); { 5835 }
    d_34EC[d_682E].F06 := (X * 16); { 5849 }
    d_34EC[d_682E].F08 := (Y * 16); { 585D }
    d_34EC[d_682E].F16 := 1; { 5869 }
    d_34EC[d_682E].F18 := 0; { 5879 }
    d_34EC[d_682E].F0A := 1; { 5885 }
    d_34EC[d_682E].F1A := 0; { 5895 }
    d_34EC[d_682E].F0C := (Random(20) + 55); { 58AD }
    d_34EC[d_682E].F0E := 0; { 58BB }
    d_34EC[d_682E].F1C := 10; { 58C7 }
    d_34EC[d_682E].F1E := 0; { 58D5 }
    d_34EC[d_682E].F1F := 0; { 58E2 }
  end; { 58E7 }
  if Symbol = 'Q' then { 58F7 }
  begin { 58F7 }
    u2_2c6e(X, Y, 2, 465, 0, 0, 0, Foreground); { 5918 }
    Inc(d_682E); { 591B }
    u9_19f9(d_6D82^[2243], (X * 16), ((Y * 16) + 16)); { 593E }
    u9_19f9(d_6D82^[2243], (X * 16), ((Y * 16) + 416)); { 5962 }
    d_34EC[d_682E].F00 := 0; { 5971 }
    d_34EC[d_682E].F14 := 465; { 597D }
    d_34EC[d_682E].F02 := (X * 16); { 5993 }
    d_34EC[d_682E].F04 := (Y * 16); { 59A7 }
    d_34EC[d_682E].F06 := (X * 16); { 59BB }
    d_34EC[d_682E].F08 := (Y * 16); { 59CF }
    d_34EC[d_682E].F16 := 1; { 59DB }
    d_34EC[d_682E].F18 := 0; { 59EB }
    d_34EC[d_682E].F0A := 1; { 59F7 }
    d_34EC[d_682E].F1A := 0; { 5A07 }
    d_34EC[d_682E].F0C := (Random(20) + 55); { 5A1F }
    d_34EC[d_682E].F0E := 0; { 5A2D }
    d_34EC[d_682E].F1C := 11; { 5A39 }
    d_34EC[d_682E].F1E := 0; { 5A47 }
    d_34EC[d_682E].F1F := 0; { 5A54 }
  end; { 5A59 }
  if Symbol = '<' then { 5A69 }
  begin { 5A69 }
    u2_2c6e(X, Y, 2, 0, 487, 1, 0, Foreground); { 5A8A }
    Inc(d_682E); { 5A8D }
    u9_19f9(d_6D82^[5763], (X * 16), ((Y * 16) + 16)); { 5AB0 }
    u9_19f9(d_6D82^[5763], (X * 16), ((Y * 16) + 416)); { 5AD4 }
    d_34EC[d_682E].F00 := 0; { 5AE3 }
    d_34EC[d_682E].F14 := 487; { 5AEF }
    d_34EC[d_682E].F02 := (X * 16); { 5B05 }
    d_34EC[d_682E].F04 := (Y * 16); { 5B19 }
    d_34EC[d_682E].F06 := (X * 16); { 5B2D }
    d_34EC[d_682E].F08 := (Y * 16); { 5B41 }
    d_34EC[d_682E].F16 := 1; { 5B4D }
    d_34EC[d_682E].F18 := 0; { 5B5D }
    d_34EC[d_682E].F0A := 1; { 5B69 }
    d_34EC[d_682E].F1A := 0; { 5B79 }
    d_34EC[d_682E].F0C := (Random(20) + 55); { 5B91 }
    d_34EC[d_682E].F0E := 0; { 5B9F }
    d_34EC[d_682E].F1C := 12; { 5BAB }
    d_34EC[d_682E].F1E := 0; { 5BB9 }
    d_34EC[d_682E].F1F := 0; { 5BC6 }
  end; { 5BCB }
  if Symbol = '=' then { 5BDB }
  begin { 5BDB }
    u2_2c6e(X, Y, 2, 0, 491, 1, 0, Foreground); { 5BFC }
    Inc(d_682E); { 5BFF }
    u9_19f9(d_6D82^[6403], (X * 16), ((Y * 16) + 16)); { 5C22 }
    u9_19f9(d_6D82^[6403], (X * 16), ((Y * 16) + 416)); { 5C46 }
    d_34EC[d_682E].F00 := 0; { 5C55 }
    d_34EC[d_682E].F14 := 491; { 5C61 }
    d_34EC[d_682E].F02 := (X * 16); { 5C77 }
    d_34EC[d_682E].F04 := (Y * 16); { 5C8B }
    d_34EC[d_682E].F06 := (X * 16); { 5C9F }
    d_34EC[d_682E].F08 := (Y * 16); { 5CB3 }
    d_34EC[d_682E].F16 := 1; { 5CBF }
    d_34EC[d_682E].F18 := 0; { 5CCF }
    d_34EC[d_682E].F0A := 1; { 5CDB }
    d_34EC[d_682E].F1A := 0; { 5CEB }
    d_34EC[d_682E].F0C := (Random(20) + 55); { 5D03 }
    d_34EC[d_682E].F0E := 0; { 5D11 }
    d_34EC[d_682E].F1C := 13; { 5D1D }
    d_34EC[d_682E].F1E := 0; { 5D2B }
    d_34EC[d_682E].F1F := 0; { 5D38 }
  end; { 5D3D }
  if Symbol = ';' then { 5D4D }
  begin { 5D4D }
    u2_2c6e(X, (Y - 2), 2, 0, 428, 1, 0, 0); { 5D71 }
    u2_2c6e(X, (Y - 1), 2, 0, 0, 0, 0, Foreground); { 5D91 }
    u2_2c6e(X, Y, 2, 0, 427, 1, 0, 0); { 5DAF }
    Inc(d_682E); { 5DB2 }
    u9_19f9(d_6D7E^[4323], (X * 16), (((Y - 2) * 16) + 16)); { 5DD8 }
    u9_19f9(d_6D7E^[4323], (X * 16), (((Y - 2) * 16) + 416)); { 5DFF }
    u9_19f9(d_6D7E^[4163], (X * 16), ((Y * 16) + 16)); { 5E23 }
    u9_19f9(d_6D7E^[4163], (X * 16), ((Y * 16) + 416)); { 5E47 }
    d_34EC[d_682E].F00 := 0; { 5E56 }
    d_34EC[d_682E].F14 := 435; { 5E62 }
    d_34EC[d_682E].F02 := (X * 16); { 5E78 }
    d_34EC[d_682E].F04 := ((Y - 1) * 16); { 5E8D }
    d_34EC[d_682E].F06 := (X * 16); { 5EA1 }
    d_34EC[d_682E].F08 := ((Y - 1) * 16); { 5EB6 }
    d_34EC[d_682E].F16 := 1; { 5EC2 }
    d_34EC[d_682E].F18 := 0; { 5ED2 }
    d_34EC[d_682E].F0A := 1; { 5EDE }
    d_34EC[d_682E].F1A := 0; { 5EEE }
    d_34EC[d_682E].F0C := 30; { 5EFA }
    d_34EC[d_682E].F0E := Random(30); { 5F11 }
    d_34EC[d_682E].F1C := 15; { 5F1D }
    d_34EC[d_682E].F1E := 0; { 5F2B }
    d_34EC[d_682E].F1F := 0; { 5F38 }
  end; { 5F3D }
  if Symbol = '>' then { 5F4D }
  begin { 5F4D }
    u2_2c6e((X - 2), Y, 2, 0, 433, 1, 0, Foreground); { 5F72 }
    u2_2c6e((X - 1), Y, 2, 0, 0, 0, 0, Foreground); { 5F92 }
    u2_2c6e(X, Y, 2, 0, 434, 1, 0, Foreground); { 5FB1 }
    Inc(d_682E); { 5FB4 }
    u9_19f9(d_6D7E^[5123], ((X - 2) * 16), ((Y * 16) + 16)); { 5FDA }
    u9_19f9(d_6D7E^[5123], ((X - 2) * 16), ((Y * 16) + 416)); { 6001 }
    u9_19f9(d_6D7E^[5283], (X * 16), ((Y * 16) + 16)); { 6025 }
    u9_19f9(d_6D7E^[5283], (X * 16), ((Y * 16) + 416)); { 6049 }
    d_34EC[d_682E].F00 := 0; { 6058 }
    d_34EC[d_682E].F14 := 435; { 6064 }
    d_34EC[d_682E].F02 := ((X - 1) * 16); { 607B }
    d_34EC[d_682E].F04 := (Y * 16); { 608F }
    d_34EC[d_682E].F06 := ((X - 1) * 16); { 60A4 }
    d_34EC[d_682E].F08 := (Y * 16); { 60B8 }
    d_34EC[d_682E].F16 := 1; { 60C4 }
    d_34EC[d_682E].F18 := 0; { 60D4 }
    d_34EC[d_682E].F0A := 1; { 60E0 }
    d_34EC[d_682E].F1A := 0; { 60F0 }
    d_34EC[d_682E].F0C := 30; { 60FC }
    d_34EC[d_682E].F0E := Random(30); { 6113 }
    d_34EC[d_682E].F1C := 16; { 611F }
    d_34EC[d_682E].F1E := 0; { 612D }
    d_34EC[d_682E].F1F := 0; { 613A }
  end; { 613F }
  if Symbol = '?' then { 614F }
  begin { 614F }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 616F }
    Inc(d_682E); { 6172 }
    d_34EC[d_682E].F00 := 0; { 6180 }
    d_34EC[d_682E].F14 := 435; { 618C }
    d_34EC[d_682E].F02 := (X * 16); { 61A2 }
    d_34EC[d_682E].F04 := (Y * 16); { 61B6 }
    d_34EC[d_682E].F06 := (X * 16); { 61CA }
    d_34EC[d_682E].F08 := (Y * 16); { 61DE }
    d_34EC[d_682E].F16 := 1; { 61EA }
    d_34EC[d_682E].F18 := 0; { 61FA }
    d_34EC[d_682E].F0A := 1; { 6206 }
    d_34EC[d_682E].F1A := 0; { 6216 }
    d_34EC[d_682E].F0C := 30; { 6222 }
    d_34EC[d_682E].F0E := Random(30); { 6239 }
    d_34EC[d_682E].F1C := 17; { 6245 }
    d_34EC[d_682E].F1E := 0; { 6253 }
    d_34EC[d_682E].F1F := 0; { 6260 }
  end; { 6265 }
  if Symbol = 'A' then { 6275 }
  begin { 6275 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 6295 }
    Inc(d_682E); { 6298 }
    d_34EC[d_682E].F00 := 0; { 62A6 }
    d_34EC[d_682E].F14 := 435; { 62B2 }
    d_34EC[d_682E].F02 := (X * 16); { 62C8 }
    d_34EC[d_682E].F04 := (Y * 16); { 62DC }
    d_34EC[d_682E].F06 := (X * 16); { 62F0 }
    d_34EC[d_682E].F08 := (Y * 16); { 6304 }
    d_34EC[d_682E].F16 := 1; { 6310 }
    d_34EC[d_682E].F18 := 0; { 6320 }
    d_34EC[d_682E].F0A := 1; { 632C }
    d_34EC[d_682E].F1A := 0; { 633C }
    d_34EC[d_682E].F0C := 30; { 6348 }
    d_34EC[d_682E].F0E := Random(30); { 635F }
    d_34EC[d_682E].F1C := 18; { 636B }
    d_34EC[d_682E].F1E := 0; { 6379 }
    d_34EC[d_682E].F1F := 0; { 6386 }
  end; { 638B }
  if Symbol = '@' then { 639B }
  begin { 639B }
    u2_2c6e(X, Y, 2, 0, 302, 0, 0, Foreground); { 63BC }
    Inc(d_682E); { 63BF }
    d_34EC[d_682E].F00 := 0; { 63CD }
    d_34EC[d_682E].F14 := 305; { 63D9 }
    d_34EC[d_682E].F02 := (X * 16); { 63EF }
    d_34EC[d_682E].F04 := ((Y - 1) * 16); { 6404 }
    d_34EC[d_682E].F06 := (X * 16); { 6418 }
    d_34EC[d_682E].F08 := ((Y - 1) * 16); { 642D }
    d_34EC[d_682E].F16 := 0; { 643B }
    d_34EC[d_682E].F18 := 0; { 6449 }
    d_34EC[d_682E].F0A := (Random(18) + 1); { 645F }
    d_34EC[d_682E].F1A := 0; { 646D }
    d_34EC[d_682E].F0C := 0; { 647B }
    d_34EC[d_682E].F0E := 5; { 6487 }
    d_34EC[d_682E].F1C := 43; { 6495 }
    d_34EC[d_682E].F1E := 0; { 64A3 }
    d_34EC[d_682E].F1F := 0; { 64B0 }
  end; { 64B5 }
  if Symbol = #212 then { 64C5 }
  begin { 64C5 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 64E5 }
    Inc(d_682E); { 64E8 }
    d_34EC[d_682E].F00 := 0; { 64F6 }
    d_34EC[d_682E].F14 := 309; { 6502 }
    d_34EC[d_682E].F02 := (X * 16); { 6518 }
    d_34EC[d_682E].F04 := (Y * 16); { 652C }
    d_34EC[d_682E].F06 := (X * 16); { 6540 }
    d_34EC[d_682E].F08 := (Y * 16); { 6554 }
    d_34EC[d_682E].F16 := 0; { 6562 }
    d_34EC[d_682E].F18 := 0; { 6570 }
    d_34EC[d_682E].F0A := 1; { 657C }
    d_34EC[d_682E].F1A := 0; { 658C }
    d_34EC[d_682E].F0C := 0; { 659A }
    d_34EC[d_682E].F0E := 2; { 65A6 }
    d_34EC[d_682E].F1C := 44; { 65B4 }
    d_34EC[d_682E].F1E := 0; { 65C2 }
    d_34EC[d_682E].F1F := 0; { 65CF }
  end; { 65D4 }
  if Symbol = 'x' then { 65E4 }
  begin { 65E4 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 6604 }
    Inc(d_682E); { 6607 }
    d_34EC[d_682E].F00 := 0; { 6615 }
    d_34EC[d_682E].F14 := 259; { 6621 }
    d_34EC[d_682E].F02 := (X * 16); { 6637 }
    d_34EC[d_682E].F04 := (Y * 16); { 664B }
    d_34EC[d_682E].F06 := (X * 16); { 665F }
    d_34EC[d_682E].F08 := (Y * 16); { 6673 }
    d_34EC[d_682E].F16 := 0; { 6681 }
    d_34EC[d_682E].F18 := 0; { 668F }
    d_34EC[d_682E].F0A := 1; { 669B }
    d_34EC[d_682E].F1A := 0; { 66AB }
    d_34EC[d_682E].F0C := 0; { 66B9 }
    d_34EC[d_682E].F0E := 2; { 66C5 }
    d_34EC[d_682E].F1C := 44; { 66D3 }
    d_34EC[d_682E].F1E := 0; { 66E1 }
    d_34EC[d_682E].F1F := 0; { 66EE }
  end; { 66F3 }
end;
