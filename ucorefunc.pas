unit uCoreFunc;

interface
type
  TIO = class
    procedure CoreWrite(I: integer); overload; virtual; abstract;
    procedure CoreWrite(S: string); overload; virtual; abstract;
    procedure CoreRead(var I: integer); overload; virtual; abstract;
    procedure CoreRead(var S: string); overload; virtual; abstract;
  end;

  TConsoleIO = class(TIO)
    procedure CoreWrite(I: integer); overload; override;
    procedure CoreWrite(S: string); overload; override;
    procedure CoreRead(var I: integer); overload; override;
    procedure CoreRead(var S: string); overload; override;
  end;

procedure CoreWrite(I: integer); overload;
procedure CoreWrite(S: string); overload;
procedure CoreRead(var I: integer); overload;
procedure CoreRead(var S: string); overload;
var
  IO: TIO;

implementation

procedure CoreWrite(I: integer);
begin
  if Assigned(IO) then
    IO.CoreWrite(I)
end;

procedure CoreWrite(S: string);
begin
  if Assigned(IO) then
    IO.CoreWrite(S)
end;

procedure CoreRead(var I: integer);
begin
  if Assigned(IO) then
    IO.CoreRead(I)
end;

procedure CoreRead(var S: string);
begin
  if Assigned(IO) then
    IO.CoreRead(S)
end;

{ TConsoleIO }

procedure TConsoleIO.CoreRead(var I: integer);
begin
  inherited;
  Writeln(I);
end;

procedure TConsoleIO.CoreRead(var S: string);
begin
  inherited;
  Writeln(S);
end;

procedure TConsoleIO.CoreWrite(I: integer);
begin
  inherited;
  Writeln(I);
end;

procedure TConsoleIO.CoreWrite(S: string);
begin
  inherited;
  Writeln(S);
end;

end.
