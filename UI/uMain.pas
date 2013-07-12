unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI,
  uPropTable ,
  uCoreFunc,
  uEmitter,
  uExec,
  uParser;

type
  TForm1 = class(TForm)
    mmoCode: TMemo;
    mmoResult: TMemo;
    btnRun: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    procedure btnRunClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  procedure DropFiles(var message:Tmessage);message wm_dropfiles;
  end;

  TFormIO = class(TIO)
    procedure CoreWrite(I: integer); overload; override;
    procedure CoreWrite(S: string); overload; override;
    procedure CoreRead(var I: integer); overload; override;
    procedure CoreRead(var S: string); overload; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnRunClick(Sender: TObject);
var
  Source: PAnsiChar;
  gExec: TExec;
  gEmitter: TEmitter;
  gPropTable: TPropTable;
  gParser: TParser;
begin
  if mmoCode.Lines.Text <> '' then
  begin
    try
      Source := PAnsiChar(mmoCode.Lines.Text);
      IO := TFormIO.Create;
      gPropTable := TPropTable.Create;
      gExec := TExec.Create(gPropTable);
      gEmitter := TEmitter.Create(gExec, gPropTable);
      gEmitter.Opt := True;
      gParser := TParser.Create(gEmitter, gPropTable);
      gParser.Opt := True;
      if gParser.parser(Source) then
      begin
        gExec.Exec;
      end;
      gExec.Free;
      gEmitter.Free;
      gPropTable.Free;
      gParser.Free;
      IO.Free;
    except
      on E: Exception do
        ShowMessage(E.ClassName + ': ' + E.Message);
    end;

  end;
end;

{ TFormIO }

procedure TFormIO.CoreRead(var I: integer);
begin
  I := StrToInt(Form1.Edit1.Text);
end;

procedure TFormIO.CoreRead(var S: string);
begin
  S := Form1.Edit1.Text;
end;

procedure TFormIO.CoreWrite(I: integer);
begin
  Form1.mmoResult.Lines.Add(IntToStr(I))
end;

procedure TFormIO.CoreWrite(S: string);
begin
  Form1.mmoResult.Lines.Add(S)
end;

procedure TForm1.DropFiles(var message: Tmessage);
var
  p:array[0..254] of AnsiChar;
  S: AnsiString;
  i:word;
  buf: PAnsiChar;
begin
// 取拖下文件的数量
  I:= dragqueryfile(message.wparam,$ffffffff,nil,0);
  if I > 1 then
  begin
    ShowMessage('请只拖动一个文件');
    Exit;
  end;
  dragqueryfile(message.wparam,I - 1, p ,255);
  S := P;
  if FileExists(S) then
  begin
    with TMemoryStream.Create do
    begin
      LoadFromFile(S);
      GetMem(buf, Size + 1);
      Read(buf^, Size);
      buf[Size] := #0;
      mmoCode.Lines.SetText(buf);
      FreeMem(buf);
      Free;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Dragacceptfiles(Form1.Handle,True);
end;

end.
