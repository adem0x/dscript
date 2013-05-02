unit uparser;

{ bnf
  program -> stmt-sequence
  stmt-sequence -> stmt-sequence;statement|statement
  statement -> for-stmt|if-stmt| while- stmt| assign-stmt| read-stmt| write-stmt | func-stmt | var-stmt| return-stmt
  if-stmt -> if logicexp then stmt-sequence end | if exp then stmt-sequence else stmt-sequence end
  while-stmt-> while logicexp do stmt-sequence end
  assign-stmt -> identifiers = sexp|identifiers|callfunc-stmt|object-stmt
  read-stmt-> read identifier
  write- stmt -> write logicexp
  logicexp -> sexp logicop sexp
  logicop-> <|>|=|>=|<=
  sexp-> term asop term|term
  term -> factor mdop factor|factor|callfun-stmt|func-stmt|
  factor-> (exp)|num|identifier|string
  asop-> +|-
  mdop-> *|/|%
  num->0..9
  identifier-> _identifiernum|a..zidentifiernum|A..Zidentifiernum
  identifiers-> identifier| identifier,stmt_assign
  func-stmt ->  function (identifiers | nil ) begin  stmt-sequence | nil end
  var-stmt -> var assign-stmt
  return-stmt -> return sexp
  callfunc-stmt -> (identifiers | nil)
}
interface

uses uconst, SysUtils, ulex, Classes, uemitter, uproptable;

type
  TParser = class
  private
    FEmitter: TEmitter;
    CurrentToken: Token;
    Stack: Integer;
    TempVar: Boolean;
    TempVarCount: Integer;
    AnonyMousFunc: Boolean;
    FFrontList: TList;
    FInWhileStmt: Boolean;
    FBreakList: TList;
    FContinueList: TList;
    FObjectId: Integer;
  private
    FPropTable: TPropTable;
    FLex: TLex;
    FOpt: Boolean;
    function GetNextToken(AMactch: Boolean = False): Token;
    function GetToken(): string;
    function Match(AToken: Token): Boolean;
  public
    constructor Create(AEmitter: TEmitter; APropTable: TPropTable);
    destructor Destroy; override;
    procedure parser(ASource: PAnsiChar);
    procedure ParserError(s: string);
    function Stmt_sequence: TEmitInts;
    function statement: TEmitInts;
    function stmt_if: TEmitInts;
    function stmt_while: TEmitInts;
    function stmt_break: TEmitInts;
    function stmt_continue: TEmitInts;
    function stmt_assign: TEmitInts;
    function stmt_read: TEmitInts;
    function stmt_write: TEmitInts;
    function stmt_func: TEmitInts;
    function stmt_object: TEmitInts;
    function stmt_for: TEmitInts;
    function sExp: TEmitInts;
    function logicexp: TEmitInts;
    function asop: TEmitInts;
    function mdop: TEmitInts;
    function term: TEmitInts;
    function factor: TEmitInts;
    function logicop: TEmitInts;
    function num: string;
    function sident(): string; overload;
    function sident(aIdent: string): Integer; overload;
    function sgetstring: string; overload;
    function sgetstring(s: string): Integer; overload;
    function idents(): string;
    function stmt_var: TEmitInts;
    function stmt_return: TEmitInts;
    function reversedop(AEmitInts: _TEmitInts): _TEmitInts;
    function stmt_callfunc: TEmitInts;
    procedure ToEmitter;
    property Opt: Boolean read FOpt write FOpt;
  end;

implementation

function TParser.GetToken: string;
begin
  Result := FLex.GetToken
end;

function TParser.GetNextToken(AMactch: Boolean): Token;
begin
  Result := FLex.GetNextToken(AMactch)
end;

constructor TParser.Create(AEmitter: TEmitter; APropTable: TPropTable);
begin
  if Assigned(AEmitter) and Assigned(APropTable) then
  begin
    FEmitter := AEmitter;
    FPropTable := APropTable;
  end
  else
    raise Exception.Create('AEmitter or APropTable  is nil');
  FLex := TLex.Create;
  TempVar := False;
  FFrontList := TList.Create;
end;

