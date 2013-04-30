unit uemitter;

interface

uses
  uconst, SysUtils, ulex, Classes, uexec, uproptable;

type
  TEmitter = class
    StrList, VarnameList, TempVarnameList, FuncnameList, FuncParamnameList
      : TStringList;
    EmitCoder, EmitFunCoder: TList;
    CodeLine: integer;
    FuncCodeLine: integer;
    EmitFunc: boolean;
    FuncName: string;
    FExec: TExec;
    FPropTable: TPropTable;
    m: TMemoryStream;
    procedure ClearFuncParamAddr;
    function FindAddr(varname: string): integer;
    function FuncParamAddr(varname: string): integer;
    function GetFuncStackAddr(varname: string): integer;
    function GetStackAddr(varname: string): integer;
    function GetStrAddr(strname: string): integer;
    function GetTempVarAddr(varname: string): integer;
    procedure ClearTempVar;
    function EmitNop(): integer;
    function DeleteCode(ALine :Integer): Boolean;
    procedure ModifiyCode(ALine: integer; atoken: _TEmitInts; _p1: TEmitInts);
    procedure EmitCode(atoken: _TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1, _p2: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1, _p2, _p3: TEmitInts;
      LineNo: integer = -1; IsFunc: boolean = False); overload;
    function Ints2str(aInts: _TEmitInts): string;
    function str2Ints(aInts: string): _TEmitInts;
    procedure ToExec;
    constructor Create(AExec: TExec; APropTable: TPropTable);
  end;

var
  EmitInts: TEmitInts;

implementation

uses
  uparser;

function TEmitter.GetStrAddr(strname: string): integer;
begin
  Result := StrList.IndexOf(strname);
  if Result = -1 then
  begin
    StrList.Add(strname);
    Result := StrList.IndexOf(strname);
    FPropTable.varproptable[Result] := strname;
  end;
end;

function TEmitter.GetFuncStackAddr(varname: string): integer;
begin
  if varname = '' then
  begin
    Result := 0;
    Exit;
  end;
  Result := FuncnameList.IndexOf(varname);
  if Result = -1 then
  begin
    FuncnameList.Add(varname);
    Result := FuncnameList.IndexOf(varname);
  end;
end;

function TEmitter.FuncParamAddr(varname: string): integer;
begin
  Result := FuncParamnameList.IndexOf(varname);
  if Result = -1 then
  begin
    FuncParamnameList.Add(varname);
    Result := FuncParamnameList.IndexOf(varname);
  end;
end;

procedure TEmitter.ClearFuncParamAddr;
begin
  FuncParamnameList.Clear;
  FuncParamnameList.Add('999888t');
end;

function TEmitter.GetStackAddr(varname: string): integer;
begin
  Result := FuncParamnameList.IndexOf(varname);
  if Result = -1 then
    Result := FuncnameList.IndexOf(varname);
  if Result = -1 then
  begin
    Result := VarnameList.IndexOf(varname);
    if Result = -1 then
    begin
      VarnameList.Add(varname);
      Result := VarnameList.IndexOf(varname);
      FPropTable.varproptable[Result] := varname;
    end;
  end
  else
    Result := -Result;
end;

function TEmitter.FindAddr(varname: string): integer;
begin
  Result := TempVarnameList.IndexOf(varname);
  if Result = -1 then
    Result := FuncParamnameList.IndexOf(varname);
  if Result = -1 then
  begin
    Result := VarnameList.IndexOf(varname);
    if Result = -1 then
      Result := 0;
  end
  else
    Result := -Result;
end;

function TEmitter.GetTempVarAddr(varname: string): integer;
begin
  Result := TempVarnameList.IndexOf(varname);
  if Result = -1 then
  begin
    TempVarnameList.Add(varname);
    Result := TempVarnameList.IndexOf(varname);
  end;
end;

function TEmitter.Ints2str(aInts: _TEmitInts): string;
begin
  if aInts in [iread .. itheend] then
    Result := PrintInts[aInts];
end;

function TEmitter.str2Ints(aInts: string): _TEmitInts;
var
  I: _TEmitInts;
begin
  Result := inone;
  for I := Low(_TEmitInts) to High(_TEmitInts) do
  begin
    if PrintInts[I] = aInts then
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TEmitter.ToExec;
var
  I: integer;
begin
  FExec.Code.Clear;
  for I := 0 to EmitFunCoder.Count - 1 do
    FExec.Code.Add(EmitFunCoder[I]);
  for I := 0 to EmitCoder.Count - 1 do
    FExec.Code.Add(EmitCoder[I]);
  if Assigned(StrList) then
    FExec.StringList.AddStrings(StrList);
  FExec.IP := EmitFunCoder.Count;
  FExec.IPEnd := FExec.Code.Count;
  EmitFunCoder.Clear;
  EmitCoder.Clear;
  StrList.Clear;
  VarnameList.Clear;
  TempVarnameList.Clear;
  FuncnameList.Clear;
  FuncParamnameList.Clear;
end;

function TEmitter.EmitNop(): integer;
begin
  if not Assigned(EmitCoder) then
    EmitCoder := TList.Create;
  if not Assigned(EmitFunCoder) then
    EmitFunCoder := TList.Create;
  Result := CodeLine;
  if not EmitFunc then
  begin
    EmitCode(inop);
//    EmitCoder.Add(nil);
  end
  else
  begin
    EmitCode(inop);
//    EmitFunCoder.Add(nil);
  end;

//  Inc(CodeLine);
end;

