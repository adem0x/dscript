unit uPropTable;

interface

uses
  uconst, Classes, Contnrs;

type
  PFuncProp = ^TFuncProp;
  PValues = ^TValues;
  TValues = array[0..255] of TValue;
  TFuncProp = record
    FuncName: string;
    EntryAddr: Integer;
    UpValue: TValues;
  end;

type
  TPropTable = class
  private
    FFuncPropCount: Integer;
    FFuncPropTable: array of TFuncProp;
    FFuncVarPropTable: array of array of string; // 0维是全局
    FObjectValuePropTable: array of string;
    function GetFuncPropTable(Index: Integer): PFuncProp;
    procedure SetFuncPropTable(Index: Integer; const Value: PFuncProp);

    procedure SetFuncVarPropTable(X, Y: Integer; const Value: string);
    procedure SetObjectValuePropTable(X: Integer; const Value: string);
  public
    FTempVarListStack: TStack;
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
    function IsAClosureVar(varname: string): Boolean;
    procedure FreeTempVar;
    procedure ClearValue;
    function GetFuncVarPropTable(X, Y: Integer): string;
    function GetObjectValuePropTable(X: Integer): string;
    property FuncPropTable[Index: Integer]: PFuncProp read GetFuncPropTable
    write SetFuncPropTable;
  end;
const
  CZeroStr = '999888t';

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
  TempVarnameList.Add(CZeroStr);
end;

procedure TPropTable.ClearValue;
begin
  FValueList.Clear;
  FValueList.Add('prototype'); //0的位置放原型继承
end;

constructor TPropTable.Create;
begin
  VarnameList := TStringList.Create;
  VarnameList.Add(CZeroStr);
  FuncNameList := TStringList.Create;
  FuncNameList.Add(CZeroStr);
  StrList := TStringList.Create;
  StrList.Add(CZeroStr);
  FValueList := TStringList.Create;
  FValueList.Add('prototype');
  FTempVarListStack := TStack.Create;
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
  end;
  FFuncPropTable[index] := Value^;
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
  Result := FuncNameList.IndexOf(AVarName) > -1;
end;

procedure TPropTable.CreateTempVar();
var
  m_list: TStringList;
begin
  FTempVarListStack.Push(TempVarnameList);
  m_list := TStringList.Create;
  if Assigned(TempVarnameList) then
  begin
    m_list.AddStrings(TempVarnameList);
    TempVarnameList := m_list;
  end else
  begin
    TempVarnameList := m_list;
    TempVarnameList.Add(CZeroStr)
  end;
end;

procedure TPropTable.FreeTempVar;
begin
  TempVarnameList.Free;
  TempVarnameList := FTempVarListStack.Pop;
end;

function TPropTable.IsAClosureVar(varname: string): Boolean;
var
  m_list: TStringList;
  I: Integer;
begin
  Result := False;
  for I := 0 to FTempVarListStack.List.Count - 1 do
  begin
    m_list := FTempVarListStack.List[I];
    if Assigned(m_list) and (m_list.IndexOf(varname) >= 0) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

end.

