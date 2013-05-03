unit uexec;

interface

uses
  uconst, SysUtils, Classes, ucorefunc, uproptable, uobjmgr;

type
  TFunction = procedure;

  TExec = class
  private
    globlevar: array [0 .. 1024 * 1024] of TValue;
    tempvar: array [0 .. 1024 * 1024] of TValue;
    FStack: array [0 .. 1024 * 1024] of TValue;
    CallStack, VarX: array [0 .. 1024] of Integer;
    FESP, EBP, CallESP, VarXSP: Integer;
    FStringList: TStringList;
    FCode: TList;
    FCodeCount: Integer;
    FCodeLen: Word;
    FPropTable: TPropTable;
    FIP, FIPEnd: Integer;
    FFunctionList: TStringList;
    FObjMgr, FCopyObjMgr: TObjMgr;
    procedure RunError(S: string);
    function GetStack(Index: Integer): PValue;
    procedure SetStack(Index: Integer; const Value: PValue);
  public
    constructor Create(APropTable: TPropTable);
    procedure CoreExec();
    procedure Exec();
    property StringList: TStringList read FStringList;
    property Code: TList read FCode;
    property CodeCount: Integer read FCodeCount;
    property CodeLen: Word read FCodeLen;
    property IP: Integer read FIP write FIP;
    property IPEnd: Integer read FIPEnd write FIPEnd;
    function RegisterFunction(AFuncName: string; AFuncAddr: Pointer): Boolean;
    property Stack[Index: Integer]: PValue read GetStack write SetStack;
    property ESP: Integer read FESP;
  end;

implementation

uses
  uemitter;

procedure TExec.RunError(S: string);
begin
  raise Exception.Create('RunTimeError: ' + S + 'On Line: ' + IntToStr(IP));
end;

procedure TExec.Exec;
begin
  try
    CoreExec
  except
    on E: Exception do
      Writeln(E.Message);
  end;
end;

constructor TExec.Create(APropTable: TPropTable);
begin
  if not Assigned(APropTable) then
    raise Exception.Create('PropTable is nil in TExec');
  FPropTable := APropTable;
  FStringList := TStringList.Create;
  FCode := TList.Create;
  FFunctionList := TStringList.Create;
  FObjMgr := TObjMgr.Create;
  FCopyObjMgr := TObjMgr.Create;
end;

procedure TExec.CoreExec();
var
  CodeBuf: PAnsiChar;
  Ints: _TEmitInts;
  _p1, _p2, _p3, _pt: PValue;
  __p1, __p2, __p3: TValue;
  neg: Integer;
  ER, BR: Boolean;
  S: string;
  I: Integer;
  m_FuncProp: PFuncProp;
  VarI: Integer;
  Obj: TObj;
  procedure GetValue(var P: PAnsiChar; var Value: PValue);
  var
    I: Integer;
    T: _TEmitInts;
  begin
    Value._Type := _PEmitInts(P)^;
    Inc(P, SizeOf(_TEmitInts));
    case Value._Type of
      pobject:
        begin
          Value._Int := PInteger(P)^;
          Inc(P, SizeOf(Integer));
        end;
      ivalue:
        begin
          Value._Int := PInteger(P)^;
          Inc(P, SizeOf(Integer));
        end;
      pint, pfunc:
        begin
          Value._Int := PInteger(P)^;
          Inc(P, SizeOf(Integer));
        end;
      pstring:
        begin
          Value._Int := PInteger(P)^;
          Value._String := StringList[Value._Int];
          Inc(P, SizeOf(Integer));
        end;
      iident:
        begin
          I := PInteger(P)^;
          Inc(P, SizeOf(Integer));
          if I > 0 then
          begin
            Value := @globlevar[I];
            Value._Id := FPropTable.GetFuncVarPropTable(0, I);
          end
          else
          begin
            Value := @tempvar[EBP - I];
            Value._Id := FPropTable.GetFuncVarPropTable(VarI, -I);
          end;
        end;
      pfuncaddr:
        begin
          I := PInteger(P)^;
          Inc(P, SizeOf(Integer));
          if I > 0 then
          begin
            Value := @globlevar[I];
            Value._Id := FPropTable.GetFuncVarPropTable(0, I);
          end
          else
          begin
            Value := @tempvar[EBP - I];
            Value._Id := FPropTable.GetFuncVarPropTable(VarI, -I);
          end;
          Value._Type := pfuncaddr;
        end;
    end;
  end;

  procedure Str2Int(var Value: PValue);
  begin
    Value._Type := pint;
    Value._Int := StrToIntDef(Value._String, 0);
  end;

  procedure Int2Str(var Value: PValue);
  begin
    Value._Type := pstring;
    Value._String := IntToStr(Value._Int)
  end;

