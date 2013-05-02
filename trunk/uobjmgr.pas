unit uobjmgr;

interface

uses
  uconst, Classes, IniFiles;

type
  TObjMgr = class;

  TObj = class
    Name: Integer;
    FValues: TList;
  public
    constructor Create(AObjMgr: TObjMgr);
    function FindAValue(AName: Integer): PValue;
    function AddAValue(AValue: TValue): Integer;
    function DelAValue(AName: Integer): PValue;
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
  end;

var
  proplist: TStringList;

implementation

{ TObj }

function TObj.AddAValue(AValue: TValue): Integer;
var
  v: PValue;
begin
  New(v);
  v^ := AValue;
  Result := FValues.Add(v)
end;

constructor TObj.Create(AObjMgr: TObjMgr);
begin
  if Assigned(AObjMgr) then
    AObjMgr.AddAObject(Self);
  FValues := TList.Create;
end;

function TObj.DelAValue(AName: Integer): PValue;
var
  v: PValue;
begin
  v := FValues[AName];
  Dispose(v);
  v := nil;
end;

function TObj.FindAValue(AName: Integer): PValue;
begin
  Result := FValues[AName];
end;

{ TObjMgr }
function TObjMgr.DeleteAObject(AObj: TObj): Integer;
begin

end;

function TObjMgr.AddAObject(AObj: TObj): Integer;
begin

end;

constructor TObjMgr.Create;
begin
  FObjList := TList.Create;
end;

function TObjMgr.DeleteAObject(AIndex: Integer): Integer;
begin

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

initialization

proplist := TStringList.Create;

finalization

proplist.Free;

end.