destructor TParser.Destroy;
begin
  FLex.Free;
  FFrontList.Free;
  inherited;
end;

procedure TParser.ParserError(s: string);
begin
  raise Exception.Create('ParseError: ' + s);
end;

function TParser.Stmt_sequence: TEmitInts;
begin
  while True do
  begin
    statement;
    if GetNextToken() = tksemicolon then
      Match(tksemicolon)
    else
      Break;
  end;
end;

function TParser.statement: TEmitInts;
begin
  CurrentToken := GetNextToken(False);
  case CurrentToken of
    tkfor:
      stmt_for;
    tkread:
      stmt_read;
    tkwrite:
      stmt_write;
    tkif:
      stmt_if;
    tkwhile:
      stmt_while;
    tkident:
      stmt_assign;
    tkvar:
      stmt_var;
    tkfunc:
      begin
        AnonyMousFunc := False;
        stmt_func;
      end;
    tkreturn:
      stmt_return;
    tkbreak:
      stmt_break;
    tkcontinue:
      stmt_continue;
    tksemicolon:
      Match(tksemicolon);
    tkhalt:
      ;
  else
    ParserError('not clear' + GetToken);
  end;
end;

function TParser.stmt_if: TEmitInts;
var
  gtoken: TEmitInts;
  _p1: TEmitInts;
  linenoifend, linenoelseend: Integer;
begin
  Match(tkif);
  gtoken := logicexp;
  Match(tkthen);
  linenoifend := FEmitter.emitnop;
  Stmt_sequence;
  if GetNextToken = tkelse then
  begin
    linenoelseend := FEmitter.emitnop;
    Match(tkelse);
    _p1.Ints := pint;
    _p1.iInstr := FEmitter.codeline - linenoifend;
    _p1.sInstr := IntToStr(_p1.iInstr);
    FEmitter.modifiycode(linenoifend, reversedop(gtoken.Ints), _p1);
    Stmt_sequence;
    gtoken.Ints := ijmp;
    _p1.iInstr := FEmitter.codeline - linenoelseend;
    _p1.sInstr := IntToStr(_p1.iInstr);
    FEmitter.modifiycode(linenoelseend, gtoken.Ints, _p1);
  end
  else
  begin
    _p1.Ints := pint;
    _p1.iInstr := FEmitter.codeline - linenoifend;
    _p1.sInstr := IntToStr(_p1.iInstr);
    FEmitter.modifiycode(linenoifend, reversedop(gtoken.Ints), _p1);
  end;
  if not Match(tkend) then
    ParserError('not ''end'' but ' + GetToken + ' find');
end;

function TParser.stmt_object: TEmitInts;
var
  m_objaddr, m_lastobjid: Integer;
  _p1, _p2, _p3: TEmitInts;
  CurrentToken: Token;
begin
  Inc(Stack);
  Match(tkleftbrace);
  Inc(FObjectId);
  FPropTable.EmitObject := True;
  m_objaddr := FPropTable.GetObjectAddr(IntToStr(FObjectId));
  m_lastobjid := FPropTable.ObjectId;
  FPropTable.ObjectId := m_objaddr;
  Result.Ints := pobject;
  Result.iInstr := m_objaddr;
  Result.sInstr := IntToStr(FObjectId);
  FEmitter.EmitCode(inewobj, Result);
  while True do
  begin
    CurrentToken := GetNextToken();
    case CurrentToken of
      tkrightbrace:
        Break;
      tksemicolon:
        Match(tksemicolon);
    else
      _p1.Ints := iident;
      _p1.sInstr := idents;
      _p1.iInstr := FPropTable.GetValueAddr(_p1.sInstr);
      Match(tkequal);
      case GetNextToken() of
        tkfunc:
          begin
            Result := stmt_func;
          end;
      else
        begin
          _p2 := sExp;
          _p3.Ints := pint;
          _p3.iInstr := m_objaddr;
          FEmitter.EmitCode(iputobjv, _p2, _p3);
        end;
      end;
    end;
  end;
  Match(tkrightbrace);
  Dec(FObjectId);
  FPropTable.EmitObject := False;
  FPropTable.ObjectId := m_objaddr;
  Dec(Stack);
