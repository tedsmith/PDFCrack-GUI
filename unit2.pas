unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    btnCloseAbout : TButton;
    Memo1 : TMemo;
    procedure btnCloseAboutClick(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAbout : TfrmAbout;

implementation

{$R *.lfm}

{ TfrmAbout }

procedure TfrmAbout.btnCloseAboutClick(Sender : TObject);
begin
  frmAbout.Close;
end;

end.

