unit uEmitFuncMgr;

interface
uses
  SysUtils, Classes, uproptable, Contnrs, uconst;
//管理生成的函数，便于代码优化
type
  TEmitFunc = class
  private
    FFuncName: string;
    FCodeLineCount: Integer;
    FCode: array of PAnsiChar;
    FCodeBufSize: Integer;
    FClosureVarList: TStringList;
    function GetCode(Index: Integer): PAnsiChar;
  public
    constructor Create;
    destructor Destroy; override;
    function AddACode(ACode: PAnsiChar): Boolean;
    function ModifiyCode(ALineNo: Integer; ACode: PAnsiChar): Boolean;
    function DeleteCode(ALineNo: Integer): Boolean;
    property CodeLineCount: Integer read FCodeLineCount;
    property FuncName: string read FFuncName write FFuncName;
    property Code[Index: Integer]: PAnsiChar read GetCode;
    procedure AddClosureVar(AVarName: string);
    function FindAColsureVar(AVarName: string): Boolean;
  end;

  TEmitFuncMgr = class
  private
    FStack: TStack;
    FCurrentFunc, FLastFunc: TEmitFunc;
    FFunc: TList;
    FPropTable: TPropTable;
    FCurrentFuncIndex: Integer;
    function GetFuncCount: Integer;
  public
    constructor Create(APropTable: TPropTable);
    procedure StartEmitFunc(AFuncName: string);
    function AddACode(ACode: PAnsiChar): Boolean;
    function ModifiyCode(ALineNo: Integer; ACode: PAnsiChar): Boolean;
    function DeleteCode(ALineNo: Integer): Boolean;
    procedure EndEmitFunc;
    function SaveCodeToList(AList: TList): Integer; //返回入口地址
    property FuncCount: Integer read GetFuncCount;
    property CurrentFunc: TEmitFunc read FCurrentFunc;
    function FirstFunc: TEmitFunc;
    function GetNextFunc(AFunc: TEmitFunc = nil): TEmitFunc;
    procedure AddClosureVar(AVarName: string);
    function GetFuncNum(AFunc: TEmitFunc): Integer;
  end;

implementation
uses
  uOptimizer;

{ TEmitFunc }

function TEmitFunc.AddACode(ACode: PAnsiChar): Boolean;
begin
  if FCodeLineCount >= FCodeBufSize then
  begin
    Inc(FCodeBufSize, 10);
    SetLength(FCode, FCodeBufSize);
  end;
  FCode[CodeLineCount] := ACode;
  Inc(FCodeLineCount);
  Result := True;
end;

procedure TEmitFunc.AddClosureVar(AVarName: string);
begin
  FClosureVarList.Add(AVarName)
end;

constructor TEmitFunc.Create;
begin
  FCodeLineCount := 0;
  FCodeBufSize := 0;
  FClosureVarList := TStringList.Create;
end;

function TEmitFunc.DeleteCode(ALineNo: Integer): Boolean;
var
  I: Integer;
begin
  if ALineNo >= FCodeLineCount then
  begin
    Result := False;
    Exit;
  end;
  FreeMem(FCode[ALineNo]);
  for I := ALineNo to FCodeLineCount - 1 do
  begin
    FCode[I] := FCode[I + 1]
  end;
  Dec(FCodeLineCount);
  Result := True;
end;

destructor TEmitFunc.Destroy;
begin
  FClosureVarList.Free;
  inherited;
end;

function TEmitFunc.FindAColsureVar(AVarName: string): Boolean;
begin
  Result := FClosureVarList.IndexOf(AVarName) <> -1
end;

function TEmitFunc.GetCode(Index: Integer): PAnsiChar;
begin
  if Index < FCodeLineCount then
    Result := FCode[Index]
  else
    Result := nil;
end;

function TEmitFunc.ModifiyCode(ALineNo: Integer;
  ACode: PAnsiChar): Boolean;
begin
  FreeMem(FCode[ALineNo]);
  FCode[ALineNo] := ACode;
  Result := True;
end;

{ TEmitFuncMgr }

function TEmitFuncMgr.AddACode(ACode: PAnsiChar): Boolean;
begin
  Result := FCurrentFunc.AddACode(ACode)
end;