end;

function TParser.stmt_while: TEmitInts;
var
  gtoken: TEmitInts;
  _p1: TEmitInts;
  lineno1, lineno2, I: Integer;
  lastbreaklist, lastcontinuelist: TList;
  // 实现while嵌套
begin
  Match(tkwhile);
  FInWhileStmt := True;
  lastcontinuelist := FContinueList;
  FContinueList := TList.Create;
  lastbreaklist := FBreakList;
  FBreakList := TList.Create;
  lineno2 := FEmitter.codeline;
  gtoken := logicexp;
  lineno1 := FEmitter.emitnop;
  Match(tkdo);
  Stmt_sequence;
  _p1.Ints := pint;
  _p1.iInstr := lineno2 - FEmitter.codeline;
  _p1.sInstr := IntToStr(_p1.iInstr);
  FEmitter.EmitCode(ijmp, _p1);
  _p1.iInstr := FEmitter.codeline - lineno1;
  _p1.sInstr := IntToStr(_p1.iInstr);
  FEmitter.modifiycode(lineno1, reversedop(gtoken.Ints), _p1);
  Match(tkend);
  for I := 0 to FContinueList.Count - 1 do
  begin
    _p1.Ints := pint;
    _p1.iInstr := lineno1 - Integer(FContinueList[I]) - 1;
    _p1.sInstr := IntToStr(_p1.iInstr);
    FEmitter.modifiycode(Integer(FContinueList[I]), ijmp, _p1);
  end;
  for I := 0 to FBreakList.Count - 1 do
  begin
    _p1.Ints := pint;
    _p1.iInstr := FEmitter.codeline - Integer(FBreakList[I]);
    _p1.sInstr := IntToStr(_p1.iInstr);
    FEmitter.modifiycode(Integer(FBreakList[I]), ijmp, _p1);
  end;
  FContinueList.Free;
  FBreakList.Free;
  FContinueList := lastcontinuelist;
  FBreakList := lastbreaklist;
end;

function TParser.stmt_assign: TEmitInts;
var
  _p2, _p3: TEmitInts;
begin
  Inc(Stack);
  Result.Ints := iident;
  Result.sInstr := idents;
  if TempVar then
  begin
    Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
    Inc(TempVarCount);
  end
  else
  begin
    Result.iInstr := FPropTable.getstackaddr(Result.sInstr);
  end;
  case GetNextToken() of
    tkequal:
      begin
        Match(tkequal);
        _p2 := sExp;
        if _p2.Ints = pobject then
        begin
          FEmitter.EmitCode(imov, _p2, Result);
        end
        else if _p2.Ints = pfunc then
        begin
          _p3.Ints := iident;
          _p3.sInstr := '1tempvar' + IntToStr(Stack);
          _p3.iInstr := -FPropTable.gettempvaraddr(_p3.sInstr);
          FEmitter.EmitCode(ipop, _p3);
          FEmitter.EmitCode(imov, _p3, Result);
        end
        else
        begin
          if _p2.Ints = pfuncaddr then
          begin
            FPropTable.funcproptable[Result.iInstr] := FPropTable.funcproptable
              [_p2.iInstr];
          end;
          FEmitter.EmitCode(imov, _p2, Result);
        end;
      end;
    tkleftpart:
      begin
        _p2 := stmt_callfunc;
        Result.Ints := pfunc;
        Result.iInstr := FPropTable.getfuncaddr(Result.sInstr);
        Result.sInstr := IntToStr(Result.iInstr);
        FEmitter.EmitCode(icall, Result);
      end;
    tksemicolon:
      Match(tksemicolon);
  else
    ParserError('unknown assign word' + GetToken);
  end;
  Dec(Stack);
end;

function TParser.stmt_break: TEmitInts;
begin
  if not FInWhileStmt then
    ParserError('not in parse while');
  Match(tkbreak);
  FBreakList.Add(Pointer(FEmitter.emitnop))
end;

function TParser.sExp: TEmitInts; // 一般表达式
var
  gtoken: TEmitInts;
  _p1, _p2, _p3: TEmitInts;
