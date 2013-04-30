unit ucorefunc;

interface

procedure CoreWrite(I: integer); overload;
procedure CoreWrite(S: string); overload;
procedure CoreRead(var I: integer); overload;
procedure CoreRead(var S: string); overload;


implementation

procedure CoreWrite(I: integer);
begin
  Writeln(I);
end;

procedure CoreWrite(S: string);
begin
  Writeln(S);
end;

procedure CoreRead(var I: integer);
begin
  Read(I);
end;

procedure CoreRead(var S: string);
begin
  Read(S);
end;

end.
