unit uEmitter;

interface

uses
  uconst, SysUtils, ulex, Classes, uexec, uproptable, uEmitFuncMgr;

type
  TEmitter = class
  private
    function GetEmitFuncState: Boolean;
  public
    FuncCodeLine: integer;
    FExec: TExec;
    FPropTable: TPropTable;
    m: TMemoryStream;
    EmitFuncMgr: TEmitFuncMgr;
    function EmitNop(): integer;
    function DeleteCode(ALine: integer): Boolean;
    procedure ModifiyCode(ALine: integer; atoken: _TEmitInts;
      _p1: TEmitInts); overload;
    procedure ModifiyCode(ALine: integer; atoken: _TEmitInts;
      _p1, _p2: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1, _p2: TEmitInts); overload;
    procedure EmitCode(atoken: _TEmitInts; _p1, _p2, _p3: TEmitInts;
      LineNo: integer = -1; IsFunc: Boolean = False); overload;
    function Ints2str(aInts: _TEmitInts): string;
    function str2Ints(aInts: string): _TEmitInts;
    procedure ToExec;
    constructor Create(AExec: TExec; APropTable: TPropTable);
    function GetCodeLine: Integer;
    property CodeLine:Integer  read GetCodeLine;
    property EmitFunc: Boolean  read GetEmitFuncState;
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
  FExec.IP := EmitFuncMgr.SaveCodeToList(FExec.Code);
  FExec.IPEnd := FExec.Code.Count;
  if Assigned(FPropTable.StrList) then
    FExec.StringList.AddStrings(FPropTable.StrList);
end;

function TEmitter.EmitNop(): integer;
begin
  Result := EmitFuncMgr.CurrentFunc.CodeLineCount;
  EmitCode(inop);
end;

procedure TEmitter.ModifiyCode(ALine: integer; atoken: _TEmitInts;
  _p1, _p2: TEmitInts);
var
  Param: TEmitInts;
  P: Pointer;
begin
  Param.Ints := inone;
  EmitCode(atoken, _p1, _p2, Param, ALine);
end;

procedure TEmitter.ModifiyCode(ALine: integer; atoken: _TEmitInts;
  _p1: TEmitInts);
var
  Param: TEmitInts;
  P: Pointer;
begin
  Param.Ints := inone;
  EmitCode(atoken, _p1, Param, Param, ALine);
end;

constructor TEmitter.Create(AExec: TExec; APropTable: TPropTable);
begin
  FExec := AExec;
  FPropTable := APropTable;
  m := TMemoryStream.Create;
  EmitFuncMgr := TEmitFuncMgr.Create(FPropTable);
end;

function TEmitter.DeleteCode(ALine: integer): Boolean;
begin
  Result := EmitFuncMgr.DeleteCode(ALine);
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
            if _p.Ints = pfunc then
            Write('(func)',_p.iInstr, ' ')
            else
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
{$IFDEF emit} Write('(funcaddr)', _p.sInstr, '(', _p.iInstr, ')', ' '); {$ENDIF}
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
  m.Clear;
  m.Write(atoken, SizeOf(_TEmitInts));
  emitparam(_p1);
  emitparam(_p2);
  emitparam(_p3);
  Writeln;
  GetMem(buf, m.Size);
  Move(m.Memory^, buf^, m.Size);
  if LineNo = -1 then
    EmitFuncMgr.AddACode(buf)
  else
    EmitFuncMgr.ModifiyCode(LineNo, buf)
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

function TEmitter.GetCodeLine: Integer;
begin
  Result := EmitFuncMgr.CurrentFunc.CodeLineCount;
end;

function TEmitter.GetEmitFuncState: Boolean;
begin
  Result := EmitFuncMgr.CurrentFunc.FuncName <> '1Main'
end;

end.