begin
  Inc(Stack);
  Result := term;
  while True do
    case GetNextToken() of
      tksubop, tkaddop:
        begin
          gtoken := asop;
          _p1 := Result;
          _p2 := term;
          if (_p1.Ints = pint) and (_p2.Ints = pint) and Opt then
          begin
            Result.Ints := pint;
            if gtoken.Ints = iadd then
              Result.iInstr := _p1.iInstr + _p2.iInstr
            else
              Result.iInstr := _p1.iInstr - _p2.iInstr;
            Result.sInstr := IntToStr(Result.iInstr)
          end
          else
          begin
            _p3.Ints := iident;
            _p3.sInstr := '1tempvar' + IntToStr(Stack);
            _p3.iInstr := -FPropTable.gettempvaraddr(_p3.sInstr);
            FEmitter.EmitCode(gtoken.Ints, _p1, _p2, _p3);
            Result := _p3;
          end;
        end;
    else
      Break;
    end;
  Dec(Stack);
end;

function TParser.logicexp: TEmitInts;
var
  _p1, _p2: TEmitInts;
begin
  Result := sExp;
  case GetNextToken() of
    tkbigop, tksmallop, tkbigequalop, tksmallequalop, tkunequal, tkequal:
      begin
        _p1 := Result;
        Result := logicop;
        Inc(Stack);
        _p2 := sExp;
        Dec(Stack);
        FEmitter.EmitCode(icmp, _p1, _p2);
      end;
  end;
end;

function TParser.logicop: TEmitInts;
begin
  CurrentToken := GetNextToken(False);
  case CurrentToken of
    tkbigop:
      begin
        Match(tkbigop);
        Result.Ints := ijb;
        Result.sInstr := FEmitter.Ints2str(Result.Ints);
      end;
    tksmallop:
      begin
        Match(tksmallop);
        Result.Ints := ijs;
        Result.sInstr := FEmitter.Ints2str(Result.Ints);
      end;
    tkbigequalop:
      begin
        Match(tkbigequalop);
        Result.Ints := ijbe;
        Result.sInstr := FEmitter.Ints2str(Result.Ints);
      end;
    tksmallequalop:
      begin
        Match(tksmallequalop);
        Result.Ints := ijse;
        Result.sInstr := FEmitter.Ints2str(Result.Ints);
      end;
    tkequal:
      begin
        Match(tkequal);
        Result.Ints := ije;
        Result.sInstr := FEmitter.Ints2str(Result.Ints);
      end;
    tkunequal:
      begin
        Match(tkunequal);
        Result.Ints := ijne;
        Result.sInstr := FEmitter.Ints2str(Result.Ints);
      end;
  end;
end;

function TParser.Match(AToken: Token): Boolean;
begin
  Result := FLex.Match(AToken)
end;

function TParser.asop: TEmitInts;
begin
  case GetNextToken of
    tksubop:
      begin
        Match(tksubop);
        Result.Ints := isub;
        Result.sInstr := FEmitter.Ints2str(isub);
      end;
    tkaddop:
      begin
        Match(tkaddop);
        Result.Ints := iadd;
        Result.sInstr := FEmitter.Ints2str(iadd);
      end;
  end;
end;

function TParser.mdop: TEmitInts;
begin
  case GetNextToken of
    tkmulop:
      begin
        Match(tkmulop);
        Result.Ints := imul;
        Result.sInstr := FEmitter.Ints2str(imul);
      end;
    tkdivop:
      begin
        Match(tkdivop);
        Result.Ints := idiv;
        Result.sInstr := FEmitter.Ints2str(idiv);
      end;
    tkmodop:
      begin
        Match(tkmodop);
        Result.Ints := imod;
        Result.sInstr := FEmitter.Ints2str(imod);
      end;
  end;
end;

function TParser.term: TEmitInts;
var
  gtoken: TEmitInts;
  _p1, _p2, _p3: TEmitInts;
