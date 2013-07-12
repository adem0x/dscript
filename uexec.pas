unit uExec;

interface

uses
  uconst, SysUtils, Classes, ucorefunc, uproptable, uobjmgr, uDataStruct;

type
  TFunction = procedure;

  TExec = class
  private
    globlevar: array[0..1024 * 1024] of TValue;
    tempvar: array[0..1024 * 1024] of TValue;
    FStack: array[0..1024 * 1024] of TValue;
    CallStack: array[0..1024] of Integer; //ret ip
    FESP, EBP, CallESP: Integer;
    FStringList: TQuickStringList;
    FCode: TList;
    FCodeCount: Integer;
    FCodeLen: Word;
    FPropTable: TPropTable;
    FIP, FIPEnd: Integer;
    FFunctionList: TStringList;
    FObjMgr: TObjMgr;
    FCurrentUpValue: PValues;
    FMovclosureList: TList;
    FGc: Integer;
    FStop: Boolean;
    FStoped: Boolean;
    procedure RunError(S: string);
    function GetStack(Index: Integer): PValue;
    procedure SetStack(Index: Integer; const Value: PValue);
    procedure SetStop(const Value: Boolean);
  public
    constructor Create(APropTable: TPropTable);
    procedure CoreExec();
    procedure Exec();
    property StringList: TQuickStringList read FStringList;
    property Code: TList read FCode;
    property CodeCount: Integer read FCodeCount;
    property CodeLen: Word read FCodeLen;
    property IP: Integer read FIP write FIP;
    property IPEnd: Integer read FIPEnd write FIPEnd;
    function RegisterFunction(AFuncName: string; AFuncAddr: Pointer): Boolean;
    property Stack[Index: Integer]: PValue read GetStack write SetStack;
    property ESP: Integer read FESP;
    procedure Mark;
    procedure Sweep;
    procedure GarbageCollection;
    function ExecuteFunc(AFuncName: string): Boolean;
    procedure SetParam(AValue: TValue);
    function GetResult: TValue;
    property Stop: Boolean read FStop write SetStop;
    property Stoped: Boolean read FStoped;
  end;

implementation

uses
  uemitter;

procedure TExec.RunError(S: string);
begin
  raise Exception.Create('RunTimeError: ' + S + ' On Line: ' + IntToStr(IP));
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
  FStringList := TQuickStringList.Create;
  FCode := TList.Create;
  FFunctionList := TStringList.Create;
  FObjMgr := TObjMgr.Create;
  FMovclosureList := TList.Create;
end;

procedure TExec.CoreExec();
var
  CodeBuf, CodeBuf1: PAnsiChar;
  Ints: _TEmitInts;
  _p1, _p2, _p3, _pt: PValue;
  __p1, __p2, __p3: TValue;
  neg: Integer;
  ER, BR: Boolean;
  S: string;
  I: Integer;
  m_FuncProp: PFuncProp;
  Obj: TObj;
  procedure GetValue(var P: PAnsiChar; var Value: PValue);
  var
    I: Integer;
    m_codetype: _TEmitInts;
  begin
    Value._Type := _PEmitInts(P)^;
    m_codetype := Value._Type;
    Inc(P, SizeOf(_TEmitInts));
    case Value._Type of
      pobject, pnewobject:
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
          Inc(P, SizeOf(Integer));
          StringList.Get(Value._Int)
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
            Value._Id := FPropTable.GetFuncVarPropTable(0, -I);
          end;
        end;
      iclosure:
        begin
          I := PInteger(P)^;
          Inc(P, SizeOf(Integer));
          Value := @FCurrentUpValue[-I];
          Value._Id := FPropTable.GetFuncVarPropTable(0, -I);
        end;
      pfuncaddr:
        begin
          I := PInteger(P)^;
          Inc(P, SizeOf(Integer));
          Value._Type := pfuncaddr;
          Value._Int := I;
        end;
    end;
    Value._CodeType := m_codetype;
  end;

  procedure Str2Int(var Value: PValue);
  begin
    Value._Type := pint;
    Value._Int := StrToIntDef(StringList.Get(Value._Int), 0);
  end;

  procedure Int2Str(var Value: PValue);
  begin
    Value._Type := pstring;
    Value._Int := StringList.Add(IntToStr(Value._Int));
  end;

