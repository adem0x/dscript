unit uemitter;

interface

uses
  uconst, SysUtils, ulex, Classes, uexec, uproptable;

type
  TEmitter = class

    EmitCoder, EmitFunCoder: TList;
    CodeLine: integer;
    FuncCodeLine: integer;
    FExec: TExec;
    FPropTable: TPropTable;
    m: TMemoryStream;

    function EmitNop(): integer;
    function DeleteCode(ALine: integer): Boolean;
    procedure ModifiyCode(ALine: integer; atoken: _TEmitInts; _p1: TEmitInts); overload;
    procedure ModifiyCode(ALine: integer; atoken: _TEmitInts; _p1, _p2: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1, _p2: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1, _p2, _p3: TEmitInts;
      LineNo: integer = -1; IsFunc: Boolean = False); overload;
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

function TEmitter.Ints2str(aInts: _TEmitInts): string;
begin
  if aInts in [iread .. itheend] then
    Result := PrintInts[aInts];
end;

procedure TEmitter.ModifiyCode(ALine: integer; atoken: _TEmitInts; _p1,
  _p2: TEmitInts);
var
  Param: TEmitInts;
  P: Pointer;
begin
  Param.Ints := inone;
  if not FPropTable.EmitFunc then
  begin
    P := EmitCoder[ALine];
    FreeMem(P);
    EmitCoder.Delete(ALine);
  end
  else
  begin
    P := EmitFunCoder[ALine];
    FreeMem(P);
    EmitFunCoder.Delete(ALine);
  end;
  Dec(CodeLine);
  EmitCode(atoken, _p1, _p2
  , Param, ALine);
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
  if Assigned(FPropTable.StrList) then
    FExec.StringList.AddStrings(FPropTable.StrList);
  FExec.IP := EmitFunCoder.Count;
  FExec.IPEnd := FExec.Code.Count;
  EmitFunCoder.Clear;
  EmitCoder.Clear;
  // FPropTable.StrList.Clear;
  // FPropTable.VarnameList.Clear;
  // FPropTable.TempVarnameList.Clear;
  // FPropTable.FuncnameList.Clear;
  // FPropTable.FuncParamnameList.Clear;
end;

function TEmitter.EmitNop(): integer;
begin
  if not Assigned(EmitCoder) then
    EmitCoder := TList.Create;
  if not Assigned(EmitFunCoder) then
    EmitFunCoder := TList.Create;
  Result := CodeLine;
  if not FPropTable.EmitFunc then
  begin
    EmitCode(inop);
    // EmitCoder.Add(nil);
  end
  else
  begin
    EmitCode(inop);
    // EmitFunCoder.Add(nil);
  end;

  // Inc(CodeLine);
end;

procedure TEmitter.ModifiyCode(ALine: integer; atoken: _TEmitInts;
  _p1: TEmitInts);
var
  Param: TEmitInts;
  P: Pointer;
begin
  Param.Ints := inone;
  if not FPropTable.EmitFunc then
  begin
    P := EmitCoder[ALine];
    FreeMem(P);
    EmitCoder.Delete(ALine);
  end
  else
  begin
    P := EmitFunCoder[ALine];
    FreeMem(P);
    EmitFunCoder.Delete(ALine);
  end;
  Dec(CodeLine);
  EmitCode(atoken, _p1, Param, Param, ALine);
end;

constructor TEmitter.Create(AExec: TExec; APropTable: TPropTable);
begin
  FExec := AExec;
  FPropTable := APropTable;
  m := TMemoryStream.Create;
end;

function TEmitter.DeleteCode(ALine: integer): Boolean;
begin
  Result := True;
  if not FPropTable.EmitFunc then
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
  LineNo: integer; IsFunc: Boolean);

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
{$IFDEF emit} Write('''', _p.sInstr, ''' '); {$ENDIF}
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
          end;
        pobject:
          begin
            m.Write(_p.Ints, 1);
            m.Write(_p.iInstr, SizeOf(integer));
{$IFDEF emit} Write(_p.sInstr, '(', _p.iInstr, ')', ' '); {$ENDIF}
          end;
        ivalue:
          begin
            m.Write(_p.Ints, 1);
            m.Write(_p.iInstr, SizeOf(integer));
{$IFDEF emit} Write(_p.sInstr, '(', _p.iInstr, ')', ' '); {$ENDIF}
          end;
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
  if not FPropTable.EmitFunc then
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
