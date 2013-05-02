unit ulex;

interface

uses
  SysUtils;

{
  read
  write
  if
  then
  else
  while
  do
  end
  function
  var
  break
  continue
  new
  for
  .
  <
  >
  =
  <>
  >=
  <=
  ==

  +
  -
  *
  /
  (
  )
  %
  {
}
// }
type
  Token = (tknone, tkhalt, tkread, tkwrite, tkif, tkthen, tkelse, tkwhile, tkdo,
    tkend, tkop, tkident, tkaddop, tksubop, tkmulop, tkdivop, tkintnum,
    tkfloatnum, tknum, tkaend, tkdot, tkequal, tkbigop, tksmallop, tkbigequalop,
    tksmallequalop, tkunequal, tkleftpart, tkrightpart, tksemicolon, tkstring,
    tkfunc, tkvar, tkcomma, tkbegin, tkreturn, tkret, tkbreak, tkcontinue,
    tkmodop, tkleftbrace, tkrightbrace, tknew, tkfor);

var
  KeyWord: array [0 .. 16] of string = (
    'read',
    'write',
    'if',
    'then',
    'else',
    'while',
    'do',
    'end',
    'function',
    'var',
    'begin',
    'return',
    'ret',
    'break',
    'continue',
    'new',
    'for'
  );
  KeyWordToken: array [0 .. 16] of Token = (
    tkread,
    tkwrite,
    tkif,
    tkthen,
    tkelse,
    tkwhile,
    tkdo,
    tkend,
    tkfunc,
    tkvar,
    tkbegin,
    tkreturn,
    tkret,
    tkbreak,
    tkcontinue,
    tknew,
    tkfor
  );

type
  TLex = class
  private
    CurrentToken: string;
    SrcLineNo: integer; // ÐÐºÅ
    FSourceLen: PAnsiChar;
    FSource: PAnsiChar;
    procedure SetSource(const Value: PAnsiChar);
  public
    function GetNextToken(AMactch: boolean = False): Token;
    function GetToken(): string;
    function Match(AToken: Token): boolean;
    procedure LexError(s: string);
    property Source: PAnsiChar read FSource write SetSource;
  end;

implementation

procedure TLex.LexError(s: string);
begin
  raise Exception.Create('LexError: ' + s + ' On Line:' + IntToStr(SrcLineNo));
end;

function TLex.GetNextToken(AMactch: boolean): Token;
var
  Temp: array [0 .. 255] of AnsiChar;
  Tempi: integer;
  StateToken, LastToken: Token;
  m_Src: PAnsiChar;
  I: integer;
  InStr: integer;
begin
  m_Src := Source;
  Tempi := 0;
  LastToken := tknone;
  StateToken := tknone;
  Result := tknone;
  while (FSource^ = ' ') or (FSource^ = #10) or (FSource^ = #13) do
    Inc(FSource);
  InStr := 0;
  if FSource >= FSourceLen then
  begin
    Result := tkhalt;
    Exit;
  end;
  while True do
  begin
    case FSource^ of
      '0' .. '9':
        begin
          StateToken := tknum;
        end;
      'a' .. 'z', 'A' .. 'Z', '_':
        begin
          StateToken := tkident;
        end;
      #0:
        begin
          StateToken := tkaend;
        end;
      ' ':
        StateToken := tkaend;
      #10:
        begin
          StateToken := tkaend;
          Inc(SrcLineNo);
        end;
      #13, #9:
        begin
          Inc(FSource);
          Continue;
        end;
      '.':
        StateToken := tkdot;
      '=':
        StateToken := tkequal;
      '>':
        StateToken := tkbigop;
      '<':
        StateToken := tksmallop;
      '+':
        StateToken := tkaddop;
      '-':
        StateToken := tksubop;
      '*':
        StateToken := tkmulop;
      '/':
        StateToken := tkdivop;
      '(':
        StateToken := tkleftpart;
      ')':
        StateToken := tkrightpart;
      ';':
        StateToken := tksemicolon;
      '''':
        StateToken := tkstring;
      ',':
        StateToken := tkcomma;
      '%':
        StateToken := tkmodop;
      '{':
        StateToken := tkleftbrace;
      '}':
        StateToken := tkrightbrace;
    else
      LexError('unknow word' + FSource^);
    end;
    if StateToken in [tkequal, tkaddop, tksubop, tkmulop, tkdivop, tkbigop,
      tksmallop, tkleftpart, tkrightpart, tksemicolon, tkcomma, tkmodop, tkdot,
      tkleftbrace, tkrightbrace] then
    begin
      if LastToken in [tknum, tkfloatnum, tkident, tkstring] then
        StateToken := tkaend;
    end;
    if LastToken = tknone then
      LastToken := StateToken;
    if StateToken = tkaend then
    begin
      Result := LastToken;
      Temp[Tempi] := #0;
      CurrentToken := Temp;
      if Result = tkident then
      begin
        for I := Low(KeyWord) to High(KeyWord) do
        begin
          if CurrentToken = KeyWord[I] then
          begin
            Result := KeyWordToken[I];
            Break;
          end;
        end;
      end;
      if (Result = tkstring) and (InStr > 0) then
      begin
        SetLength(CurrentToken, Length(CurrentToken) - 1);
        if (InStr mod 2) = 0 then
          LexError(''' error');
      end;
      Break;
    end;
    case LastToken of
      tknum:
        begin
          // lasttoken := tknum;
          Temp[Tempi] := Source^;
          Inc(Tempi);
          Inc(FSource);
          if StateToken = tkdot then
            LastToken := tkfloatnum;
        end;
      tkfloatnum:
        begin
          Temp[Tempi] := Source^;
          Inc(Tempi);
          Inc(FSource);
        end;
      tkident:
        begin
          Temp[Tempi] := Source^;
          Inc(Tempi);
          Inc(FSource);
        end;
      tkbigop:
        begin
          Temp[Tempi] := Source^;
          Inc(Tempi);
          Inc(FSource);
          if StateToken = tkequal then
          begin
            Result := tkbigequalop;
            Temp[Tempi] := #0;
            CurrentToken := Temp;
            Break;
          end
          else if StateToken = tksmallop then
          begin
            Result := tkunequal;
            Temp[Tempi] := #0;
            CurrentToken := Temp;
            Break;
          end;
        end;
      tksmallop:
        begin
          Temp[Tempi] := Source^;
          Inc(Tempi);
          Inc(FSource);
          if StateToken = tkequal then
          begin
            Result := tksmallequalop;
            Temp[Tempi] := #0;
            CurrentToken := Temp;
            Break;
          end;
        end;
      tkaddop, tksubop, tkmulop, tkdivop, tkequal, tkleftpart, tkrightpart,
        tksemicolon, tkcomma, tkmodop, tkdot, tkleftbrace, tkrightbrace:
        begin
          Result := LastToken;
          CurrentToken := Source^;
          Inc(FSource);
          Break;
        end;
      tkhalt:
        begin
          Result := LastToken;
          CurrentToken := 'halt';
          Break;
        end;
      tkstring:
        begin
          if InStr > 0 then
          begin
            Temp[Tempi] := Source^;
            Inc(Tempi);
          end;
          Inc(FSource);
          Inc(InStr);
        end;
    end;
  end;
  if not AMactch then
    Source := m_Src;
end;

function TLex.GetToken(): string;
begin
  Result := CurrentToken;
end;

function TLex.Match(AToken: Token): boolean;
begin
  if GetNextToken() = AToken then
  begin
    GetNextToken(True);
    Result := True;
{$IFDEF lex}
    Write(GetToken, ' ');
{$ENDIF}
  end
  else
  begin
    Result := False;
    // {$IFDEF lex}
    LexError('Match Error:' + CurrentToken);
    // {$ENDIF}
  end;
end;

procedure TLex.SetSource(const Value: PAnsiChar);
begin
  FSource := Value;
  FSourceLen := FSource + Length(FSource);
end;

end.