begin
  VarI := 0;
  VarXSP := -1;
  ER := False;
  BR := False;
  EBP := 0;
  while IP < IPEnd do
  begin
    _p1 := @__p1;
    _p2 := @__p2;
    _p3 := @__p3;
    CodeBuf := Code[IP];
    Ints := _PEmitInts(CodeBuf)^;
    Inc(CodeBuf, SizeOf(_TEmitInts));
    case Ints of
      igetobjv:
        begin
          GetValue(CodeBuf, _p1); // obj
          GetValue(CodeBuf, _p2); // objvalue
          GetValue(CodeBuf, _p3); // copyvalue
          _pt := TObj(_p1._Object).FindAValue(_p2._Int);
          if _pt <> nil then
            _p3^ := _pt^
          else
            // 再建立一个物体的属性表，修改下
            RunError('ObjectValue 0x' + IntToHex(Integer(_p1._Object), 8) +
              ' is not exist');

        end;
      iputobjv:
        begin
          GetValue(CodeBuf, _p1); // obj
          GetValue(CodeBuf, _p2); // objvalue
          GetValue(CodeBuf, _p3); // copyvalue
          // _p1._Object := FObjMgr.GetAObject(_p1._Int);
          TObj(_p1._Object).AddAValue(_p2._Int, _p3^)
        end;
      inewobj:
        begin
          GetValue(CodeBuf, _p1);
          if _p1._Int >= FCopyObjMgr.ObjectCount then
            Obj := TObj.Create(FCopyObjMgr);
        end;
      icopyobj:
        begin
          GetValue(CodeBuf, _p1); // obj
          GetValue(CodeBuf, _p2); // copyvalue
          Obj := TObj.Create(FObjMgr);
          _p1._Object := FCopyObjMgr.GetAObject(_p1._Int);
          TObj(_p1._Object).CopyTo(Obj);
          _p2._Type := pobject;
          _p2._Int := _p1._Int;
          _p2._Object := Obj;
        end;
      inop:
        begin
        end;
      ipush:
        begin
          GetValue(CodeBuf, _p1);
          Inc(FESP);
          FStack[FESP] := _p1^;
          _p1^._Type := inone;
        end;
      ipop:
        begin
          GetValue(CodeBuf, _p1);
          _p1^ := FStack[FESP];
          FStack[FESP]._Type := inone;
          Dec(FESP);
        end;
      iret:
        begin
          IP := CallStack[CallESP];
          Dec(CallESP);

          VarI := VarX[VarXSP];
          Dec(VarXSP);
          Continue;
        end;
      iebp:
        begin
          GetValue(CodeBuf, _p1);
          Inc(EBP, _p1._Int);
        end;
      icall:
        begin
          Inc(CallESP);
          CallStack[CallESP] := IP + 1;
          GetValue(CodeBuf, _p1);
          m_FuncProp := FPropTable.funcproptable[_p1._Int];
          if m_FuncProp.EntryAddr = -1 then
          begin
            I := FFunctionList.IndexOf(m_FuncProp.FuncName);
            if I <> -1 then
            begin
              TFunction(FFunctionList.Objects[I])();
              Inc(FIP);
              Continue;
            end
            else
            begin
              _p1._String := m_FuncProp.FuncName;
              RunError('function: "' + _p1._String + '" is not def');
            end;
          end;
          IP := m_FuncProp.EntryAddr;
          Inc(VarXSP);
          VarX[VarXSP] := VarI;
          VarI := _p1._Int;
          Continue;
        end;
      iread:
        begin
          GetValue(CodeBuf, _p1);
          if _p1._Type = pint then
            CoreRead(_p1._Int)
          else
          begin
            _p1._Type := pstring;
            CoreRead(_p1._String)
          end;
        end;
      iwrite:
        begin
          GetValue(CodeBuf, _p1);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def on line:' +
              IntToStr(IP));
          case _p1._Type of
            pint:
              CoreWrite(_p1._Int);
            pstring:
              CoreWrite(_p1._String);
          end;
        end;
      imov:
        begin
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def');
          case _p1._Type of
            pfuncaddr:
              begin
                _p2._Type := pfuncaddr;
                FPropTable.funcproptable[_p2._Int] := FPropTable.funcproptable
                  [_p1._Int];
              end;
            pint:
              begin
                _p2._Type := pint;
                _p2._Int := _p1._Int;
              end;
            pstring:
              begin
                _p2._Type := pstring;
                _p2._Int := _p1._Int;
                _p2._String := _p1._String;
              end;
            pobject:
              begin
                _p2._Type := pobject;
                _p2._Int := _p1._Int;
                _p2._String := _p1._String;
                _p2._Object := _p1._Object;
              end;
          end;
        end;
      isub, iadd:
        begin
          if Ints = iadd then
            neg := 1
          else
            neg := -1;
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          GetValue(CodeBuf, _p3);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def');
          if _p2._Type = inone then
            RunError('var "' + _p2._Id + '" is not def');
          case _p1._Type of
            pint:
              begin
                if _p2._Type = pstring then
                  Str2Int(_p2);
                _p3._Type := pint;
                _p3._Int := _p1._Int + _p2._Int * neg;
              end;
            pstring:
              begin
                if _p2._Type = pint then
                  Int2Str(_p2);
                _p3._Type := pstring;
                S := StringList.Strings[_p1._Int] + StringList.Strings
                  [_p2._Int];
                I := StringList.IndexOf(S);
                if I = -1 then
                  I := StringList.Add(S);
                _p3._Int := I;
              end;
          end;
        end;
      imul:
        begin
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          GetValue(CodeBuf, _p3);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def on line:' +
              IntToStr(IP));
          if _p2._Type = inone then
            RunError('var "' + _p2._Id + '" is not def on line:' +
              IntToStr(IP));
          case _p1._Type of
            pint:
              begin
                if _p2._Type = pstring then
                  Str2Int(_p2);
                _p3._Type := pint;
                _p3._Int := _p1._Int * _p2._Int;
              end;
          else
            RunError('var "' + _p1._Id + '" type error on line:' +
              IntToStr(IP));
          end;
        end;
      idiv:
        begin
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          GetValue(CodeBuf, _p3);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def on line:' +
              IntToStr(IP));
          if _p2._Type = inone then
            RunError('var "' + _p2._Id + '" is not def on line:' +
              IntToStr(IP));
          case _p1._Type of
            pint:
              begin
                if _p2._Type = pstring then
                  Str2Int(_p2);
                _p3._Type := pint;
                _p3._Int := _p1._Int div _p2._Int;
              end;
          else
            RunError('var "' + _p1._Id + '" type error on line:' +
              IntToStr(IP));
          end;
        end;
      imod:
        begin
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          GetValue(CodeBuf, _p3);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def on line:' +
              IntToStr(IP));
          if _p2._Type = inone then
            RunError('var "' + _p2._Id + '" is not def on line:' +
              IntToStr(IP));
          case _p1._Type of
            pint:
              begin
                if _p2._Type = pstring then
                  Str2Int(_p2);
                _p3._Type := pint;
                _p3._Int := _p1._Int mod _p2._Int;
              end;
          else
            RunError('var "' + _p1._Id + '" type error on line:' +
              IntToStr(IP));
          end;
        end;
      icmp:
        begin
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          case _p1._Type of
            inone:
              begin
                if _p2._Type = _p1._Type then
                  ER := True
                else
                  ER := False;
              end;
            pint:
              begin
                if _p2._Type = pstring then
                  Str2Int(_p2);
                if _p1._Int = _p2._Int then
                  ER := True
                else
                  ER := False;

                if _p1._Int > _p2._Int then
                  BR := True
                else
                  BR := False;
              end;
            pstring:
              begin
                if _p2._Type = pint then
                  Int2Str(_p2);
                if _p1._String = _p2._String then
                  ER := True
                else
                  ER := False;
              end;
          end;
        end;
      ijmp:
        begin
          GetValue(CodeBuf, _p1);
          Inc(FIP, _p1._Int);
          Continue;
        end;
      ije:
        begin
          if ER then
          begin
            GetValue(CodeBuf, _p1);
            Inc(FIP, _p1._Int);
            Continue;
          end;
        end;
      ijne:
        begin
          if not ER then
          begin
            GetValue(CodeBuf, _p1);
            Inc(FIP, _p1._Int);
            Continue;
          end;
        end;
      ijse:
        begin
          if (not BR) or (ER) then
          begin
            GetValue(CodeBuf, _p1);
            Inc(FIP, _p1._Int);
            Continue;
          end;
        end;
      ijs:
        begin
          if not BR then
          begin
            GetValue(CodeBuf, _p1);
            Inc(FIP, _p1._Int);
            Continue;
          end;
        end;
      ijbe:
        begin
          if BR or ER then
          begin
            GetValue(CodeBuf, _p1);
            Inc(FIP, _p1._Int);
            Continue;
          end;
        end;
      ijb:
        begin
          if BR then
          begin
            GetValue(CodeBuf, _p1);
            Inc(FIP, _p1._Int);
            Continue;
          end;
        end;
      ihalt:
        begin
          CoreWrite('Halt');
          Break;
        end;
    end;
    Inc(FIP);
  end;
end;

function TExec.GetStack(Index: Integer): PValue;
begin
  Result := @FStack[Index]
end;

function TExec.RegisterFunction(AFuncName: string; AFuncAddr: Pointer): Boolean;
begin
  Result := False;
  if FFunctionList.IndexOf(AFuncName) = -1 then
  begin
    FFunctionList.AddObject(AFuncName, TObject(AFuncAddr));
    Result := True;
  end;
end;

procedure TExec.SetStack(Index: Integer; const Value: PValue);
begin
  FStack[Index] := Value^
end;

end.
