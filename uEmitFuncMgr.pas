unit uEmitFuncMgr;

interface
uses
  SysUtils, Classes, uproptable;
//管理生成的函数，便于代码优化
type
  TEmitFunc = class
  private
    FFuncName: string;
    FCodeLineCount: Integer;
    FCode: array of PAnsiChar;
    FCodeBufSize: Integer;
    function GetCode(Index: Integer): PAnsiChar;
  public
    constructor Create;
    function AddACode(ACode: PAnsiChar): Boolean;
    function ModifiyCode(ALineNo: Integer; ACode: PAnsiChar): Boolean;
    function DeleteCode(ALineNo: Integer): Boolean;
    property CodeLineCount:Integer  read FCodeLineCount;
    property FuncName:string  read FFuncName write FFuncName;
    property Code[Index: Integer]:PAnsiChar  read GetCode;
  end;

  TEmitFuncMgr = class
  private
    FLastFunc: TEmitFunc;
    FCurrentFunc: TEmitFunc;
    FFunc: array of TEmitFunc;
    FFuncBufSize: Integer;
    FFuncCount: Integer;
    FPropTable: TPropTable;
  public
    constructor Create(APropTable: TPropTable);
    procedure StartEmitFunc(AFuncName: string);
    function AddACode(ACode: PAnsiChar): Boolean;
    function ModifiyCode(ALineNo: Integer; ACode: PAnsiChar): Boolean;
    function DeleteCode(ALineNo: Integer): Boolean;
    procedure EndEmitFunc;
    procedure OptimizeCode();
    function SaveCodeToList(AList: TList): Integer; //返回入口地址
    property FuncCount:Integer  read FFuncCount;
    property CurrentFunc: TEmitFunc  read FCurrentFunc;
  end;

implementation
uses
  uOptimizer;

{ TEmitFunc }

function TEmitFunc.AddACode(ACode: PAnsiChar): Boolean;
begin
  if FCodeLineCount>= FCodeBufSize then
  begin
    Inc(FCodeBufSize, 10);
    SetLength(FCode, FCodeBufSize);
  end;
  FCode[CodeLineCount] := ACode;
  Inc(FCodeLineCount);
  Result := True;
end;

constructor TEmitFunc.Create;
begin
  FCodeLineCount := 0;
  FCodeBufSize := 0;
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
  for I:= ALineNo to FCodeLineCount - 1 do
  begin
    FCode[I] := FCode[I + 1]
  end;
  Dec(FCodeLineCount);
  Result := True;
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
  FPropTable:= APropTable;
  StartEmitFunc('1Main')
end;

procedure TEmitFuncMgr.StartEmitFunc(AFuncName: string);
begin
  FLastFunc := FCurrentFunc;
  FCurrentFunc := TEmitFunc.Create;
  FCurrentFunc.FFuncName := AFuncName;
end;

procedure TEmitFuncMgr.EndEmitFunc;
begin
  if FFuncCount >= FFuncBufSize then
  begin
    Inc(FFuncBufSize, 10);
    SetLength(FFunc, FFuncBufSize)
  end;
  FFunc[FFuncCount] := FCurrentFunc;
  Inc(FFuncCount);
  FCurrentFunc := FLastFunc;
  FLastFunc := nil;
end;

function TEmitFuncMgr.ModifiyCode(ALineNo: Integer;
  ACode: PAnsiChar): Boolean;
begin
  Result := FCurrentFunc.ModifiyCode(ALineNo, ACode)
end;

function TEmitFuncMgr.SaveCodeToList(AList: TList): Integer;
var
  I, J: Integer;
  m_LastFuncCodeCount: Integer;
  m_FuncProp: TFuncProp;
begin
  Result := -1;
  if not Assigned(AList) then Exit;
  if FFunc[FFuncCount - 1].FFuncName <> '1Main' then raise Exception.Create('emit main code is undone');
  m_LastFuncCodeCount := 0;
  Result := 0;
  for I:= 0 to FFuncCount - 1 do
  begin
    if I < FFuncCount - 1 then
    begin
    Inc(Result, FFunc[I].CodeLineCount);
    m_FuncProp.FuncName := FFunc[I].FFuncName;
    m_FuncProp.EntryAddr := m_LastFuncCodeCount;
    FPropTable.FuncPropTable[I] := @m_FuncProp;
    Inc(m_LastFuncCodeCount, FFunc[I].CodeLineCount);
    end;
    for J:= 0 to FFunc[I].CodeLineCount - 1 do
      AList.Add(FFunc[I].FCode[J])
  end;
end;

function TEmitFuncMgr.DeleteCode(ALineNo: Integer): Boolean;
begin
  Result := FCurrentFunc.DeleteCode(ALineNo)
end;

procedure TEmitFuncMgr.OptimizeCode;
var
  ToFunc: array of TEmitFunc;
  I: Integer;
begin
  Exit;
  SetLength(ToFunc, FFuncCount);
  for I:= 0 to FFuncCount - 1 do
  begin
    ToFunc[I] := PeepHoleOptimize(FFunc[I]);
    FFunc[I].Free;
    FFunc[I] := ToFunc[I];
  end;
end;

end.
