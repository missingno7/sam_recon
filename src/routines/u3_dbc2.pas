{@decls}
const
  Border = #176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176;
{@stubs}

{@body}
procedure u3_dbc2;
var
  I, D_2, D_3, D_4: Word;
begin
  TextMode(3);
  ClrScr;
  GotoXY(1, 1);
  for I := 0 to 19 do
  begin
    u4_0399(4 * I + 1, 1, 8, 0, Border);
    u4_0399(4 * I + 2, 1, 7, 0, Border);
    u4_0399(4 * I + 3, 1, 15, 0, Border);
    u4_0399(4 * I + 4, 1, 7, 0, Border);
  end;
{$IFDEF SAM1}
  u4_0309(9, 2, 72, 4, 15, 4, 3);
  u4_0349(3, 15, 4, ' HOW TO ORDER THE FINAL TWO AMAZING EPISODES OF SECRET AGENT');
  u4_0309(5, 7, 76, 21, 3, 4, 3);
  u4_0349(8, 14, 4, ' The final two episodes of SECRET AGENT continue your adventure');
  u4_0349(9, 14, 4, ' as the heroic super spy 006'#171'.  You''ll encounter fun and danger');
  u4_0349(10, 14, 4, ' on two all-new islands, packed with new graphics and challenges.');
  u4_0349(12, 14, 4, ' By ordering the final two episodes of SECRET AGENT you''ll get:');
  u4_0349(13, 14, 4, ' The hints and tricks sheet, the cheat password, and an all-new');
  u4_0349(14, 14, 4, ' bonus game from Apogee Software for you to try out.');
  u4_0349(16, 15, 4, ' Apogee Software             CALL TOLL FREE!  ');
  u4_0349(17, 15, 4, ' P.O. Box 476389              1-800-GAME123   ');
  u4_0349(18, 15, 4, ' Garland, TX 75047          Visa or MasterCard ');
  u4_0349(20, 14, 4, ' Or mail $34 (check or money order) to order SECRET AGENT.');
{$ELSE}
  u4_0101(1, 1, 80, 24, 3, 1, 4);
  u4_0309(5, 3, 76, 6, 128, 6, 7);
  u4_0349(4, 15, 6, ' NOTICE: THIS GAME IS NOT SHAREWARE, FREEWARE NOR PUBLIC DOMAIN!');
  u4_0349(5, 15, 6, ' THIS GAME MAY ONLY BE DISTRIBUTED BY AUTHORIZED APOGEE DEALERS.');
  u4_0309(5, 8, 76, 22, 2, 4, 3);
  u4_0349(9, 15, 4, ' Only the first episode of SECRET AGENT is available as shareware.');
  u4_0349(11, 14, 4, ' The remaining two episodes (including this episode), are only sold');
  u4_0349(12, 14, 4, ' by Apogee Software, or through authorized distributors.');
  u4_0349(14, 14, 4, ' Bulletin boards, shareware vendors, user groups and clubs MAY NOT');
  u4_0349(15, 14, 4, ' distribute this episode of SECRET AGENT without lawful penalties.');
  u4_0349(17, 14, 4, ' SECRET AGENT consists of three unique and exciting episodes:');
  u4_0349(18, 14, 4, ' The Hunt for Red Rock Rover - Kill Again Island - Dr. No Body');
  u4_0349(20, 15, 4, ' To order the complete SECRET AGENT trilogy, call 1-800-GAME123');
  u4_0349(21, 15, 4, ' Or write:  Apogee Software  P.O. Box 476389  Garland, TX 75047');
{$ENDIF}
  TextColor(3);
  TextBackground(0);
  GotoXY(1, 24);
end;