begin
  Inc(Stack);
  Result := factor;
  while True do
    case GetNextToken() of
      tkmulop, tkdivop, tkmodop:
        begin
          gtoken := mdop;
          _p1 := Result;
          _p2 := factor;
          if (_p1.Ints = pint) and (_p2.Ints = pint) and Opt then
          begin
            Result.Ints := pint;
            case gtoken.Ints of
              imul:
                Result.iInstr := _p1.iInstr * _p2.iInstr;
              idiv:
                Result.iInstr := _p1.iInstr div _p2.iInstr;
              imod:
                Result.iInstr := _p1.iInstr mod _p2.iInstr;
            end;
            Result.sInstr := IntToStr(Result.iInstr)
          end
          else
          begin
            _p3.Ints := iident;
            _p3.sInstr := '1tempvar' + IntToStr(Stack);
            _p3.iInstr := -FPropTable.gettempvaraddr(_p3.sInstr);
            FEmitter.EmitCode(gtoken.Ints, _p1, _p2, _p3);
            Result := _p3;
          end;
        end;
      tkleftpart:
        begin
          stmt_callfunc;
          Result.Ints := pfunc;
          Result.iInstr := FPropTable.FindAddr(Result.sInstr);
          if Result.iInstr = 0 then
            Result.iInstr := FPropTable.getfuncaddr(Result.sInstr);
          Result.sInstr := IntToStr(Result.iInstr);
          FEmitter.EmitCode(icall, Result);
          Result.Ints := iident;
          Result.sInstr := '1tempvar' + IntToStr(Stack);
          Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
          FEmitter.EmitCode(ipop, Result);
        end;
      tkfunc:
        begin
          AnonyMousFunc := True;
          Result := stmt_func;
        end;
      tkleftbrace:
        begin
          Result := stmt_object;
        end;
    else
      Break;
    end;
  Dec(Stack);
end;

procedure TParser.ToEmitter;
begin
  FEmitter.ToExec;
end;

function TParser.factor: TEmitInts;
begin
  Inc(Stack);
  CurrentToken := GetNextToken();
  case CurrentToken of
    tkstring:
      begin
        Result.Ints := pstring;
        Result.sInstr := sgetstring;
        Result.iInstr := sgetstring(Result.sInstr);
      end;
    tknum:
      begin
        Result.Ints := pint;
        Result.sInstr := num;
        Result.iInstr := StrToInt(Result.sInstr);
      end;
    tkident:
      begin
        Result.Ints := iident;
        Result.sInstr := sident;
        Result.iInstr := sident(Result.sInstr);
        // if Result.iInstr > 0 then
        // if FPropTable.vartypeproptable[Result.iInstr] <> inone then
        // Result.Ints := FPropTable.vartypeproptable[Result.iInstr]
      end;
    tkleftpart:
      begin
        Match(tkleftpart);
        Result := sExp;
        Match(tkrightpart);
      end;
  end;
  Dec(Stack);
end;

function TParser.num: string;
begin
  Match(tknum);
  Result := GetToken;
end;

function TParser.sident: string;
begin
  Match(tkident);
  Result := GetToken;
end;

function TParser.sident(aIdent: string): Integer;
begin
  Result := FPropTable.FindAddr(aIdent);
  if Result = 0 then
    Result := FPropTable.getstackaddr(aIdent);
end;

function TParser.sgetstring: string;
begin
  Match(tkstring);
  Result := GetToken;
end;

function TParser.sgetstring(s: string): Integer;
begin
  Result := FPropTable.getstraddr(s);
end;

function TParser.stmt_read: TEmitInts;
var
  _p1: TEmitInts;
begin
  Match(tkread);
  Match(tkident);
  _p1.Ints := iident;
  _p1.sInstr := GetToken;
  _p1.iInstr := FPropTable.getstackaddr(_p1.sInstr);
  FEmitter.EmitCode(iread, _p1);
end;

function TParser.stmt_write: TEmitInts;
var
  _p1: TEmitInts;
begin
  Inc(Stack);
  Match(tkwrite);
  _p1 := sExp;
  FEmitter.EmitCode(iwrite, _p1);
  Dec(Stack);
end;

function TParser.stmt_for: TEmitInts;
var
  _p1, _p2, _p3, _p4, _p5: TEmitInts;
  LineNo: Integer;
