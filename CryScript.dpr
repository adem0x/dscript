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
  uobjmgr in 'uobjmgr.pas',
  uEmitFuncMgr in 'uEmitFuncMgr.pas',
  uOptimizer in 'uOptimizer.pas',
  uDataStruct in 'uDataStruct.pas',
  mycontnrs in 'mycontnrs.pas';

var
  Source: PAnsiChar;
  gExec: TExec;
  gEmitter: TEmitter;
  gPropTable: TPropTable;
  gParser: TParser;
//  p1: TValue;

procedure MyWrite;
var
  v: PValue;
begin
  v := gExec.Stack[gExec.ESP];
  if v._Type = pint then
    Writeln(v._int)
  else if v._Type = pstring then
    Writeln(gExec.StringList.Get(v._Int))
end;

begin
  Source := nil;
//
  with TStringList.Create do
  begin
    LoadFromFile('test\2.lua');
    Source := PAnsiChar(AnsiString(GetText));
  end;

//  Source := 'require ''test\add'' a = add.add(5, 2); write a';
//  Source := 'c= 4*3 / 2; write c';
//  Source := 'a= 4; b = 5; c= a + b * 2 / 3; write c';
//  Source := 'a = 3; b = 2; c = 5; if a < b then c=a end write c ';
//  Source := 'fac = function(n) if n = 0 then return 1  else return n * fac(n); end; end;  write fac(5)';
//  Source := 'add = function(a,b)  var c= a + b; return c end;' +
//  'function add2(a,b) d= add(a, b) * 2; return d end;'+
//  'f = add(add2(5,2), 3); write f';
//  Source := 'function add2(c, d) return add(c,d) end;' +
//  Source := 'add = function(a,b)  var c= a + b; return c end;' +
//  'function add2(a,b) d= add(a, b) * 2; return d end;'+
//  'f = add(add2(1,2), 3); write f';
//  Source := 's = ''9999''; print(s); s = 1; print(s);';
//  Source := 'f = {i}; f.i = 100; write f.i;' ;
//  Source := 'i = 10; while i > 0 do i = i - 1; if i % 2 = 0 then continue  end; write i end;';
//  Source := 'f = {i = 10; next = ''abc''}; write f.next; ';
//  Source := 'f = nil; for j = 1, 10 do f = {i = j; next = f}; end; write 100;' +
//  'for j = 1, 10 do write f.i; f = f.next; end; ';
//  Source := 'f = {add = function(a,b)  return a + b end} i = f.add(9, 2); write i';
//  Source := 'function add(a,b)  return a + b end; func = add; i = add(1, 2); write i';
//  Source := 'f = {i = 1}; f.i = 99; h = f; write h.i ';
//  Source := 'f = nil; for j = 1, 10 do f = {i = j; next = f}; end; write 100;'
//  +
//  'for j = 1, 10 do write f.i; f = f.next; end; ' ;
//  无脑支持forward，aha，原理太简单了add2是个全局变量。。。return的时候分配地址，定义的时候赋值
//  Source := 'function add(a,b)  return add2(2)  end;   function add2(a) return a * 2 end  i = add(1, 2); write i';
//  Source := 'function rec(a) if a > 1 then return rec(a - 1 ) else return 1 end; end; write rec(10)';
//  Source :='f ={}; b = function() return 100; end; f.a = b; write f.a()';
//  Source :='f = {i = 10}; write f.i; f = 100; write f;';
//  Source := 'f = {}; for i = 1, 10 do f[i] = i * i; end; for i = 1, 10 do write f[i]; end; write f[5]';
//  Source := 'a = {}; b = {i = 88}; a.prototype = b; write a.i';
//  Source := 'f = {add2 = function(c,d) function add(a, b) return a + b; end; return c + d + add(c, d); end;};write f.add2(1, 5)';
//  Source := 'function add2(c,d) return c + d; end; function add(a, b)  return a + b + add2(a, b); end; write add(1, 5)';
  try
    IO := TConsoleIO.Create;
    gPropTable := TPropTable.Create;
    gExec := TExec.Create(gPropTable);
    gEmitter := TEmitter.Create(gExec, gPropTable);
    gEmitter.Opt := True;
    gParser := TParser.Create(gEmitter, gPropTable);
    gParser.Opt := True;
    if gParser.parser(Source) then
    begin
      gExec.RegisterFunction('print', @MyWrite);
      Writeln('exec start!');
      gExec.Exec;
      Writeln('exec end!');
//    p1._Type := pint;
//    p1._Int := 10;
//    gExec.SetParam(p1);
//    p1._Type := pint;
//    p1._Int := 20;
//    gExec.SetParam(p1);
//    gExec.ExecuteFunc('add');
//    p1 := gExec.GetResult;
//    Writeln(p1._int);
//    MyWrite;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.

