program CryScript;

uses
  Forms,
  uMain in 'uMain.pas' {Form1},
  uPropTable in '..\uproptable.pas',
  uconst in '..\uconst.pas',
  uCoreFunc in '..\ucorefunc.pas',
  uDataStruct in '..\uDataStruct.pas',
  uEmitFuncMgr in '..\uEmitFuncMgr.pas',
  uEmitter in '..\uemitter.pas',
  uExec in '..\uexec.pas',
  uLex in '..\ulex.pas',
  uObjMgr in '..\uobjmgr.pas',
  uOptimizer in '..\uOptimizer.pas',
  uParser in '..\uparser.pas',
  MyContnrs in '..\mycontnrs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
