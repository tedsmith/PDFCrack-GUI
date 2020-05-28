{
The PDF Crack GUI interface and code are copyright (c) 2014-20, Ted Smith
The backend, which is 'pdfcrack', is copyright of Henning Norén
The intention of PDF Crack GUI is to compliment pdfcrack. It relies on pdfcrack entirely.
Any future development will be steered by any future development in pdfcrack.

Parts of pdfcrack.c and md5.c is derived/copied/inspired from
xpdf/poppler and are copyright 1995-2006 Glyph & Cog, LLC.

The PDF data structures, operators, and specification are
copyright 1985-2006 Adobe Systems Inc.

Project page for pdfcrack:     http://sourceforge.net/projects/pdfcrack/
Project page for pdfcrackGUI : http://sourceforge.net/projects/pdfcrackgui

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For a copy of the GNU General Public License, see <http://www.gnu.org/licenses/>.

}

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Spin, Menus, DateUtils, Unit2, BaseUnix;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnSelectPDF : TButton;
    btnCrackPDF: TButton;
    btnChooseWordListFile : TButton;
    btnStop : TButton;
    cbOverrideDefaultOptions: TCheckBox;
    cbWorkWithOwnerPassword: TCheckBox;
    cbWorkWithUserPassword: TCheckBox;
    cbPermutatePasswords: TCheckBox;
    edtCharacterOverride : TEdit;
    gbChangeOptions : TGroupBox;
    Label1: TLabel;
    lblPermutatePasswords: TLabel;
    ledtUserPasswordString: TLabeledEdit;
    lblWorkWithOwnerPassword: TLabel;
    lblProgressIndicator: TLabel;
    Label2 : TLabel;
    lblMaxLength : TLabel;
    lblMinLength : TLabel;
    lblWordListFileName : TLabel;
    MainMenu1 : TMainMenu;
    Memo1: TMemo;
    MenuItem1 : TMenuItem;
    MenuItem2 : TMenuItem;
    MenuItem3 : TMenuItem;
    OpenDialog1 : TOpenDialog;
    OpenDialog2 : TOpenDialog;
    Panel1: TPanel;
    Process: TProcess;
    SpinEdit_MaxLength : TSpinEdit;
    SpinEdit_MinLength : TSpinEdit;
    procedure btnChooseWordListFileClick(Sender : TObject);
    procedure btnSelectPDFClick(Sender : TObject);
    procedure btnCrackPDFClick(Sender: TObject);
    procedure btnStopClick(Sender : TObject);
    procedure cbOverrideDefaultOptionsChange(Sender: TObject);
    procedure cbWorkWithOwnerPasswordChange(Sender: TObject);
    procedure cbWorkWithUserPasswordChange(Sender: TObject);
    procedure cbPermutatePasswordsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem2Click(Sender : TObject);
    procedure MenuItem3Click(Sender : TObject);
    procedure SpinEdit_MinLengthChange(Sender : TObject);
    function SaveMemoToFile(Sender : TObject) : boolean;
  private
    NumBytes: LongInt;
    BytesRead: LongInt;
    MemStream: TMemoryStream;
    OutputLines : TStringList;
    pdfCrackProcess : TProcess;
    UseSavedState : boolean;
    procedure ShowAllLines;
  public
    { public declarations }
  end;

const
  READ_BYTES = 2048;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

// Specifies the resources to create on startup of the program
procedure TMainForm.FormCreate(Sender: TObject);
begin
  gbChangeOptions.Visible := false;

  if FileExists('pdfcrack') then
    begin
      MemStream := TMemoryStream.Create;
      OutputLines := TStringList.Create;
      btnCrackPDF.Enabled := false;
      btnChooseWordListFile.Enabled := true;
      btnChooseWordListFile.Visible := true;
    end
    else
      begin
        ShowMessage('Program "pdfcrack" was not found. Please download it from sourceforge.net/projects/pdfcrack');
      end;
end;

// Specifies the resources to free on exit of the program
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MemStream.Free;
  OutputLines.Free;
  pdfCrackProcess.Free;
end;

procedure TMainForm.MenuItem2Click(Sender : TObject);
begin
  Close;
