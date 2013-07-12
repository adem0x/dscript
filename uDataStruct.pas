unit uDataStruct;

interface
uses
  Classes;
type
  PFreeData = ^TFreeData;
  TFreeData = record
    Index: Integer;
    Next: PFreeData;
  end;

  TStringData = record
    UnUsed: Boolean;
    Used: Boolean;
    Mark: Boolean;
    S: string;
  end;

  TQuickStringList = class
  private
    FList: array of TStringData;
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
    procedure Mark(AIndex: Integer);
    procedure Sweep();
  end;

  TQuickObjectList = class
  private
    FList: array of TObject;
    FListBufLen: Integer;
    FListCount: Integer;
    FFreeList: PFreeData;
    FBufAddLen: Integer;
    procedure CheckIndex();
  public
    constructor Create(ABufAddLen: Integer = 20);
    destructor Destroy; override;
    function Add(AObject: TObject): Integer;
    function Get(AIndex: Integer): TObject;
    function Delete(AIndex: Integer): Boolean;
    property Count: Integer read FListCount;
  end;

implementation

{ TDyStringList }

function TQuickStringList.Add(S: string): Integer;
var
  m_data: PFreeData;
begin
  if Assigned(FFreeList) then
  begin
    Result := FFreeList.Index;
    FList[Result].S := S;
    FList[Result].Used := True;
    m_data := FFreeList;
    FFreeList := FFreeList.Next;
    Dispose(m_data);
  end else
  begin
    CheckIndex;
    Result := FListCount;
    FList[Result].S := S;
    FList[Result].Used := True;
    Inc(FListCount);
  end;
end;

function TQuickStringList.AddStrings(AStringList: TStringList): Boolean;
var
  I, ret: Integer;
begin
  Result := False;
  if not Assigned(AStringList) then Exit;
  for I := 0 to AStringList.Count - 1 do
  begin
    ret := Self.Add(AStringList[I]);
    FList[ret].UnUsed := True;
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
    FList[AIndex].Mark := False;
    FList[AIndex].Used := False;
    New(m_data);
    m_data.Index := AIndex;
    m_data.Next := FFreeList;
    FFreeList := m_data;
  end;
end;

function TQuickStringList.Get(AIndex: Integer): string;
begin
  if AIndex < FListCount then
  begin
    Result := FList[AIndex].S;
    FList[AIndex].UnUsed := False;
  end;
end;

procedure TQuickStringList.Mark(AIndex: Integer);
begin
  if (AIndex < FListCount) and (FList[AIndex].Used) then
  begin
    FList[AIndex].Mark := True;
    Writeln('Mark: ', AIndex);
  end;
end;

procedure TQuickStringList.Sweep;
var
  I: Integer;
begin
  for I := 0 to FListCount - 1 do
  begin
    if FList[I].UnUsed then Continue;
    if (FList[I].Used) and (not FList[I].Mark) then
    begin
      Delete(I);
      Writeln('Sweep:', I);
    end
    else
      FList[I].Mark := False;
  end;

end;

{ TQuickObjectList }

function TQuickObjectList.Add(AObject: TObject): Integer;
var
  m_data: PFreeData;
begin
  if Assigned(FFreeList) then
  begin
    Result := FFreeList.Index;
    FList[Result] := AObject;
    m_data := FFreeList;
    FFreeList := FFreeList.Next;
    Dispose(m_data);
  end else
  begin
    CheckIndex;
    Result := FListCount;
    FList[Result] := AObject;
    Inc(FListCount);
  end;
end;

procedure TQuickObjectList.CheckIndex;
begin
  if FListCount >= FListBufLen then
  begin
    Inc(FListBufLen, FBufAddLen);
    SetLength(FList, FListBufLen);
  end;
end;

constructor TQuickObjectList.Create(ABufAddLen: Integer);
begin
  FListBufLen := 0;
  FListCount := 0;
  FFreeList := nil;
  FBufAddLen := ABufAddLen
end;

function TQuickObjectList.Delete(AIndex: Integer): Boolean;
var
  m_data: PFreeData;
begin
  Result := False;
  if AIndex < FListCount then
  begin
    FList[AIndex].Free;
    FList[AIndex] := nil;
    New(m_data);
    m_data.Index := AIndex;
    m_data.Next := FFreeList;
    FFreeList := m_data;
  end;
end;

destructor TQuickObjectList.Destroy;
var
  I: Integer;
  m_data: PFreeData;
begin
  for I := 0 to FListCount - 1 do
  begin
    if Assigned(FList[I]) then FList[I].Free;
  end;
  SetLength(FList, 0);
  while FFreeList <> nil do
  begin
    m_data := FFreeList;
    FFreeList := FFreeList.Next;
    Dispose(m_data);
  end;

  inherited;
end;

function TQuickObjectList.Get(AIndex: Integer): TObject;
begin
  if AIndex < FListCount then
  begin
    Result := FList[AIndex];
  end
  else
    Result := nil;
end;

end.

