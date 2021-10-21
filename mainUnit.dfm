object MainFRM: TMainFRM
  Left = 0
  Top = 0
  Caption = 'MainFRM'
  ClientHeight = 613
  ClientWidth = 926
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object memoLog: TMemo
    Left = 8
    Top = 8
    Width = 910
    Height = 545
    TabOrder = 0
  end
  object btnConnect: TButton
    Left = 8
    Top = 559
    Width = 105
    Height = 33
    Caption = 'Connect'
    TabOrder = 1
    OnClick = btnConnectClick
  end
end