end;

procedure TMainForm.MenuItem3Click(Sender : TObject);
begin
   frmAbout.Visible:= true;
end;

// Ensure the user cannot accidentally create a max length less than min length
// by linking min length to max length, but not visa versa, as max length needs to
// be able to be greater than min length.
procedure TMainForm.SpinEdit_MinLengthChange(Sender : TObject);
begin
  SpinEdit_MaxLength.Value := SpinEdit_MinLength.Value;
end;

// Specifies the input file to crack, as chosen by the user
procedure TMainForm.btnSelectPDFClick(Sender : TObject);
begin
  UseSavedState := false; // by default, don't pass savedstate option unless such a file exists
  Memo1.Clear;

  if OpenDialog1.Execute then
  begin
    if FileExists(OpenDialog1.Filename) then // To avoid selection even if cancel is clicked
    begin
      btnCrackPDF.Enabled := true;
      btnChooseWordListFile.Enabled := true;
      Memo1.Lines.Add(OpenDialog1.Filename + ' selected. Awaiting user to click Crack PDF button...');
    end;

    if FileExists('savedstate.sav') then
    begin
      if MessageDlg('Previously aborted decryption attempt detected. To resume it click [Yes], or to start new click [No]?', mtConfirmation,
      [mbYes, mbNo],0) = mrYes then UseSavedState := true;
    end;
  end;
end;

// Specified what Wordlist file (aka dictionary file) to use, if desired
procedure TMainForm.btnChooseWordListFileClick(Sender : TObject);
begin
   if OpenDialog2.Execute then
  begin
    if FileExists(OpenDialog2.Filename) then // To avoid selection even if cancel is clicked
    begin
      lblWordListFileName.Enabled := true;
      lblWordListFileName.Visible := true;
      lblWordListFileName.Caption := OpenDialog2.Filename;
      // We don't need to do anything else other than obtaining the filename of the wordlist
    end;
  end;
end;

// Passes the arguments from the interface to pdfcrack, runs pdfcrack and displays its output
procedure TMainForm.btnCrackPDFClick(Sender: TObject);
var
  StartDate, EndDate, TotalTimeTaken : TDateTime;
  StartDateFormatted, EndDateFormatted : string;
  ResultsSaved : boolean;
