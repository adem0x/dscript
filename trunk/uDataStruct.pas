unit uDataStruct;

interface
uses
  Classes;
type
  PFreeData =^TFreeData;
  TFreeData= record
    Index: Integer;
    Next: PFreeData;
  end;

  TQuickStringList = class
  private
    FList: array of string;
    FListBufLen: Integer;
    FListCount: Integer;
    FFreeList: PFreeData;
    FBufAddLen: Integer;
    procedure CheckIndex();
  public
    constructor Create(ABufAddLen: Integer = 20);
    function Add(S: string): Integer;
    function Get(AIndex: Integer): string;
    function Delete(AIndex: Integer): Boolean;
    function AddStrings(AStringList: TStringList): Boolean;
  end;

implementation

{ TDyStringList }

function TQuickStringList.Add(S: string): Integer;
var
  m_data: PFreeData;
begin
  Result := -1;
  if Assigned(FFreeList) then
  begin
    Result := FFreeList.Index;
    FList[Result] := S;
    m_data := FFreeList;
    FFreeList := FFreeList.Next;
    Dispose(m_data);
  end else
  begin
    CheckIndex;
    Result := FListCount;
    FList[Result] := S;
    Inc(FListCount);
  end;
end;

function TQuickStringList.AddStrings(AStringList: TStringList): Boolean;
var
  I: Integer;
begin
  Result := False;
  if not Assigned(AStringList) then Exit;
  for I:= 0 to AStringList.Count - 1 do
  begin
    Self.Add(AStringList[I])
  end;
  Result := True;
end;

procedure TQuickStringList.CheckIndex();
begin
  if FListCount >= FListBufLen then
  begin
    Inc(FListBufLen, FBufAddLen);
    SetLength(FList, FListBufLen);
  end;
end;

constructor TQuickStringList.Create(ABufAddLen: Integer);
begin
  FListBufLen := 0;
  FListCount := 0;
  FFreeList := nil;
  FBufAddLen := ABufAddLen
end;

function TQuickStringList.Delete(AIndex: Integer): Boolean;
var
  m_data: PFreeData;
begin
  Result := False;
  if AIndex < FListCount then
  begin
    New(m_data);
    m_data.Index := AIndex;
    m_data.Next := FFreeList;
    FFreeList := m_data;
  end;
end;

function TQuickStringList.Get(AIndex: Integer): string;
begin
  if AIndex < FListCount then Result := FList[AIndex]
end;

end.
