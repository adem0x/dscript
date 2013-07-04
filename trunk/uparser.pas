unit uParser;

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

uses uconst, SysUtils, ulex, Classes, uemitter, uproptable,Contnrs;

type
  TParser = class
  private
    FEmitter: TEmitter;
    CurrentToken: Token;
    Stack: Integer;
    TempVar: Boolean;
    FFrontList: TList;
    FFrontListStack: TStack;
    FInWhileStmt: Boolean;
    FBreakList: TList;
    FContinueList: TList;
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
    function stmt_if(AInts: PEmitInts = nil): TEmitInts;
    function stmt_while(AInts: PEmitInts = nil): TEmitInts;
    function stmt_break(AInts: PEmitInts = nil): TEmitInts;
    function stmt_continue(AInts: PEmitInts = nil): TEmitInts;
    function stmt_assign(AInts: PEmitInts = nil): TEmitInts;
    function stmt_read(AInts: PEmitInts = nil): TEmitInts;
    function stmt_write(AInts: PEmitInts = nil): TEmitInts;
    function stmt_func(AInts: PEmitInts = nil): TEmitInts;
    function stmt_object(AInts: PEmitInts = nil): TEmitInts;
    function stmt_for(AInts: PEmitInts = nil): TEmitInts;
    function sExp(AInts: PEmitInts = nil): TEmitInts;
    function logicexp(AInts: PEmitInts = nil): TEmitInts;
    function asop(AInts: PEmitInts = nil): TEmitInts;
    function mdop(AInts: PEmitInts = nil): TEmitInts;
    function term(AInts: PEmitInts = nil): TEmitInts;
    function factor(AInts: PEmitInts = nil): TEmitInts;
    function logicop(AInts: PEmitInts = nil): TEmitInts;
    function num: string;
    function sident(): string; overload;
    function sident(aIdent: string): Integer; overload;
    function sgetstring: string; overload;
    function sgetstring(s: string): Integer; overload;
    function idents(): string;
    function stmt_var(AInts: PEmitInts = nil): TEmitInts;
    function stmt_return(AInts: PEmitInts = nil): TEmitInts;
    function reversedop(AEmitInts: _TEmitInts): _TEmitInts;
    function stmt_callfunc(AInts: PEmitInts = nil): TEmitInts;
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
  FFrontListStack := TStack.Create;
end;

destructor TParser.Destroy;
begin
  FLex.Free;
  FFrontListStack.Free;
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
      stmt_func;
    tkreturn:
      stmt_return;
    tkbreak:
      stmt_break;
    tkcontinue:
      stmt_continue;
    tksemicolon:
      Match(tksemicolon);
    tkhalt, tkend:
      ;
  else
    ParserError('not clear' + GetToken);
  end;
end;

function TParser.stmt_if(AInts: PEmitInts): TEmitInts;
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

function TParser.stmt_object(AInts: PEmitInts): TEmitInts;
var
  m_objaddr, m_lastobjid: Integer;
  _p1, _p2, _p3, _p4: TEmitInts;
  CurrentToken: Token;
begin
  Inc(Stack);
  Match(tkleftbrace);
  Result.Ints := pobject;
  Result.iInstr := FPropTable.GetStackAddr(AInts.sInstr);
  Result.sInstr := AInts.sInstr;
  FPropTable.EmitObject := True;
  _p4.Ints := iident;
  _p4.sInstr := '1tempvar' + IntToStr(Stack);
  _p4.iInstr := -FPropTable.gettempvaraddr(_p3.sInstr);
  FEmitter.EmitCode(inewobj, _p4);
  while True do
  begin
    CurrentToken := GetNextToken();
    case CurrentToken of
      tkrightbrace:
        Break;
      tksemicolon:
        Match(tksemicolon);
    else
      _p1.Ints := ivalue;
      _p1.sInstr := idents;
      _p1.iInstr := FPropTable.GetValueAddr(_p1.sInstr);
      Match(tkequal);
      _p2 := sExp(@_p1);
      Inc(Stack);
      _p3.Ints := iident;
      _p3.sInstr := '1tempvar' + IntToStr(Stack);
      _p3.iInstr := -FPropTable.gettempvaraddr(_p3.sInstr);
      Dec(Stack);
      FEmitter.EmitCode(isetobjv, _p4, _p1, _p2);
    end;
  end;
  Result := _p4;
  Match(tkrightbrace);
  FPropTable.EmitObject := False;
  Dec(Stack);