begin
  btnCrackPDF.Enabled  := False;
  btnSelectPDF.Enabled := False;
  ResultsSaved := false;
  BytesRead := 0;
  lblProgressIndicator.Caption := 'Progress will refresh here every few seconds....';
  Memo1.Lines.Add('User initiated processing. Will now start...');

  pdfCrackProcess := Process;
  pdfCrackProcess.Options := [poUsePipes];
  pdfCrackProcess.Executable := 'pdfcrack';
  pdfCrackProcess.Parameters.Add('-f');
  pdfCrackProcess.Parameters.Add(OpenDialog1.Filename);

  // Pass the min and max length arguments to pdfcrack, if specified,
  // i.e. if > than default value of 0

  // Pass the minimum password length value specified by the user
  if StrToInt(SpinEdit_MinLength.Caption) > 0 then
  begin
    pdfCrackProcess.Parameters.Add('-n');
    pdfCrackProcess.Parameters.Add(SpinEdit_MinLength.Caption);
    Memo1.Lines.Add('-- Options : Minimum password length specified: ' + SpinEdit_MinLength.Caption);
  end
  else Memo1.Lines.Add('-- Options : No minimum password length specified');

  // Pass the maximum password length value specified by the user
  if StrToInt(SpinEdit_MaxLength.Caption) > 0 then
  begin
    pdfCrackProcess.Parameters.Add('-m');
    pdfCrackProcess.Parameters.Add(SpinEdit_MaxLength.Caption);
    Memo1.Lines.Add('-- Options : Maximum password length specified: ' + SpinEdit_MaxLength.Caption);
  end
  else Memo1.Lines.Add('-- Options : No maximum password length specified');

  // Pass the wordlist properties supplied by the user to facilitate dictionary attack
  if FileExists(OpenDialog2.Filename) then
  begin
    pdfCrackProcess.Parameters.Add('-w');
    pdfCrackProcess.Parameters.Add(OpenDialog2.Filename);
    Memo1.Lines.Add('-- Options : Wordlist specified and to be used : ' + OpenDialog2.Filename);
  end
  else Memo1.Lines.Add('-- Options : Wordlist NOT specified. Brute force attack invoked.');

  // Pass the specified character ranges to include as supplied by the user
  if Length(edtCharacterOverride.Text) > 0 then
  begin
    pdfCrackProcess.Parameters.Add('-c');
    pdfCrackProcess.Parameters.Add(edtCharacterOverride.Text);
    Memo1.Lines.Add('-- Options : Using character range ' + edtCharacterOverride.Text);
  end
  else Memo1.Lines.Add('-- Options : Using default character range');

  // Pass the requirement to work with owner password, with or without supplying user password, added with pdfcrack v0.19 and pdfcrack-GUI v1.2
  if cbWorkWithOwnerPassword.Checked then
  begin
    if Length(ledtUserPasswordString.Caption) > 0 then
    begin
      pdfCrackProcess.Parameters.Add('-p');
      pdfCrackProcess.Parameters.Add(ledtUserPasswordString.Caption);
      Memo1.Lines.Add('-- Options : Working with owner password AND supplied userpassword of : ' + ledtUserPasswordString.Caption);
    end
    else
    begin
      pdfCrackProcess.Parameters.Add('-o');
      Memo1.Lines.Add('-- Options : Working with owner password without supplied userpassword');
    end;
  end
  else Memo1.Lines.Add('-- Options : Not working with owner password or any supplied user password');

  // Pass the requirement to work with user password, added with pdfcrack v0.19 and pdfcrack-GUI v1.2
  if cbWorkWithUserPassword.checked then
  begin
    pdfCrackProcess.Parameters.Add('-u');
    pdfCrackProcess.Parameters.Add(ledtUserPasswordString.Caption);
    Memo1.Lines.Add('-- Options : Working with user password (default)');
  end
  else Memo1.Lines.Add('-- Options : Not working with user password');

  // Pass the requirement to permutate user password, added with pdfcrack v0.19 and pdfcrack-GUI v1.2
  if cbPermutatePasswords.Checked then
  begin
    pdfCrackProcess.Parameters.Add('-s');
    Memo1.Lines.Add('-- Options : Will try permutating the passwords (currently only first character to uppercase)');
  end
  else Memo1.Lines.Add('-- Options : Will not attempt permutation of first password character');

  if UseSavedState = true then
  begin
    pdfCrackProcess.Parameters.Add('-l');
    pdfCrackProcess.Parameters.Add('savedstate.sav');
    Memo1.Lines.Add('-- Options : Resuming previous decryption attempt from savedstate.sav file.');
  end;

  Memo1.Lines.Add('-- Attempting to break ' + OpenDialog1.Filename);

  // Compute start timings

  StartDate := Now;
  StartDateFormatted := FormatDateTime('YYYY/MM/DD HH:MM:SS', StartDate);
  Memo1.Lines.Add('Start time : ' + StartDateFormatted);
  btnStop.Enabled := true;
  Application.ProcessMessages;

  // Start pdfCrack with the passed arguments

  pdfCrackProcess.Execute;

  // Catch the output of pdfcrack and refresh the interface

  while True do
  begin
    // make sure we have room
    MemStream.SetSize(BytesRead + READ_BYTES);

    // try reading it
    NumBytes := pdfCrackProcess.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
    if NumBytes > 0 then // All read() calls will block, except the final one.
    begin
      Application.ProcessMessages;
      //Get recent lines
      MemStream.Position := BytesRead;
      Inc(BytesRead, NumBytes);
      MemStream.SetSize(BytesRead);
      OutputLines.LoadFromStream(MemStream);
      lblProgressIndicator.Caption := OutputLines[OutputLines.Count-1];
      Application.ProcessMessages;
    end // End of Numbytes > 0 condition
    else
      begin
        lblProgressIndicator.Caption := OutputLines.Strings[OutputLines.Count - 1];
        BREAK; // Program has finished execution.
      end;
   end; // end of while

  MemStream.SetSize(BytesRead);
  ShowAllLines;
  Memo1.Lines.Add('-- Finished decryption attempt.');
  Memo1.Lines.Add('-- You can now close the program or choose another file');

  // Compute decryption time

  EndDate := Now;
  EndDateFormatted := FormatDateTime('YYYY/MM/DD HH:MM:SS', EndDate);
  Memo1.Lines.Add('End time : ' + EndDateFormatted);

  TotalTimeTaken := (EndDate - StartDate);
  Memo1.Lines.Add('Execution time : ' + TimeToStr(TotalTimeTaken));

  ResultsSaved := SaveMemoToFile(Memo1);
  if ResultsSaved = false then ShowMessage('Could not save message window to log file, for information');

  // Reset buttons for next run

  btnSelectPDF.Enabled          := True;
  btnCrackPDF.Enabled           := False;
  btnChooseWordListFile.Enabled := False;
  lblWordListFileName.Caption   := '';
  lblWordListFileName.Visible   := False;
  btnStop.Enabled               := false;
  Application.ProcessMessages;
