object Form1: TForm1
  Left = 272
  Top = 216
  Width = 979
  Height = 563
  Caption = 'CryScript'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 432
    Top = 8
    Width = 36
    Height = 13
    Caption = #36755#20837#65306
  end
  object mmoCode: TMemo
    Left = 0
    Top = 0
    Width = 401
    Height = 529
    Align = alLeft
    HideSelection = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object mmoResult: TMemo
    Left = 656
    Top = 0
    Width = 315
    Height = 529
    Align = alRight
    HideSelection = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object btnRun: TButton
    Left = 424
    Top = 336
    Width = 203
    Height = 73
    Caption = 'Run!'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = btnRunClick
  end
  object Edit1: TEdit
    Left = 432
    Top = 32
    Width = 193
    Height = 21
    TabOrder = 3
  end
end
