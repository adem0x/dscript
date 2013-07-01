unit uobjmgr;

interface

uses
  uconst, Classes, IniFiles;

type
  TObjMgr = class;

  TObj = class
  private
    Name: Integer;
    FValues, FValues2: array of TValue;
    FValuesCount, FValuesCount2: Integer;

    FId: Integer;
  public
    constructor Create(AObjMgr: TObjMgr);
    function FindAValue(AName: Integer): PValue;
    function AddAValue(AIndex: Integer; AValue: TValue): Boolean;
    function DelAValue(AName: Integer): PValue;
    function CopyTo(AObj: TObj): Boolean;
    property Id: Integer read FId;
  end;

  TObjMgr = class
  private
    FObjList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    function DeleteAObject(AIndex: Integer): Integer;
    function AddAObject(AObj: TObj): Integer;
    function GetAObject(AIndex: Integer): TObj;
    function ObjectCount: Integer;
  end;

implementation

{ TObj }

function TObj.AddAValue(AIndex: Integer; AValue: TValue): Boolean;
begin
  Result := True;
  if AIndex > 0 then
  begin
    if AIndex >= FValuesCount then
    begin
      FValuesCount := AIndex + 1;
      SetLength(FValues, FValuesCount);
    end;
    FValues[AIndex] := AValue;
  end
  else if AIndex < 0 then
  begin
    AIndex := - AIndex;
    if AIndex >= FValuesCount2 then
    begin
      FValuesCount2 := AIndex + 1;
      SetLength(FValues2, FValuesCount2);
    end;
    FValues2[AIndex] := AValue;
  end else Result := False;
end;

function TObj.CopyTo(AObj: TObj): Boolean;
var
  I: Integer;
begin
  Result := False;
  if not Assigned(AObj) then
    Exit;
  for I := 0 to FValuesCount - 1 do
    AObj.AddAValue(I, FValues[I]);
  for I := 0 to FValuesCount2 - 1 do
    AObj.AddAValue(- I, FValues2[I]);
  Result := True;
end;

constructor TObj.Create(AObjMgr: TObjMgr);
begin
  if Assigned(AObjMgr) then
    FId := AObjMgr.AddAObject(Self);
end;

function TObj.DelAValue(AName: Integer): PValue;
begin
  if AName > 0 then
    FValues[AName]._Type := inone
  else
    FValues2[- AName]._Type := inone;
  Result := nil;
end;

function TObj.FindAValue(AName: Integer): PValue;
begin
  if AName > 0 then
  begin
    if AName < Length(FValues) then
      Result := @FValues[AName]
    else
      Result := nil;
  end else
  if AName < 0 then
  begin
    AName := - AName;
    if AName < Length(FValues2) then
      Result := @FValues2[AName]
    else
      Result := nil;
  end;
end;

{ TObjMgr }

function TObjMgr.AddAObject(AObj: TObj): Integer;
begin
  Result := FObjList.Add(AObj)
end;

constructor TObjMgr.Create;
begin
  FObjList := TList.Create;
  FObjList.Add(nil);
end;

function TObjMgr.DeleteAObject(AIndex: Integer): Integer;
begin
  if AIndex < FObjList.Count then
  begin
    TObj(FObjList[AIndex]).Free;
    FObjList.Delete(AIndex);
  end;
end;

destructor TObjMgr.Destroy;
var
  I: Integer;
begin
  for I := 0 to FObjList.Count - 1 do
  begin
    TObject(FObjList[I]).Free;
  end;
  FObjList.Free;
  inherited;
end;

function TObjMgr.GetAObject(AIndex: Integer): TObj;
begin
  Result := nil;
  if AIndex < FObjList.Count then
    Result := FObjList[AIndex]
end;

function TObjMgr.ObjectCount: Integer;
begin
  Result := FObjList.Count
end;

end.
