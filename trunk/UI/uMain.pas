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
    Button1: TButton;
    procedure btnRunClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    FStop: Boolean;
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

  TExecThread = class(TThread)
  procedure Execute; override;
  constructor Create;
  end;

var
  Form1: TForm1;
  Source: PAnsiChar;
  gExec: TExec;
  gEmitter: TEmitter;
  gPropTable: TPropTable;
  gParser: TParser;
implementation

{$R *.dfm}

procedure TForm1.btnRunClick(Sender: TObject);
begin
  if mmoCode.Lines.Text <> '' then
  begin
    try
      FStop := True;              
      Button1.Caption := 'Stop!';
      Button1.Enabled := True;
      btnRun.Enabled := False;
      if Assigned(IO) then FreeAndNil(IO);
      if Assigned(gPropTable) then FreeAndNil(gPropTable);
      if Assigned(gExec) then FreeAndNil(gExec);
      if Assigned(gEmitter) then FreeAndNil(gEmitter);
      if Assigned(gParser) then FreeAndNil(gParser);
      IO := TFormIO.Create;
      gPropTable := TPropTable.Create;
      gExec := TExec.Create(gPropTable);
      gEmitter := TEmitter.Create(gExec, gPropTable);
      gEmitter.Opt := True;
      gParser := TParser.Create(gEmitter, gPropTable);
      gParser.Opt := True;
      Source := PAnsiChar(mmoCode.Lines.Text);
      if gParser.parser(Source) then
      begin
        gExec.Exec;
      end;
      btnRun.Enabled := True;
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
  Form1.mmoResult.Lines.Add(IntToStr(I));
  Application.ProcessMessages;
end;

procedure TFormIO.CoreWrite(S: string);
begin
  Form1.mmoResult.Lines.Add(S);
  Application.ProcessMessages;
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
  FStop := True;
  Dragacceptfiles(Form1.Handle,True);
  Button1.Enabled := False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(IO) then FreeAndNil(IO);
  if Assigned(gPropTable) then FreeAndNil(gPropTable);
  if Assigned(gExec) then FreeAndNil(gExec);
  if Assigned(gEmitter) then FreeAndNil(gEmitter);
  if Assigned(gParser) then FreeAndNil(gParser);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if not FStop then
  begin
    if gExec.Stoped then
    begin
      gExec.Stop := False;
      TExecThread.Create();
      btnRun.Enabled := False;
    end
  end else
  begin
    gExec.Stop := True;
    btnRun.Enabled := True;
  end;
  FStop := not FStop;
  if FStop then
    Button1.Caption := 'Stop!'
  else
    Button1.Caption := 'ReRun!'
end;
{ TExecThread }

constructor TExecThread.Create;
begin
  inherited Create(False);
  FreeOnTerminate := True;
end;

procedure TExecThread.Execute;
begin
  inherited;
  gExec.Exec;
end;

end.
