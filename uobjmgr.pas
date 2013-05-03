unit uobjmgr;

interface

uses
  uconst, Classes, IniFiles;

type
  TObjMgr = class;

  TObj = class
  private
    Name: Integer;
    FValues: array of TValue;
    FValuesCount: Integer;
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
    function DeleteAObject(AObj: TObj): Integer; overload;
    function DeleteAObject(AIndex: Integer): Integer; overload;
    function AddAObject(AObj: TObj): Integer;
    function GetAObject(AIndex: Integer): TObj;
    function ObjectCount: Integer;
  end;

implementation

{ TObj }

function TObj.AddAValue(AIndex: Integer; AValue: TValue): Boolean;
var
  v: PValue;
begin
  if AIndex >= FValuesCount then
  begin
    FValuesCount := AIndex + 1;
    SetLength(FValues, FValuesCount);
  end;
  FValues[AIndex] := AValue;
  Result := True;
end;

function TObj.CopyTo(AObj: TObj): Boolean;
var
  I: Integer;
begin
  Result := False;
  if not Assigned(AObj) then Exit;
  for I := 0 to FValuesCount - 1 do
  begin
    AObj.AddAValue(I, FValues[I])
  end;
  Result := True;
end;

constructor TObj.Create(AObjMgr: TObjMgr);
begin
  if Assigned(AObjMgr) then
    FId := AObjMgr.AddAObject(Self);
end;

function TObj.DelAValue(AName: Integer): PValue;
begin
  FValues[AName]._Type := inone;
end;

function TObj.FindAValue(AName: Integer): PValue;
begin
  Result := @FValues[AName];
end;

{ TObjMgr }
function TObjMgr.DeleteAObject(AObj: TObj): Integer;
begin

end;

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