begin
  Match(tkfor);
  _p1.Ints := iident;
  _p1.sInstr := sident;
  _p1.iInstr := -FPropTable.gettempvaraddr(_p1.sInstr);
  Match(tkequal);
  _p2 := sExp;
  Match(tkcomma);
  _p3 := sExp;
  if GetNextToken() = tkcomma then
  begin
    Match(tkcomma);
    _p4 := sExp
  end
  else
  begin
    _p4.Ints := pint;
    _p4.iInstr := 1;
  end;
  FEmitter.EmitCode(imov, _p2, _p1);
  FEmitter.EmitCode(icmp, _p1, _p3);
  LineNo := FEmitter.emitnop;
  Match(tkdo);
  while GetNextToken() <> tkend do
    Stmt_sequence;
  FEmitter.EmitCode(iadd, _p1, _p4, _p1);
  _p5.Ints := pint;
  _p5.iInstr := -(FEmitter.codeline - LineNo + 1);
  FEmitter.EmitCode(ijmp, _p5);
  _p5.Ints := pint;
  _p5.iInstr := FEmitter.codeline - LineNo;
  FEmitter.modifiycode(LineNo, ijbe, _p5);
  Match(tkend);
end;

function TParser.stmt_func: TEmitInts;
var
  CurrentCodeLine, I: Integer;
  _p1: TEmitInts;
  LineNo, lineno2: Integer;
  m_FuncProp: PFuncProp;
begin
  if FPropTable.EmitFunc then
    ParserError('do not support nest func');
  FFrontList.Clear;
  FPropTable.ClearTempVar;
  TempVarCount := 0;
  Inc(Stack);
  FPropTable.EmitFunc := True;
  CurrentCodeLine := FEmitter.codeline;
  FEmitter.codeline := FEmitter.funccodeline;
  LineNo := FEmitter.emitnop();
  Match(tkfunc);
  if not AnonyMousFunc then
  begin
    Match(tkident);
    FPropTable.FuncName := GetToken;
    I := FPropTable.getfuncaddr(FPropTable.FuncName, FEmitter.codeline);
    Result.Ints := pfunc;
    Result.sInstr := FPropTable.FuncName;
    Result.iInstr := I;
  end
  else
  begin
    FPropTable.FuncName := '1AnonyMousFunc' + IntToStr(Stack);
    I := FPropTable.getfuncaddr(FPropTable.FuncName, FEmitter.codeline);
    Result.Ints := pfuncaddr;
    Result.sInstr := FPropTable.FuncName;
    Result.iInstr := I;
  end;
  Match(tkleftpart);
  while True do
  begin
    case GetNextToken() of
      tkrightpart:
        Break;
      tkident:
        begin
          _p1.Ints := iident;
          _p1.sInstr := sident;
          _p1.iInstr := -FPropTable.gettempvaraddr(_p1.sInstr);
          FEmitter.EmitCode(ipop, _p1);
        end;
      tkcomma:
        Match(tkcomma);
    end;
  end;
  Match(tkrightpart);
//  Match(tkbegin);
  if GetNextToken() <> tkend then
    Stmt_sequence;
  Match(tkend);
  for I := 0 to FFrontList.Count - 1 do
  begin
    lineno2 := Integer(FFrontList[I]);
    _p1.Ints := pint;
    _p1.iInstr := FEmitter.codeline - lineno2;
    FEmitter.modifiycode(lineno2, ijmp, _p1);
  end;
  FFrontList.Clear;
  if TempVarCount = 0 then
  begin
    // 删除1条指令，入口地址要修改
    FEmitter.DeleteCode(LineNo);
    I := FPropTable.getfuncaddr(FPropTable.FuncName);
    m_FuncProp := FPropTable.funcproptable[I];
    Dec(m_FuncProp.EntryAddr)
  end
  else
  begin
    _p1.Ints := pint;
    _p1.iInstr := TempVarCount;
    FEmitter.modifiycode(LineNo, iebp, _p1);

    _p1.Ints := pint;
    _p1.iInstr := -TempVarCount;
    FEmitter.EmitCode(iebp, _p1);
  end;
  FEmitter.EmitCode(iret);
  FEmitter.funccodeline := FEmitter.codeline - CurrentCodeLine;
  FEmitter.codeline := CurrentCodeLine;
  FPropTable.EmitFunc := False;
  FPropTable.FuncName := '';
  Dec(Stack);
