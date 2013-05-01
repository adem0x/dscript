unit uproptable;

interface
uses
  uconst, Classes;
type
  PFuncProp = ^TFuncProp;
  TFuncProp = record
    FuncName: string;
    EntryAddr: Integer;
  end;
type
  TPropTable = class
  private
    FFuncPropCount: Integer;
    FFuncPropTable: array of TFuncProp;

    FFuncVarPropTable: array of array of string;
    function GetFuncPropTable(Index: Integer): PFuncProp;
    procedure SetFuncPropTable(Index: Integer; const Value: PFuncProp);

    procedure SetFuncVarPropTable(X,Y: Integer; const Value: string);
  public
    StrList, VarnameList, TempVarnameList, FuncNameList
    : TStringList;
    EmitFunc: boolean;
    FuncName: string;
    constructor Create;
    function FindAddr(varname: string): integer;
    function GetFuncAddr(varname: string; entryaddr: Integer): Integer; overload;
    function GetFuncAddr(varname: string): Integer; overload;
    function GetStackAddr(varname: string): integer;
    function GetStrAddr(strname: string): integer;
    function GetTempVarAddr(varname: string): integer;
    procedure ClearTempVar;
    function GetFuncVarPropTable(X, Y: Integer): string;
    property FuncPropTable[Index: Integer]: PFuncProp read GetFuncPropTable write SetFuncPropTable;
  end;

implementation

function TPropTable.GetStrAddr(strname: string): integer;
begin
  Result := StrList.IndexOf(strname);
  if Result = -1 then
  begin
    StrList.Add(strname);
    Result := StrList.IndexOf(strname);
  end;
end;

function TPropTable.GetFuncAddr(varname: string;entryaddr: Integer): integer;
var
  pm_FuncProp: PFuncProp;
  m_FuncProp: TFuncProp;
begin
  if varname = '' then
  begin
    Result := 0;
    Exit;
  end;
  Result := FuncNameList.IndexOf(varname);
  if Result = -1 then
  begin
    FuncNameList.Add(varname);
    Result := FuncNameList.IndexOf(varname);
  end;
  pm_FuncProp := FuncPropTable[Result];
  if(not Assigned(pm_FuncProp)) or (entryaddr >= 0) then
  begin
    m_FuncProp.FuncName := varname;
    m_FuncProp.EntryAddr := entryaddr;
    FuncPropTable[Result] := @m_FuncProp;
  end;
end;


function TPropTable.GetFuncAddr(varname: string): Integer;
begin
  Result := GetFuncAddr(varname, -1);
end;

function TPropTable.GetStackAddr(varname: string): integer;
begin
  Result := FuncnameList.IndexOf(varname);
  if Result = -1 then
    Result := TempVarnameList.IndexOf(varname);
  if Result = -1 then
  begin
    Result := VarnameList.IndexOf(varname);
    if Result = -1 then
    begin
      VarnameList.Add(varname);
      Result := VarnameList.IndexOf(varname);
      SetFuncVarPropTable(0, Result, varname);
    end;
  end
  else
    Result := -Result;
end;

function TPropTable.FindAddr(varname: string): integer;
begin
  Result := TempVarnameList.IndexOf(varname);
  if Result = -1 then
  begin
    Result := VarnameList.IndexOf(varname);
    if Result = -1 then
      Result := 0;
  end
  else
    Result := -Result;
end;

function TPropTable.GetTempVarAddr(varname: string): integer;
var
  Y: Integer;
begin
  Result := TempVarnameList.IndexOf(varname);
  if Result = -1 then
  begin
    TempVarnameList.Add(varname);
    Result := TempVarnameList.IndexOf(varname);
    Y := FuncNameList.IndexOf(FuncName);
    if Y = -1 then Y:= 0;
    SetFuncVarPropTable(Y, Result, varname);
  end;
end;
procedure TPropTable.ClearTempVar;
begin
  TempVarnameList.Clear;
  TempVarnameList.Add('999888t');
end;

constructor TPropTable.Create;
begin
  VarnameList := TStringList.Create;
  VarnameList.Add('999888t');
  TempVarnameList := TStringList.Create;
  TempVarnameList.Add('999888t');
  FuncnameList := TStringList.Create;
  FuncnameList.Add('999888t');
  StrList := TStringList.Create;
  StrList.Add('999888t');
end;

function TPropTable.GetFuncPropTable(Index: Integer): PFuncProp;
begin
  if Index > FFuncPropCount then Result := nil
  else
  begin
    Result := @FFuncPropTable[index - 1]
  end;
end;

procedure TPropTable.SetFuncPropTable(Index: Integer;
  const Value: PFuncProp);
begin
  if Index < 0 then Exit;
  if index >= FFuncPropCount then
  begin
    SetLength(FFuncPropTable, index);
    FFuncPropCount := Index;
    FFuncPropTable[index - 1] := Value^;
  end;
end;

function TPropTable.GetFuncVarPropTable(X, Y: Integer): string;
begin
  if (Length(FFuncVarPropTable) > X) and (Length(FFuncVarPropTable[X]) > Y) then
    Result := FFuncVarPropTable[X][Y];
end;

procedure TPropTable.SetFuncVarPropTable(X, Y: Integer;
  const Value: string);
begin
  if Length(FFuncVarPropTable) <= X then SetLength(FFuncVarPropTable, X + 1);
  if Length(FFuncVarPropTable[X]) <= Y then SetLength(FFuncVarPropTable[X], Y + 1);
  FFuncVarPropTable[X][Y] := Value;
end;

end.
