program Compiler;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  uparser in 'uparser.pas',
  ulex in 'ulex.pas',
  uemitter in 'uemitter.pas',
  uconst in 'uconst.pas',
  ucorefunc in 'ucorefunc.pas',
  uexec in 'uexec.pas',
  uproptable in 'uproptable.pas',
  uobjmgr in 'uobjmgr.pas';

var
  Source: PAnsiChar;
  gExec: TExec;
  gEmitter: TEmitter;
  gPropTable: TPropTable;
  gParser: TParser;

procedure MyWrite;
var
  v: PValue;
begin
  v := gExec.Stack[gExec.ESP];
  Writeln(v._int)
end;

begin

  // with TStringList.Create do
  // begin
  // LoadFromFile('1.lua');
  // Source := PAnsiChar(AnsiString(GetText));
  // end;
  // Source := 'c= 4*3 / 2; write c';
  // Source := 'a= 4; b = 5; c= a + b * 2 / 3; write c @';
  // Source := 'a = 3; b = 2; c = 5; if a < b then c=a end write c @';
  // Source := 'x = ''100''; y=x + 10; write y @';
  // Source := 'function add2(c, d) return add(c,d) end;' +
  // Source := 'add = function(a,b)  var c= a + b; return c end;' +
  // 'function add2(a,b) d= add(a, b) * 2; return d end;'+
  // 'f = add(add(1,2), 3); write f';
  // Source := 'mywrite(100)';
  // Source := 'write 4 % 2 @' ;
  // Source := 'i = 10; while i > 0 do i = i - 1; if i % 2 = 0 then continue  end; write i end;';
  // Source := 'f = {i = 10; next = f};';
  Source := ' j = 1; for i = j, 10, 2 do write i end; write ''end''';
  // Source := 'write ''end''';
  try
    gPropTable := TPropTable.Create;
    gExec := TExec.Create(gPropTable);
    gEmitter := TEmitter.Create(gExec, gPropTable);
    gParser := TParser.Create(gEmitter, gPropTable);
    gParser.Opt := True;
    gParser.parser(Source);
    Writeln;
    Writeln('parser over!');
    Writeln('exec start!');
    gExec.RegisterFunction('mywrite', @MyWrite);
    gExec.Exec;
    Writeln('exec end!');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.