end;

function TParser.stmt_callfunc: TEmitInts;
var
  PushList: array [0 .. 100] of TEmitInts;
  PushI, I: Integer;
begin
  Inc(Stack);
  Match(tkleftpart);
  PushI := 0;
  while True do
  begin
    case GetNextToken() of
      tkrightpart:
        Break;
      tknum:
        begin
          Result.Ints := pint;
          Result.sInstr := num;
          Result.iInstr := StrToInt(Result.sInstr);
          PushList[PushI] := Result;
          Inc(PushI);
        end;
      tkstring:
        begin
          Result.Ints := pstring;
          Result.sInstr := sgetstring;
          Result.iInstr := FPropTable.FindAddr(Result.sInstr);
          PushList[PushI] := Result;
          Inc(PushI);
        end;
      tkident:
        begin
          Result.Ints := iident;
          Result.sInstr := sident;
          Result.iInstr := FPropTable.getstackaddr(Result.sInstr);
          PushList[PushI] := Result;
          Inc(PushI);
        end;
      tkcomma:
        Match(tkcomma);
      tkleftpart:
        begin
          stmt_callfunc;
          Result.Ints := pfunc;
          Result.iInstr := FPropTable.FindAddr(Result.sInstr);
          if Result.iInstr = 0 then
            Result.iInstr := FPropTable.getfuncaddr(Result.sInstr);
          Result.sInstr := IntToStr(Result.iInstr);
          FEmitter.EmitCode(icall, Result);
          Result.Ints := iident;
          Result.sInstr := '1tempvar' + IntToStr(Stack);
          Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
          FEmitter.EmitCode(ipop, Result);
          if PushI <> 1 then
            ParserError('PushI Error');
          PushList[0] := Result;
        end;
    end;
  end;
  for I := PushI - 1 downto 0 do
    FEmitter.EmitCode(ipush, PushList[I]);
  Match(tkrightpart);
  Dec(Stack);
end;

function TParser.stmt_continue: TEmitInts;
begin
  if not FInWhileStmt then
    ParserError('not in parse while');
  Match(tkcontinue);
  FContinueList.Add(Pointer(FEmitter.emitnop))
end;

function TParser.idents(): string;
begin
  Match(tkident);
  Result := GetToken;
  if GetNextToken() = tkcomma then
  begin
    Match(tkcomma);
    stmt_assign;
  end;
end;

function TParser.stmt_var: TEmitInts;
begin
  if not FPropTable.EmitFunc then
    ParserError('var must be def in function');
  Match(tkvar);
  TempVar := True;
  stmt_assign;
  TempVar := False;
end;

function TParser.stmt_return: TEmitInts;
begin
  if not FPropTable.EmitFunc then
    ParserError('return must be def in function');
  Match(tkreturn);
  Result := sExp;
  FEmitter.EmitCode(ipush, Result);
  FFrontList.Add(Pointer(FEmitter.emitnop()));
  // FEmitter.EmitCode(iret);
end;

procedure TParser.parser(ASource: PAnsiChar);
begin
  if ASource = nil then
    Exit;
  FLex.Source := ASource;
  while True do
  begin
    if GetNextToken() = tkhalt then
    begin
      FEmitter.EmitCode(ihalt);
      Break;
    end;
    Stmt_sequence;
  end;
  ToEmitter;
end;

function TParser.reversedop(AEmitInts: _TEmitInts): _TEmitInts;
begin
  case AEmitInts of
    ijse:
      begin
        Result := ijb;
      end;
    ijbe:
      begin
        Result := ijs;
      end;
    ijs:
      begin
        Result := ijbe;
      end;
    ijb:
      begin
        Result := ijse;
      end;
    ijne:
      begin
        Result := ije;
      end;
    ije:
      begin
        Result := ijne;
      end;
  else
    Result := ijmp;
    ParserError('unhoped reversedop');
  end;
end;

end.
