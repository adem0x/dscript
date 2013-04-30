unit uobjmgr;

interface
uses
  uconst, Classes, IniFiles;
type
  TObjMgr = class;
  TObj = class
    Name: string;
    FValues:THashedStringList;
  public
    constructor Create(AObjMgr:TObjMgr);
    function FindAValue(AName: string): PValue;
    procedure AddAValue(AName: string; AValue: TValue);
    function DelAValue(AName: string): PValue;
  end;
  TObjMgr = class
  public
    function DeleteAObject(AObj: TObj): Integer; overload;
    function DeleteAObject(AIndex: Integer): Integer; overload;
    procedure AddAObject(AObj: TObj);
  end;
var
  proplist: TStringList;


implementation

{ TObj }

procedure TObj.AddAValue(AName: string; AValue: TValue);
var
  I: Integer;
begin
  I := FValues.IndexOf(AName);
end;
constructor TObj.Create(AObjMgr: TObjMgr);
begin
  if Assigned(AObjMgr) then
    AObjMgr.AddAObject(Self);
  FValues := THashedStringList.Create;
end;

function TObj.DelAValue(AName: string): PValue;
var
  I: Integer;
begin
  I := FValues.IndexOf(AName);
  if I = -1 then
    Result := nil
  else
  begin
    FValues.Delete(I);
  end;
end;

function TObj.FindAValue(AName: string): PValue;
var
  I: Integer;
begin
  I := FValues.IndexOf(AName);
  if I = -1 then
    Result := nil
  else
    Result := PValue(FValues.Objects[I])
end;

{ TObjMgr }

procedure TObjMgr.AddAObject(AObj: TObj);
begin

end;

function TObjMgr.DeleteAObject(AObj: TObj): Integer;
begin

end;

function TObjMgr.DeleteAObject(AIndex: Integer): Integer;
begin

end;

initialization
  proplist := TStringList.Create;
finalization
  proplist.Free;

end.
