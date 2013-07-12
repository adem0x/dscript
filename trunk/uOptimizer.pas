unit uOptimizer;

interface
uses
  Classes, uEmitFuncMgr, uconst;
{
��ν�Ŀ����Ż�����Ѱ�������룬�ҵ����������������滻��
���磺
call func
pop t
mov t a
�����Ż���
call func
pop a
}

procedure PeepHoleOptimize(ACode: TEmitFunc);
implementation

procedure PeepHoleOptimize(ACode: TEmitFunc);
var
  _p1, _p2: TValue;
  function GetValue(var P: PAnsiChar): TValue;
  begin
    Result._Type := _PEmitInts(P)^;
    Inc(P, SizeOf(_TEmitInts));
    Result._Int := PInteger(P)^;
    Inc(P, SizeOf(Integer));
  end;
  procedure SetValue(var P: PAnsiChar; AValue: TValue);
  begin
    _PEmitInts(P)^ := AValue._Type;
    Inc(P, SizeOf(_TEmitInts));
    PInteger(P)^ := AValue._Int;
    Inc(P, SizeOf(Integer));
  end;
var
  CodeBuf, CodeBuf1, CodeBuf2: PAnsiChar;
  Ints: _TEmitInts;
  I: Integer;
begin
  Exit;
  {��Ϊ��ɾ�����룬�������ת��λ�ƶ�Ҫ������������Ƚϸ��ӣ���ǰ����ֻ�ܴ�������
  ��ת������ֻ�ܴ�������ת����ʱû���뵽�õķ������Ż����������ΰ�}
  I := ACode.CodeLineCount - 1;
  while I >= 0 do
  begin
    CodeBuf := ACode.Code[i];
    Ints := _PEmitInts(CodeBuf)^;
    case Ints of
      ijmp, ijse, ijbe, ijs, ijb, ije, ijne:
      begin
        _p1 := GetValue(CodeBuf);
        if _p1._Int < 0 then Inc(I, _p1._Int)
      end;
      imov:
      begin
        //like
        // icall xxx
        // pop tempvar
        // mov tempvar globlevar
        //to
        // icall xxx
        // pop globlevar
        CodeBuf1 := ACode.Code[i - 1];
        Ints := _PEmitInts(CodeBuf1)^;
        if Ints = ipop then
        begin
          CodeBuf2 := ACode.Code[i - 2];
          Ints := _PEmitInts(CodeBuf2)^;
          if Ints = imov then
          begin
            Inc(CodeBuf1, SizeOf(_TEmitInts));
            Inc(CodeBuf2, SizeOf(_TEmitInts));
            _p1 := GetValue(CodeBuf1);
            _p2 := GetValue(CodeBuf2);
            if (_p1._Type = _p2._Type) and (_p1._Int = _p2._Int) then
            begin
              _p2 := GetValue(CodeBuf2);
              CodeBuf1 := ACode.Code[i - 1];
              Inc(CodeBuf1, SizeOf(_TEmitInts));
              SetValue(CodeBuf1, _p2);
              ACode.DeleteCode(I - 2);
              Dec(I, 2);
            end;
          end;
        end;
      end;
    end;
    Dec(I);
  end;
end;

end.
