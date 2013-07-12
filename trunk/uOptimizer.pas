unit uOptimizer;

interface
uses
  Classes, uEmitFuncMgr, uconst;
{
所谓的窥孔优化就是寻找特征码，找到了这个这个特征就替换掉
例如：
call func
pop t
mov t a
可以优化成
call func
pop a
}

function PeepHoleOptimize(ACode: TEmitFunc): TEmitFunc;
implementation

function PeepHoleOptimize(ACode: TEmitFunc): TEmitFunc;
var
  Value: TValue;
  procedure GetValue(var P: PAnsiChar);
  begin
    Value._Type := _PEmitInts(P)^;
    Inc(P, SizeOf(_TEmitInts));
    Value._Int := PInteger(P)^;
    Inc(P, SizeOf(Integer));
  end;
var
  CodeBuf: PAnsiChar;
  Ints: _TEmitInts;
  I: Integer;
begin
  I := 0;
  while I >= ACode.CodeLineCount - 1 do
  begin
    CodeBuf := ACode.Code[i];
    Ints := _PEmitInts(CodeBuf)^;
    Inc(CodeBuf, SizeOf(_TEmitInts));
    case Ints of
      igetobjv,
        isub,
        iadd,
        imul,
        idiv,
        imod:
        begin
          Inc(CodeBuf, (SizeOf(_TEmitInts) + SizeOf(Integer)) * 2);
          GetValue(CodeBuf);
        end;
      imov,
        icmp:
        begin
          Inc(CodeBuf, (SizeOf(_TEmitInts) + SizeOf(Integer)));
          GetValue(CodeBuf);
        end;
      inewobj,
        ipush,
        ipop,
        iebp,
        icall,
        iread,
        iwrite:
        begin
          GetValue(CodeBuf);
          Writeln('');
        end;
    end;
  end;
  Result := TEmitFunc.Create;
  Result.FuncName := ACode.FuncName;
  for I := 0 to ACode.CodeLineCount - 1 do
  begin
    Result.AddACode(ACode.Code[I])
  end;
end;

end.