constructor TEmitFuncMgr.Create(APropTable: TPropTable);
begin
  FStack := TStack.Create;
  FFunc := TList.Create;
  FPropTable := APropTable;
  StartEmitFunc('1Main');
end;

procedure TEmitFuncMgr.StartEmitFunc(AFuncName: string);
begin
  FStack.Push(FCurrentFunc);
  FLastFunc := FCurrentFunc;
  FCurrentFunc := TEmitFunc.Create;
  FCurrentFunc.FFuncName := AFuncName;
  FPropTable.CreateTempVar();
end;

procedure TEmitFuncMgr.EndEmitFunc;
var
  m_CodeCount: Integer;
  m_FuncProp: TFuncProp;
  I: Integer;
begin
  FPropTable.FreeTempVar;
  m_CodeCount := 0;
  for I := 0 to FFunc.Count - 1 do
    Inc(m_CodeCount, TEmitFunc(FFunc[I]).CodeLineCount);
  FFunc.Add(FCurrentFunc);
  m_FuncProp.FuncName := FCurrentFunc.FFuncName;
  m_FuncProp.EntryAddr := m_CodeCount; //从0开始，所以不用加1
  for I := 0 to Length(m_FuncProp.UpValue) - 1 do
  begin
    with m_FuncProp.UpValue[I] do
    begin
      _Type := inone;
      _CodeType := inone;
      _Int := 0;
      _Boolean := False;
      _Value := nil;
    end;
  end;

  FPropTable.FuncPropTable[FFunc.Count - 1] := @m_FuncProp;
  FCurrentFunc := FStack.Pop
end;

function TEmitFuncMgr.ModifiyCode(ALineNo: Integer;
  ACode: PAnsiChar): Boolean;
begin
  Result := FCurrentFunc.ModifiyCode(ALineNo, ACode)
end;

function TEmitFuncMgr.SaveCodeToList(AList: TList): Integer;
var
  I, J: Integer;
  m_FuncProp: PFuncProp;
begin
  Result := -1;
  if not Assigned(AList) then Exit;
  if TEmitFunc(FFunc[FFunc.Count - 1]).FFuncName <> '1Main' then raise Exception.Create('emit main code is undone');

  m_FuncProp := FPropTable.FuncPropTable[FFunc.Count - 1];
  Result := m_FuncProp.EntryAddr;
  for I := 0 to FFunc.Count - 1 do
  begin
    for J := 0 to TEmitFunc(FFunc[I]).CodeLineCount - 1 do
      AList.Add(TEmitFunc(FFunc[I]).FCode[J])
  end;
end;

function TEmitFuncMgr.DeleteCode(ALineNo: Integer): Boolean;
begin
  Result := FCurrentFunc.DeleteCode(ALineNo)
end;

function TEmitFuncMgr.GetFuncCount: Integer;
begin
  Result := FFunc.Count
end;

function TEmitFuncMgr.GetFuncNum(AFunc: TEmitFunc): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FFunc.Count - 1 do
  begin
    if AFunc = FFunc[I] then
    begin
      Result := I;
      Break;
    end;
  end;

end;

procedure TEmitFuncMgr.AddClosureVar(AVarName: string);
begin
  if Assigned(FCurrentFunc) then
    FCurrentFunc.AddClosureVar(AVarName);
end;

function TEmitFuncMgr.FirstFunc: TEmitFunc;
begin
  FCurrentFuncIndex := 0;
  if FFunc.Count > 0 then
    Result := FFunc[0]
  else
    Result := nil;
end;

function TEmitFuncMgr.GetNextFunc(AFunc: TEmitFunc): TEmitFunc;
var
  I: Integer;
begin
  Result := nil;
  if not Assigned(AFunc) then
  begin
    Inc(FCurrentFuncIndex);
    if FCurrentFuncIndex < FFunc.Count then
      Result := FFunc[FCurrentFuncIndex]
  end else
  begin
    for I := 0 to FFunc.Count - 1 do
    begin
      if AFunc = FFunc[I] then
      begin
        if (I + 1) < FFunc.Count then
        begin
          FCurrentFuncIndex := I + 1;
          Result := FFunc[FCurrentFuncIndex];
        end;
        Break;
      end;

    end;
  end;
end;

end.

