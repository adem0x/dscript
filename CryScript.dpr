program CryScript;
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
  if v._Type = pint then
    Writeln(v._int)
  else if v._Type = pstring then
    Writeln(v._String)
end;

begin

  // with TStringList.Create do
  // begin
  // LoadFromFile('test\1.lua');
  // Source := PAnsiChar(AnsiString(GetText));
  // end;

//  Source := 'function add(a, b) return a+ b; end; add2 = add; write add2(1, 2)';
//   Source := 'c= 4*3 / 2; write c';
  // Source := 'a= 4; b = 5; c= a + b * 2 / 3; write c';
  // Source := 'a = 3; b = 2; c = 5; if a < b then c=a end write c ';
  // Source := 'x = ''100''; y=x + 10; write y ';
//   Source := 'add = function(a,b)  var c= a + b; return c end;' +
//   'function add2(a,b) d= add(a, b) * 2; return d end;'+
//   'f = add(add2(5,2), 3); write f';
//   Source := 'function add2(c, d) return add(c,d) end;' +
//   Source := 'add = function(a,b)  var c= a + b; return c end;' +
//   'function add2(a,b) d= add(a, b) * 2; return d end;'+
//   'f = add(add2(1,2), 3); write f';
  // Source := 'mywrite(100)';
//   Source := 'f = {i}; f.i = 100; write f.i;' ;
  // Source := 'i = 10; while i > 0 do i = i - 1; if i % 2 = 0 then continue  end; write i end;';
//   Source := 'f = {i = 10; next = ''abc''}; write f.next; ';
//   Source := 'f = nil; for j = 1, 10 do f = {i = j; next = f}; end; write 100;' +
//   'for j = 1, 10 do write f.i; f = f.next; end; ';
//  Source := 'f = {add = function(a,b)  return a + b end} i = f.add(1, 2); write i';
  Source := 'function add(a,b)  return a + b end; func = add; i = add(1, 2); write i';
//   Source := 'f = {i = 10; next = ''abc''}; write f.next; write f.i ';
//   Source := 'f = nil; for j = 1, 10 do f = {i = j; next = f}; end; write 100;'
//   +
//   'for j = 1, 10 do write f.i; f = f.next; end; ' ;
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
    gExec.RegisterFunction('print', @MyWrite);
    gExec.Exec;
    Writeln('exec end!');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.