begin
  ER := False;
  BR := False;
  EBP := 0;
  FGc := 0;
  while IP < IPEnd do
  begin
    if FStop then Break;
    _p1 := @__p1;
    _p2 := @__p2;
    _p3 := @__p3;
    CodeBuf := Code[IP];
    Ints := _PEmitInts(CodeBuf)^;
    Inc(CodeBuf, SizeOf(_TEmitInts));
    if (CallESP > 1024) or (ESP > 1024 * 1024) then RunError('StackOverflow');
    case Ints of
      isetobjv:
        begin
          GetValue(CodeBuf, _p1); // obj
          GetValue(CodeBuf, _p2); // objvalue
          GetValue(CodeBuf, _p3); // valueto
          Obj := FObjMgr.GetAObject(_p1._Int);
          if _p2._CodeType = iident then
            Obj.AddAValue(-_p2._Int, _p3^)
          else
            Obj.AddAValue(_p2._Int, _p3^);
        end;
      igetobjv:
        begin
          GetValue(CodeBuf, _p1); // obj
          GetValue(CodeBuf, _p2); // objvalue
          GetValue(CodeBuf, _p3); // valueto
          Obj := FObjMgr.GetAObject(_p1._Int);
          if _p2._CodeType = iident then
            _pt := Obj.FindAValue(-_p2._Int)
          else
            _pt := Obj.FindAValue(_p2._Int);
          while _pt = nil do
          begin
            _pt := Obj.FindAValue(0);
            if (_pt <> nil) and (_pt._Type = pobject) and (_pt._Int > 0) then
            begin
              Obj := FObjMgr.GetAObject(_pt._Int);
              if _p2._CodeType = iident then
                _pt := Obj.FindAValue(-_p2._Int)
              else
                _pt := Obj.FindAValue(_p2._Int);
            end else
            begin
              _pt := nil;
              Break;
            end;
          end;
          if _pt <> nil then
          begin
            _p3._Value := _pt;
            _p3._Type := ivalue;
          end
          else
            // 再建立一个物体的属性表，修改下
            RunError('ObjValue ' + IntToStr(_p2._Int) +
              ' is not exist');
        end;
      inewobj:
        begin
          GetValue(CodeBuf, _p2); // copyobj
          Obj := TObj.Create(FObjMgr);
          _p2._Type := pnewobject;
          _p2._Int := Obj.Id;
        end;
      inop:
        begin
        end;
      ipush:
        begin
          GetValue(CodeBuf, _p1);
          Inc(FESP);
          FStack[FESP] := _p1^;
//          _p1^._Type := inone;
        end;
      ipop:
        begin
          GetValue(CodeBuf, _p1);
          _p1^ := FStack[FESP];
          FStack[FESP]._Type := inone;
          Dec(FESP);
        end;
      iebp:
        begin
        //closure一定有临时变量，有临时变量一定有iebp
          while FMovclosureList.Count <> 0 do
          begin
            CodeBuf1 := FMovclosureList[FMovclosureList.Count - 1];
            FMovclosureList.Delete(FMovclosureList.Count - 1);
            Inc(CodeBuf1, SizeOf(_TEmitInts));
            GetValue(CodeBuf1, _p1); // func
            GetValue(CodeBuf1, _p2); // upvalue
            GetValue(CodeBuf1, _p3); // tempvar
            m_FuncProp := FPropTable.funcproptable[_p1._Int];
            m_FuncProp.UpValue[-_p2._Int] := _p3^;
          end;
          GetValue(CodeBuf, _p1);
          Inc(EBP, _p1._Int);
        end;
      imovclosure:
        begin
          FMovclosureList.Add(Code[IP]);
        end;
      icall:
        begin
          GetValue(CodeBuf, _p1);
          if _p1._Type = inone then
          begin
            I := FFunctionList.IndexOf(_p1._Id);
            if I <> -1 then
            begin
              TFunction(FFunctionList.Objects[I])();
              Inc(FIP);
              Continue;
            end
            else
            begin
              RunError('function: "' + _p1._Id + '" is not def');
            end;
          end else
          begin
            m_FuncProp := FPropTable.funcproptable[_p1._Int];
            FCurrentUpValue := @m_FuncProp.UpValue;
            Inc(CallESP);
            Inc(EBP); //空出来放返回值的空间
            CallStack[CallESP] := IP + 1;
            IP := m_FuncProp.EntryAddr;
            Continue;
          end;
        end;
      iret:
        begin
          IP := CallStack[CallESP];
          Dec(CallESP);
          Dec(EBP);
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
            CoreRead(S);
            _p1._Int := StringList.Add(S);
          end;
        end;
      iwrite:
        begin
          GetValue(CodeBuf, _p1);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def on line:' +
              IntToStr(IP));
          if _p1._Type = ivalue then
          begin
            if not Assigned(_p1._Value) then
              RunError('do not have a ivalue');
            _P1 := _p1._Value;
          end;
          case _p1._Type of
            pint:
              CoreWrite(_p1._Int);
            pstring:
              CoreWrite(StringList.Get(_p1._Int));
          else
            CoreWrite('write param type error on line:' + IntToStr(IP));
          end;
        end;
      imov:
        begin
          GetValue(CodeBuf, _p1);
          GetValue(CodeBuf, _p2);
          if _p1._Type = inone then
            RunError('var "' + _p1._Id + '" is not def');
          if _p1._Type = ivalue then
          begin
            if not Assigned(_p1._Value) then
              RunError('do not have a ivalue');
            _P1 := _p1._Value;
          end;
          if _p2._Type = ivalue then
          begin
            if not Assigned(_p2._Value) then
              RunError('do not have a ivalue');
            _P2 := _p2._Value;
          end;
          case _p1._Type of
            pfuncaddr:
              begin
                _p2._Type := pfuncaddr;
                _p2._Int := _p1._Int;
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
              end;
            pobject:
              begin
                _p2._Type := pobject;
                _p2._Int := _p1._Int;
              end;
            pnewobject:
              begin
                _p2._Type := pobject;
                _p2._Int := _p1._Int;
                _p1._Type := inone;
                _p1._Int := _p1._Int;
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
                S := StringList.Get(_p1._Int) + StringList.Get(_p2._Int);
                _p3._Int := StringList.Add(S);
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
                if StringList.Get(_p1._Int) = StringList.Get(_p2._Int) then
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
    GarbageCollection;
  end;
