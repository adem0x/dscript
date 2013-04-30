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
begin
  with TStringList.Create do
  begin
    LoadFromFile('1.lua');
    Source := GetText;
  end;
//   Source := ' var a= 4; b = 5; c= a + b * 2 / 3; write c @';
  // Source := 'a = 3; b = 2; c = 5; if a < b then c=a end write c @';
//   Source := 'x = ''100''; y=x + 10; write y @';
//  Source := 'function add2(c, d) begin return add(c,d) end;' +
//    Source := 'add = function(a,b) begin if a> b then return a else return b end; return 100 end;' +
//    'function add2(a,b) begin  var d= add(a, b) * 2; return d end;'+
//    ' write add2(3, 4)';
//  Source := 'write 4 % 2 @' ;
//   Source := 'i = 10; while i > 0 do i = i - 1; if i % 2 = 0 then continue  end; write i end;';
  try
  gPropTable := TPropTable.Create;
  gExec := TExec.Create(gPropTable);
  gEmitter:= TEmitter.Create(gExec, gPropTable);
  TParser.Create(gEmitter, gPropTable).parser(Source);
  writeln;
  writeln('parser over!');
  gExec.Exec
  except
    on E: Exception do
      writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.