end;

function TMainForm.SaveMemoToFile(Sender : TObject) : boolean;
var
  fs: TFileStream;
  strCompletionDateTimeValue : string;
begin
  result := false;
  strCompletionDateTimeValue := '';
  try
    strCompletionDateTimeValue := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
    fs := TFileStream.Create(strCompletionDateTimeValue + '-pdfcrackgui-results.txt', fmCreate);
    fs.Seek(0,fsFromEnd);
    Memo1.Lines.SaveToStream(fs);
  finally
    fs.Free;
    result := true;
  end;
end;
// Allow the user to abort the decryption effort
procedure TMainForm.btnStopClick(Sender : TObject);
begin

  { Though TProcess.Terminate is cross platform, AFAIK, you can't specifically send
   SIGINT to it, meaning that if compiled for Windows, we can't generate Ctrl+C SIGINT signal
   So it will abort pdfcrack, but it won't also generate a savedstate.sav file.
   In Linux though, we can achieve it using fpKill from BaseUnix unit.
  }
  {$ifdef UNIX}
    fpKill(pdfCrackProcess.ProcessID, SIGINT);
  {$endif}
  {$ifdef WIN}
    pdfCrackProcess.Terminate(pdfCrackProcess.ProcessID);
  {$endif}
  Memo1.Lines.Append('... Aborted by user ' + FormatDateTime('YYYY/MM/DD HH:MM:SS', Now));
end;

// Added in v1.2
procedure TMainForm.cbOverrideDefaultOptionsChange(Sender: TObject);
begin
  if cbOverrideDefaultOptions.Checked then gbChangeOptions.Visible := true
  else gbChangeOptions.Visible := false;
end;

// Added in v1.2
procedure TMainForm.cbWorkWithOwnerPasswordChange(Sender: TObject);
begin
  if cbWorkWithOwnerPassword.Checked = true then
  begin
    cbWorkWithOwnerPassword.Caption := 'Yes';
    ledtUserPasswordString.Visible  := true;
  end
  else
  begin
    cbWorkWithOwnerPassword.Caption := 'No';
    ledtUserPasswordString.Visible  := false;
  end;
end;

// Added in v1.2
procedure TMainForm.cbWorkWithUserPasswordChange(Sender: TObject);
begin
  if cbWorkWithUserPassword.checked = true then
  cbWorkWithUserPassword.Caption:= 'Yes' else cbWorkWithUserPassword.Caption:= 'No';
end;

// Added in v1.2
procedure TMainForm.cbPermutatePasswordsChange(Sender: TObject);
begin
  if cbPermutatePasswords.Checked = true then
  cbPermutatePasswords.Caption:= 'Yes' else cbPermutatePasswords.Caption := 'No';
end;

// Display output of completed pdfcrack
procedure TMainForm.ShowAllLines;
begin
  try
    Screen.Cursor:=crHourGlass;
    //Get all lines
    MemStream.Position := 0;
    OutputLines.LoadFromStream(MemStream);
    Memo1.Lines.AddStrings(OutputLines);
  finally
    Screen.Cursor:=crDefault;
  end;
end;

end.