end;

procedure TExec.GarbageCollection;
begin
  Mark;
  Sweep;
  Inc(FGc);
end;

function TExec.GetStack(Index: Integer): PValue;
begin
  Result := @FStack[Index]
end;

procedure TExec.Mark;
var
  I: Integer;
begin
  for I := 0 to 1024 * 1024 - 1 do
  begin
    if globlevar[I]._Type = pstring then
    begin
      CoreWrite('G_Gc' + IntToStr(FGc) + ' ');
      StringList.Mark(globlevar[I]._Int);
    end;
    if (globlevar[I]._Type = pobject) or (globlevar[I]._Type = pnewobject) then
    begin
      CoreWrite('G_Gc' + IntToStr(FGc) + ' ');
      FObjMgr.Mark(globlevar[I]._Int);
    end;
  end;

  for I := 0 to 1024 * 1024 - 1 do
  begin
    if tempvar[I]._Type = pstring then
    begin
      CoreWrite('Temp Gc' + IntToStr(FGc) + ' ');
      StringList.Mark(tempvar[I]._Int);
    end;
    if (tempvar[I]._Type = pobject) or (tempvar[I]._Type = pnewobject) then
    begin
      CoreWrite('Temp Gc' + IntToStr(FGc) + ' ');
      FObjMgr.Mark(tempvar[I]._Int);
    end;
  end;
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

procedure TExec.Sweep;
begin
  StringList.Sweep;
  FObjMgr.Sweep;
end;

function TExec.ExecuteFunc(AFuncName: string): Boolean;
var
  I: Integer;
  m_FuncProp: PFuncProp;
begin
  I := 0;
  Result := False;
  while True do
  begin
    m_FuncProp := FPropTable.funcproptable[I];
    if not Assigned(m_FuncProp) then Break;
    if LowerCase(m_FuncProp.FuncName) = LowerCase(AFuncName) then
    begin
      FCurrentUpValue := @m_FuncProp.UpValue;
      Inc(CallESP);
      Inc(EBP); //空出来放返回值的空间
      CallStack[CallESP] := IP + 1;
      FIP := m_FuncProp.EntryAddr;
      Exec;
      Result := True;
      Break;
    end;
    Inc(I);
  end;
end;

procedure TExec.SetParam(AValue: TValue);
begin
  Inc(FESP);
  FStack[FESP] := AValue;
end;

function TExec.GetResult: TValue;
begin
  Result := FStack[FESP];
  Dec(FESP);
end;

procedure TExec.SetStop(const Value: Boolean);
begin
  FStop := Value;
  FStoped := True;
end;

end.

