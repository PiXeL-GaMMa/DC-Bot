program dcbot;

uses
  Vcl.Forms,
  mainUnit in 'mainUnit.pas' {MainFRM};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFRM, MainFRM);
  Application.Run;
end.