procedure TEmitter.ModifiyCode(ALine: integer; atoken: _TEmitInts;
  _p1: TEmitInts);
var
  Param: TEmitInts;
  P: Pointer;
begin
  Param.Ints := inone;
  if not EmitFunc then
  begin
    P := EmitCoder[ALine];
    FreeMem(P);
    EmitCoder.Delete(ALine);
  end else
  begin
    P := EmitFunCoder[ALine];
    FreeMem(P);
    EmitFunCoder.Delete(ALine);
  end;
  Dec(CodeLine);
  EmitCode(atoken, _p1, Param, Param, ALine);
end;

procedure TEmitter.ClearTempVar;
begin
  TempVarnameList.Clear;
  TempVarnameList.Add('999888t');
end;

constructor TEmitter.Create(AExec: TExec; APropTable: TPropTable);
begin
  FExec := AExec;
  FPropTable := APropTable;
  m := TMemoryStream.Create;

  VarnameList := TStringList.Create;
  VarnameList.Add('999888t');
  TempVarnameList := TStringList.Create;
  TempVarnameList.Add('999888t');
  FuncnameList := TStringList.Create;
  FuncnameList.Add('999888t');
  StrList := TStringList.Create;
  StrList.Add('999888t');
  FuncParamnameList := TStringList.Create;
  FuncParamnameList.Add('999888t');
end;

function TEmitter.DeleteCode(ALine: Integer): Boolean;
begin
  Result := True;
  if not EmitFunc then
  begin
    if ALine < EmitCoder.Count then
    begin
      FreeMem(EmitCoder[ALine]);
      EmitCoder.Delete(ALine);
    end;
  end
  else
  begin
    if ALine < EmitFunCoder.Count then
    begin
      FreeMem(EmitFunCoder[ALine]);
      EmitFunCoder.Delete(ALine);
    end;
  end;
  Dec(CodeLine);
end;

procedure TEmitter.EmitCode(atoken: _TEmitInts; _p1, _p2, _p3: TEmitInts;
  LineNo: integer; IsFunc: boolean);

  procedure emitparam(var _p: TEmitInts);
  var
    P: _TEmitInts;
  begin
    if _p.Ints <> inone then
    begin
      case _p.Ints of
        ptrue:
          begin
            P := pboolean;
            m.Write(P, 1);
          end;
        pfalse:
          begin
            P := pboolean;
            m.Write(P, 1);
          end;
        pint, pfunc:
          begin
            m.Write(_p.Ints, 1);
            m.Write(_p.iInstr, SizeOf(integer));
{$IFDEF emit}
            Write(_p.iInstr, ' ');
{$ENDIF}
          end;
        pstring:
          begin
            m.Write(_p.Ints, 1);
            m.Write(_p.iInstr, SizeOf(integer));
{$IFDEF emit} Write(_p.sInstr, ' '); {$ENDIF}
          end;
        iident:
          begin
            m.Write(_p.Ints, 1);
            m.Write(_p.iInstr, SizeOf(integer));
{$IFDEF emit} Write(_p.sInstr, '(', _p.iInstr, ')', ' '); {$ENDIF}
          end;
        pfuncaddr:
        begin
            m.Write(_p.Ints, 1);
            m.Write(_p.iInstr, SizeOf(integer));
{$IFDEF emit} Write(_p.sInstr, '(', _p.iInstr, ')', ' '); {$ENDIF}
        end
      else
        Write('emitparam error')
        // pfunc:
        // begin
        // m.Write(_p.Ints, 1);
        // _p.iInstr := StrToInt(funcproptable[_p.iInstr]);
        // m.Write(_p.iInstr, SizeOf(Integer));
        // {$IFDEF emit}Write(_p.sInstr, ' ');{$ENDIF}
        // end;
      end;
    end;
  end;

var
  buf: PAnsiChar;
begin
{$IFDEF emit}
  if LineNo = -1 then
    Write(CodeLine, ': ', Ints2str(atoken), ' ')
  else
    Write(LineNo, ': ', Ints2str(atoken), ' ');
{$ENDIF}
  if not Assigned(EmitCoder) then
    EmitCoder := TList.Create;
  if not Assigned(EmitFunCoder) then
    EmitFunCoder := TList.Create;
  m.Clear;
  m.Write(atoken, SizeOf(_TEmitInts));
  emitparam(_p1);
  emitparam(_p2);
  emitparam(_p3);
  Writeln;
  GetMem(buf, m.Size);
  Move(m.Memory^, buf^, m.Size);
  if not EmitFunc then
  begin
    if LineNo = -1 then
      EmitCoder.Add(buf)
    else
      EmitCoder.Insert(LineNo, buf);
  end
  else
  begin
    if LineNo = -1 then
      EmitFunCoder.Add(buf)
    else
      EmitFunCoder.Insert(LineNo, buf);
  end;
  Inc(CodeLine);
end;

procedure TEmitter.EmitCode(atoken: _TEmitInts);
var
  Param: TEmitInts;
begin
  Param.Ints := inone;
  EmitCode(atoken, Param, Param, Param);
end;

procedure TEmitter.EmitCode(atoken: _TEmitInts; _p1: TEmitInts);
var
  Param: TEmitInts;
begin
  Param.Ints := inone;
  EmitCode(atoken, _p1, Param, Param);
end;

procedure TEmitter.EmitCode(atoken: _TEmitInts; _p1, _p2: TEmitInts);
var
  Param: TEmitInts;
begin
  Param.Ints := inone;
  EmitCode(atoken, _p1, _p2, Param);
end;

end.
