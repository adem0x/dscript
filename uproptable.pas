unit uPropTable;

interface

uses
  uconst, Classes, Contnrs;

type
  PFuncProp = ^TFuncProp;

  TFuncProp = record
    FuncName: string;
    EntryAddr: Integer;
  end;

type
  TPropTable = class
  private
    FTempVarListStack: TStack;
    FFuncPropCount: Integer;
    FFuncPropTable: array of TFuncProp;
    FFuncVarPropTable: array of array of string; // 0维是全局
    FObjectValuePropTable: array of string;
    function GetFuncPropTable(Index: Integer): PFuncProp;
    procedure SetFuncPropTable(Index: Integer; const Value: PFuncProp);

    procedure SetFuncVarPropTable(X, Y: Integer; const Value: string);
    procedure SetObjectValuePropTable(X: Integer; const Value: string);
  public
    FCurrentTempVarInFuncName: string;
    StrList, VarnameList, TempVarnameList, FuncNameList, FValueList: TStringList;
    FuncName: string;
    EmitObject: Boolean;
    constructor Create;
    function IsAFunc(AVarName: string): Boolean;
    function FindValueAddr(AValueName: string): Integer;
    function GetValueAddr(AValeName: string): Integer;
    function FindAddr(varname: string): Integer;
    function GetFuncAddr(varname: string; EntryAddr: Integer): Integer;
      overload;
    function GetFuncAddr(varname: string): Integer; overload;
    function GetStackAddr(varname: string): Integer;
    function GetStrAddr(strname: string): Integer;
    function GetTempVarAddr(varname: string): Integer;
    procedure ClearTempVar;
    procedure CreateTempVar();
    procedure FreeTempVar;
    procedure ClearValue;
    function GetFuncVarPropTable(X, Y: Integer): string;
    function GetObjectValuePropTable(X: Integer): string;
    property FuncPropTable[Index: Integer]: PFuncProp read GetFuncPropTable
      write SetFuncPropTable;
  end;

implementation

function TPropTable.GetStrAddr(strname: string): Integer;
begin
  Result := StrList.IndexOf(strname);
  if Result = -1 then
  begin
    StrList.Add(strname);
    Result := StrList.IndexOf(strname);
  end;
end;

function TPropTable.GetFuncAddr(varname: string; EntryAddr: Integer): Integer;
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
  if (not Assigned(pm_FuncProp)) or (EntryAddr >= 0) then
  begin
    m_FuncProp.FuncName := varname;
    m_FuncProp.EntryAddr := EntryAddr;
    FuncPropTable[Result] := @m_FuncProp;
  end;
end;

function TPropTable.GetFuncAddr(varname: string): Integer;
begin
  Result := GetFuncAddr(varname, -1);
end;

function TPropTable.GetStackAddr(varname: string): Integer;
begin
  if EmitObject then
  begin
    Result := GetValueAddr(varname);
  end
  else
  begin
    Result := FuncNameList.IndexOf(varname);
    if Result = -1 then
    begin
      Result := TempVarnameList.IndexOf(varname);
    end;
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
end;

function TPropTable.FindAddr(varname: string): Integer;
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

function TPropTable.GetTempVarAddr(varname: string): Integer;
var
  Y: Integer;
begin
  Result := TempVarnameList.IndexOf(varname);
  if Result = -1 then
  begin
    TempVarnameList.Add(varname);
    Result := TempVarnameList.IndexOf(varname);
    Y := FuncNameList.IndexOf(FuncName);
    if Y = -1 then
      Y := 0;
    SetFuncVarPropTable(Y, Result, varname);
  end;
end;

function TPropTable.GetValueAddr(AValeName: string): Integer;
begin
  Result := FValueList.IndexOf(AValeName);
  if Result = -1 then
  begin
    Result := FValueList.Add(AValeName);
    SetObjectValuePropTable(Result, AValeName);
  end;
end;
procedure TPropTable.ClearTempVar;
begin
  TempVarnameList.Clear;
  TempVarnameList.Add('999888t');
end;

procedure TPropTable.ClearValue;
begin
  FValueList.Clear;
  FValueList.Add('prototype');//0的位置放原型继承
end;

constructor TPropTable.Create;
begin
  VarnameList := TStringList.Create;
  VarnameList.Add('999888t');
  FuncNameList := TStringList.Create;
  FuncNameList.Add('999888t');
  StrList := TStringList.Create;
  StrList.Add('999888t');
  FValueList := TStringList.Create;
  FValueList.Add('prototype');
  FTempVarListStack := TStack.Create;
  CreateTempVar();
end;

function TPropTable.GetFuncPropTable(Index: Integer): PFuncProp;
begin              
  if Index >= FFuncPropCount then
    Result := nil
  else
  begin
    Result := @FFuncPropTable[index]
  end;
end;

procedure TPropTable.SetFuncPropTable(Index: Integer; const Value: PFuncProp);
begin
  if Index < 0 then Exit;
  if index >= FFuncPropCount then
  begin
    SetLength(FFuncPropTable, index + 1);
    FFuncPropCount := Index + 1;
    FFuncPropTable[index] := Value^;
  end;
end;

function TPropTable.GetFuncVarPropTable(X, Y: Integer): string;
begin
  if (Length(FFuncVarPropTable) > X) and (Length(FFuncVarPropTable[X]) > Y) then
    Result := FFuncVarPropTable[X][Y];
end;


function TPropTable.GetObjectValuePropTable(X: Integer): string;
begin
  if (Length(FObjectValuePropTable) > X) then
    Result := FObjectValuePropTable[X];
end;

procedure TPropTable.SetFuncVarPropTable(X, Y: Integer; const Value: string);
begin
  if Length(FFuncVarPropTable) <= X then
    SetLength(FFuncVarPropTable, X + 1);
  if Length(FFuncVarPropTable[X]) <= Y then
    SetLength(FFuncVarPropTable[X], Y + 1);
  FFuncVarPropTable[X][Y] := Value;
end;

procedure TPropTable.SetObjectValuePropTable(X: Integer;
  const Value: string);
begin
  if Length(FObjectValuePropTable) <= X then
    SetLength(FObjectValuePropTable, X + 1);
  FObjectValuePropTable[X] := Value;
end;

function TPropTable.FindValueAddr(AValueName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Length(FObjectValuePropTable) - 1 do
  begin
    if FObjectValuePropTable[I] = AValueName then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TPropTable.IsAFunc(AVarName: string): Boolean;
begin
  Result :=  FuncNameList.IndexOf(AVarName) > -1;
end;

procedure TPropTable.CreateTempVar();
begin
  FTempVarListStack.Push(TempVarnameList);
  TempVarnameList := TStringList.Create;
  TempVarnameList.Add('999888t');
end;

procedure TPropTable.FreeTempVar;
begin
  TempVarnameList.Free;
  TempVarnameList := FTempVarListStack.Pop;
end;

end.
