program OverArr;
{$S-}{$R-}{$I-}{$B-}
type TArray = array[-1..0] of Integer;
     TGrid = array[2..3, -1..0] of Integer;
var a: TArray; neighbour: Integer;
    grid: TGrid; afterGrid: Integer;
    index: Integer;
begin
  a[-1]:=11; a[0]:=22; neighbour:=33;
  index:=1; a[index]:=44;
  Writeln(a[-1],' ',a[0],' ',neighbour,' ',a[index]);
  grid[2,-1]:=1; grid[2,0]:=2; grid[3,-1]:=3; grid[3,0]:=4;
  afterGrid:=5; index:=4; grid[index,-1]:=66;
  Writeln(grid[2,-1],' ',grid[3,0],' ',afterGrid,' ',grid[index,-1]);
  Writeln(Ofs(neighbour)-Ofs(a),' ',Ofs(afterGrid)-Ofs(grid));
end.