end;

function TParser.stmt_while(AInts: PEmitInts): TEmitInts;
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

function TParser.stmt_assign(AInts: PEmitInts): TEmitInts;
var
  _p1, _p2, _p3, _p4, _p5: TEmitInts;
  LineNo: Integer;
  EmitObj: Boolean;
  fp: TFuncProp;
label L1, L2;
begin
  EmitObj := False;
  Inc(Stack);
  Result.Ints := iident;
  Result.sInstr := idents;
  if TempVar then
  begin
    Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
  end
  else
  begin
    Result.iInstr := FPropTable.getstackaddr(Result.sInstr);
  end;
  _p5 := Result;
  L1:
  L2:
  case GetNextToken() of
    tkleftbracket:
      begin
        Match(tkleftbracket);
        _p1.Ints := pint;
        _p1.iInstr := FPropTable.FindAddr(Result.sInstr);
        if _p1.iInstr = -1 then
          ParserError(' ''' + _p1.sInstr + ''' is not a object');
        _p2 := factor();
        if _p2.Ints = pint then
          _p2.iInstr := -_p2.iInstr;
        Result.Ints := iident;
        Result.sInstr := '1tempvar' + IntToStr(Stack);
        Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
        FEmitter.EmitCode(igetobjv, _p1, _p2, Result);
        Match(tkrightbracket);
        goto L2;
      end;
    tkdot:
      begin
        Match(tkdot);
        Match(tkident);
        _p1.iInstr := FPropTable.FindAddr(Result.sInstr);
        if _p1.iInstr = -1 then
          ParserError(' ''' + _p1.sInstr + ''' is not a object');
        _p1.sInstr := GetToken();
        _p1.Ints := pint;
        _p1.iInstr := FPropTable.GetValueAddr(_p1.sInstr);
        Result.Ints := iident;
        Result.sInstr := '1tempvar' + IntToStr(Stack);
        Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
        EmitObj := True;
        goto L1;
      end;
    tkequal:
      begin
        Match(tkequal);
        _p4 := sExp(@Result);
        if _p4.Ints = pfunc then
        begin
          _p3.Ints := iident;
          _p3.sInstr := '1tempvar' + IntToStr(Stack);
          _p3.iInstr := -FPropTable.gettempvaraddr(_p3.sInstr);
          FEmitter.EmitCode(ipop, _p3);
          FEmitter.EmitCode(imov, _p3, Result);
        end
        else
        begin
          if not EmitObj then
          begin
            FEmitter.EmitCode(imov, _p4, Result)
          end
          else
          begin
            FEmitter.EmitCode(isetobjv, _p5, _p1, _p4);
//            FEmitter.EmitCode(imov, _p4, Result)
          end;
        end;
      end;
    tkleftpart:
      begin
        _p2 := stmt_callfunc;
        if not EmitObj then
        begin
          FEmitter.EmitCode(icall, Result);
        end
        else
        begin
          _p3.Ints := pfunc;
          _p3.iInstr := FPropTable.getfuncaddr(Result.sInstr);
          _p3.sInstr := IntToStr(Result.iInstr);
          FEmitter.EmitCode(igetobjv, _p5, _p1, Result);
          FEmitter.EmitCode(icall, Result);
        end;
      end;
    tksemicolon:
      Match(tksemicolon);
  else
    ParserError('unknown assign word: ' + GetToken);
  end;
  Dec(Stack);
end;

function TParser.stmt_break(AInts: PEmitInts): TEmitInts;
begin
  if not FInWhileStmt then
    ParserError('not in parse while');
  Match(tkbreak);
  FBreakList.Add(Pointer(FEmitter.emitnop))
end;

function TParser.sExp(AInts: PEmitInts): TEmitInts; // 一般表达式
var
  gtoken: TEmitInts;
  _p1, _p2, _p3: TEmitInts;
begin
  Inc(Stack);
  Result := term(AInts);
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

function TParser.logicexp(AInts: PEmitInts): TEmitInts;
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

function TParser.logicop(AInts: PEmitInts): TEmitInts;
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
  Result := FLex.Match(AToken);
end;

function TParser.asop(AInts: PEmitInts): TEmitInts;
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

function TParser.mdop(AInts: PEmitInts): TEmitInts;
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

function TParser.term(AInts: PEmitInts): TEmitInts;
var
  gtoken: TEmitInts;
  _p1, _p2, _p3: TEmitInts;
begin
  Inc(Stack);
  Result := factor(AInts);
  while True do
    case GetNextToken() of
      tkleftbracket:
        begin
          Match(tkleftbracket);
          _p1.Ints := pint;
          _p1.iInstr := FPropTable.FindAddr(Result.sInstr);
          if _p1.iInstr = -1 then
            ParserError(' ''' + _p1.sInstr + ''' is not a object');
          _p2 := factor();
          if _p2.Ints = pint then
            _p2.iInstr := -_p2.iInstr;
          Result.Ints := iident;
          Result.sInstr := '1tempvar' + IntToStr(Stack);
          Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
          FEmitter.EmitCode(igetobjv, _p1, _p2, Result);
          Match(tkrightbracket);
        end;
      tkdot:
        begin
          Match(tkdot);
          Match(tkident);
          _p1.Ints := pint;
          _p1.iInstr := FPropTable.FindAddr(Result.sInstr);
          if _p1.iInstr = -1 then
            ParserError(' ''' + _p1.sInstr + ''' is not a object');
          _p2.sInstr := GetToken();
          _p2.Ints := pint;
          _p2.iInstr := FPropTable.GetValueAddr(_p2.sInstr);
          _p3 := Result;
          Result.Ints := iident;
          Result.sInstr := '1tempvar' + IntToStr(Stack);
          Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
          FEmitter.EmitCode(igetobjv, _p3, _p2, Result);
        end;
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
          Result.Ints := iident;
          Result.iInstr := FPropTable.FindAddr(Result.sInstr);
          if Result.iInstr = 0 then
            Result.iInstr := FPropTable.getfuncaddr(Result.sInstr);
//          Result.sInstr := IntToStr(Result.iInstr);
          FEmitter.EmitCode(icall, Result);
          Result.Ints := iident;
          Result.sInstr := '1tempvar' + IntToStr(Stack);
          Result.iInstr := -FPropTable.gettempvaraddr(Result.sInstr);
          FEmitter.EmitCode(ipop, Result);
        end;
      tkfunc:
        begin
          Result := stmt_func(AInts);
        end;
      tkleftbrace:
        begin
          Result := stmt_object(AInts);
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

function TParser.factor(AInts: PEmitInts): TEmitInts;
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
        if FPropTable.IsAFunc(Result.sInstr) then
        begin
          Result.Ints := pfuncaddr;
          Result.iInstr := FPropTable.GetFuncAddr(Result.sInstr)
        end;
      end;
    tkleftpart:
      begin
        Match(tkleftpart);
        Result := sExp;
        Match(tkrightpart);
      end;
    tknil:
      begin
        Match(tknil);
        Result.Ints := pobject;
        Result.sInstr := 'nil';
        Result.iInstr := 0;
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

function TParser.stmt_read(AInts: PEmitInts): TEmitInts;
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

function TParser.stmt_write(AInts: PEmitInts): TEmitInts;
var
  _p1: TEmitInts;
begin
  Inc(Stack);
  Match(tkwrite);
  _p1 := sExp;
  FEmitter.EmitCode(iwrite, _p1);
  Dec(Stack);
end;

function TParser.stmt_for(AInts: PEmitInts): TEmitInts;
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
  FEmitter.modifiycode(LineNo, ijb, _p5);
  Match(tkend);
end;

function TParser.stmt_func(AInts: PEmitInts): TEmitInts;
var
  CurrentCodeLine, I: Integer;
  _p1: TEmitInts;
  LineNo, lineno2: Integer;
  m_FuncProp: PFuncProp;
  S: string;
begin
  FFrontListStack.Push(FFrontList);
  FFrontList := TList.Create;
  FPropTable.CreateTempVar;
  Inc(Stack);
  Match(tkfunc);
  if not Assigned(AInts) then
  begin
    Match(tkident);
    S := GetToken;
  end
  else
  begin
    S := AInts.sInstr;
  end;
  FEmitter.EmitFuncMgr.StartEmitFunc(S);
  LineNo := FEmitter.emitnop();
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
  FreeAndNil(FFrontList);
  FFrontList := FFrontListStack.Pop;

  if FPropTable.TempVarnameList.Count = 1 then
  begin
    // 删除1条指令，入口地址要修改
    FEmitter.DeleteCode(LineNo);
    I := FPropTable.getfuncaddr(FPropTable.FuncName);
  end
  else
  begin
    _p1.Ints := pint;
    _p1.iInstr := FPropTable.TempVarnameList.Count - 1;
    FEmitter.modifiycode(LineNo, iebp, _p1);

    _p1.Ints := pint;
    _p1.iInstr := -(FPropTable.TempVarnameList.Count - 1);
    FEmitter.EmitCode(iebp, _p1);
  end;
  FEmitter.EmitCode(iret);
  Result.Ints := pfuncaddr;
  Result.sInstr := FEmitter.EmitFuncMgr.CurrentFunc.FuncName;
  Result.iInstr := FEmitter.EmitFuncMgr.FuncCount;
  FEmitter.EmitFuncMgr.EndEmitFunc;
  FPropTable.FreeTempVar;
  {
  AInts = nil 是 类似 function xxx() end; 这种形式的函数
  }

  if AInts = nil then
  begin
    _p1.Ints := iident;
    _p1.sInstr := Result.sInstr;
    _p1.iInstr := FPropTable.GetStackAddr(_p1.sInstr);
    FEmitter.EmitCode(imov, Result, _p1);
  end;
  Dec(Stack);
end;

function TParser.stmt_callfunc(AInts: PEmitInts): TEmitInts;
var
  PushList: array[0..100] of TEmitInts;
  PushI, I: Integer;
  _p1, _p2, _p3: TEmitInts;
begin
  Inc(Stack);
  Match(tkleftpart);
  PushI := 0;
  while True do
  begin
    case GetNextToken() of
      tkrightpart:
        Break;
      tkcomma:
        Match(tkcomma);
    else
      Result := sExp();
      PushList[PushI] := Result;
      Inc(PushI);
    end
  end;
  for I := PushI - 1 downto 0 do
    FEmitter.EmitCode(ipush, PushList[I]);
  Match(tkrightpart);
  Dec(Stack);
end;

function TParser.stmt_continue(AInts: PEmitInts): TEmitInts;
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

function TParser.stmt_var(AInts: PEmitInts): TEmitInts;
begin
  if not FEmitter.EmitFunc then
    ParserError('var must be def in function');
  Match(tkvar);
  TempVar := True;
  stmt_assign;
  TempVar := False;
end;

function TParser.stmt_return(AInts: PEmitInts): TEmitInts;
begin
  if not FEmitter.EmitFunc then
    ParserError('return must be def in function');
  Match(tkreturn);
  Result := sExp;
  FEmitter.EmitCode(ipush, Result);
  FFrontList.Add(Pointer(FEmitter.emitnop()));
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
      FEmitter.EmitFuncMgr.EndEmitFunc;
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

