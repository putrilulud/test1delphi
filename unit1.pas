unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, StdCtrls, Menus, ComCtrls, ExtCtrls, TeeProcs,
  Chart, ALBasicAudioOut, ALAudioOut, LPComponent, ALCommonPlayer,
  ALWavePlayer, Mask, math, XPMan, Buttons;


type
  Twindow=(blackman, hanning, hamming, bartlett);
  T1dimensi= array of double;
  Tdatabobot= array of T1dimensi;
  T3dimensi= array of Tdatabobot;

    TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    AutoProcess1: TMenuItem;
    AutoProcess2: TMenuItem;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    ALWavePlayer1: TALWavePlayer;
    ALAudioOut1: TALAudioOut;
    Chart1: TChart;
    RichEdit1: TRichEdit;
    RichEdit2: TRichEdit;
    GroupBox1: TGroupBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Series1: TLineSeries;
    StatusBar1: TStatusBar;
    Label7: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  MATPHI=3.1415926535897932384626433832795;
  MAXDATA=15000; //15k sample
  UKURANFRAME=2048;
  FREKUENSI=12000; //12 KHz sample rate

var
  Form1: TForm1;
  maksuji,jumlahuji : word;
  PosisiFile        : Byte;
  JData             : integer;
  iterasi           : integer;
  Alpha             : double;
  Miu               : double;
  ErorMax           : double;
  StrIdentitas      : array of string;
  HUnit             : array of integer;
  JumHidden         : Byte;
  HTemp             : array of integer;
  RealData          : array of double;
  PanData           : Integer;
  Masuk             : TDataBobot;
  Cep               : TDataBobot;
  IUnit             : Integer;
  wbobot            : TDataBobot;
  vbobot            : array of TDataBobot;

  {1. OPEN FILE DATA}
procedure BukaFileData(const namafile:string);
    {2. PRE-PROCESSING}
    procedure Preprocessing(sinyal: array of double);
    {3. Tampilkan Proses}
    procedure TampilkanProcess(proses: Byte);
    {22. Do Train}
    function DoTrain: integer;
    {23. Init Target}
    function InitTarget(var target: Tdatabobot): integer;
    {24. Init Train}
    procedure InitTrain (var vbobotold: T3dimensi; var wbobotold: Tdatabobot; var hiden, hiden_in, eror_j: Tdatabobot; var output, out_in, eror_k: T1dimensi; ounit: integer);
    {31. Cek Semua Bobot}
    function CekBobotAll(hiden_in, hiden: Tdatabobot; out_in, output: T1dimensi; target: Tdatabobot; jhiden: integer):boolean;
implementation
  uses Unit2, Fourier, Unit3, Unit4;
{$R *.dfm}

{PROSEDUR BUATAN}

{==============================================================================}
{==============================================================================}
{1. OPEN FILE DATA}
procedure BukaFileData(const namafile:string);
var
  F: File of Smallint;
  dumdata: Smallint;
  loop: word;
begin
  AssignFile(F,namafile);
 {$I-}

  Reset(F);
  Seek(F,0);
  SetLength(RealData, MAXDATA);
  for loop:=0 to MAXDATA-1 do
  begin
    Read(F,dumdata);
    RealData[loop]:=dumdata;
  end;

  CloseFile(F);
  {$I+}
end;

{==============================================================================}
{==============================================================================}
{3. Tampilkan Proses}
procedure TampilkanProcess(proses: Byte);
var
  loop1: Byte;
  loop2: Byte;

begin
  with Form1, RichEdit2.Lines do
  begin
    case proses of
    0: begin
         Clear;
         Add('PreProcessing : ');
       end;
    1: Add('Baca Data Sinyal Speech ...');
    2: Add('Framing Data ...');
    3: Add('PreEmphasis ...');
    4: Add('Windowing ...');
    5: Add('FFT ...');
    6: Add('LPC ...');
    7: Add('Cepstral ...');
    100: begin
          Add('SUKSES ...');
          Add('------------------------------------');
          Add('Jumlah Koefisien Cepstral : '+FloattoStr(high(Cep)+1));
          Add('Jumlah Frame :' + FloattoStr(high(Cep[1])+1));
          for loop1 := 0 to high(Cep) do
          begin
            Add('====================================');
            for loop2 := 0 to high(Cep[loop1]) do
              Add('Frame ['+InttoStr(loop2)+']'+'Coef ['+InttoStr(loop1)+']'+#9+ FloattoStr(Cep[loop1,loop2]));
          end;
         end;
    end;
  end;
end;

{==============================================================================}
{==============================================================================}

{2. PRE-PROCESSING}
procedure Preprocessing(sinyal: array of double);
var
  p: integer;
  i: integer;
  j: integer;
  win: array of double;
  aut: array of double;
  realtime: Tdatabobot;
  imgtime: Tdatabobot;
  realfrek: Tdatabobot;
  imgfrek: Tdatabobot;
  jumframe: integer;

begin
  TampilkanProsess(0);
  TampilkanProsess(1);
  jumframe:=FrameCount(UKURANFRAME, UKURANFRAME div 3,high(sinyal)+1);
  setlength(realtime,jumframe);
  setlength(imgtime,jumframe);
  setlength(realfrek,jumframe);
  setlength(imgfrek,jumframe);
  setlength(Cep,jumframe);
  TampilkanProsess(2);
  pre_emphasis(0.94,sinyal);
  setlength(realtime,jumframe);

  for i:=0 to jumframe-1 do
  begin
    setlength(realtime[i],UKURANFRAME);
    setlength(imgtime[i],UKURANFRAME);
    setlength(realfrek[i],UKURANFRAME);
    setlength(imgfrek[i],UKURANFRAME);
  end;
  TampilkanProsess(3);
  framing(UKURANFRAME,UKURANFRAME div 3, sinyal, realtime);
  TampilkanProsess(4);
  setlength(win,UKURANFRAME);
  win_sinyal(0,hanning,win);
  TampilkanProsess(5);

  for i:=0 to jumframe-1 do
    for j:=0 to UKURANFRAME-1 do
        realtime[i,j]:=realtime[i,j]*win[j];
  for i:=0 to jumframe-1 do
    fft(UKURANFRAME, realtime[i], imgtime[i],realfrek[i],imgfrek[i]);
  for i:=0 to jumframe-1 do
    for j:=0 to UKURANFRAME-1 do
      realfrek[i,j]:=sqrt(sqr(realfrek[i,j])+sqr(imgfrek[i,j]));
  TampilkanProsess(6);
  p:=MakeOrder(FREKUENSI);
  setlength(aut,p+1);
  for i:=0 to jumframe-1 do
  begin
    setlength(Cep[i],p+1);
    LPCAnalisis(realfrek[i],UKURANFRAME,p,aut);
    lpc2cepstral(p,p,aut,Cep[i]);
    weightingcepstral(p,Cep[i]);
  end;
  TampilkanProsess(7);
  TampilkanProsess(100);
end;

{==============================================================================}
{==============================================================================}
{22. Do Train}
function DoTrain: integer;
var
  vbobotold: T3dimensi;
  wbobotold: Tdatabobot;
  output: T1dimensi;
  out_in: T1dimensi;
  eror_k: T1dimensi;
  hiden: Tdatabobot;
  hiden_in: Tdatabobot;
  eror_j: Tdatabobot;
  target: Tdatabobot;
  num: integer;
  jhiden: integer;
  i: integer;
  j: integer;
  kenal: integer;
  ounit: integer;
  sum: double;
  sumall: double;
  loop: integer;

begin
  jhiden:=length(hunit);
  ounit:=InitTarget(target);
  InitTrain(vbobotold,wbobotold,hiden,hiden_in,eror_j,output,out_in,eror_k,ounit);
  for loop:=1 to iterasi do
  begin
    kenal:=0;
    sumall:=0;
    application.ProcessMessages;
    for num:=0 to high(masuk) do
    begin
      //feedforward process
      LayerIn(masuk[num],hiden_in[0],vbobot[0]);
      FungsiAktivasi(hiden_in[0],hiden[0]);
      if high(hunit)>0 then
        for i:=0 to high(hunit)-1 do
        begin
          LayerIn(hiden[i],hiden_in[i+1],vbobot[i+1]);
          FungsiAktivasi(hiden_in[i+1],hiden[i+1]);
        end;
      LayerIn(hiden[jhiden-1],out_in,wbobot);
      FungsiAktivasi(out_in,output);
      //cek target yang dicapai
      if loop mod 10=0 then
      begin
        sum:=0;
        for i:=1 to high(output) do
        sum:=sum+abs(output[i]-target[num,i]);
        sum:=sum/jdata;
        if sum<ErorMax then
        inc(kenal);
        sumall:=sumall+sum;
        Form1.statusbar1.Panels[1].Text:=' Data identify '+inttostr(kenal)+' from '
          +inttostr(jdata)+' at '+inttostr(loop)+' epoch';
        if num=high(masuk) then
        Form1.statusbar1.Panels[2].Text:='Error = '+floattostr(sumall/jdata);
        if kenal=jdata then
          if CekBobotAll(hiden_in,hiden,out_in,output,target,jhiden) then
          begin
            result:=2;
            exit;
          end;
      end;

      //backforward process
      CalculateOutputEror(target[num],output,out_in,eror_k);
      CalculateHidenEror(eror_k,hiden_in[jhiden-1],wbobot,eror_j[jhiden-1]);
      if high(hunit)>0 then
        for i:=high(hunit) downto 1 do
          CalculateHidenEror(eror_j[i],hiden_in[i-1],vbobot[i],eror_j[i-j]);

      //update bobot
      UpdateBobot(alpha,miu,eror_k,hiden[jhiden-1],wbobot,wbobotold);
      UpdateBobot(alpha,miu,eror_j[0],masuk[num],vbobot[0],vbobotold[0]);
      if high(hunit)>0 then
        for i:=high(hunit) downto 1 do
          UpdateBobot(alpha,miu,eror_j[i],hiden[i-1],vbobot[i],vbobotold[i]);
        end;
      end;
      result:=1;//normal exit
end;

{==============================================================================}
{==============================================================================}
{23. Init Target}
function InitTarget(var target: Tdatabobot): integer;
var
  a: integer;
  b: integer;
  sisa: integer;
  ounit: integer;

begin
  setlength(target,jdata);
  sisa:=jdata mod 3;
  if sisa<>0 then
   sisa:=1;
  ounit:=jdata div 3 +sisa+1;
  for a:=0 to jdata-1 do
  begin
    setlength(target[a],ounit);
    for b:=1 to ounit-1 do
      target[a,b]:=0.1;
    target[a,1+ a div 3]:=0.3+0.3*(a mod 3);
  end;
  result:=ounit;
end;

{==============================================================================}
{==============================================================================}
{24. Init Train}
procedure InitTrain (var vbobotold: T3dimensi; var wbobotold: Tdatabobot; var hiden, hiden_in, eror_j: Tdatabobot; var output, out_in, eror_k: T1dimensi; ounit: integer);
var
  i: integer;
  j: integer;
  jhiden: integer;
begin
  setlength(hiden,length(hunit));
  setlength(hiden_in,length(hunit));
  setlength(eror_j,length(hunit));
  for i:=0 to high(hunit) do
  begin
    setlength(hiden[i],hunit[i]);
    setlength(hiden_in[i],hunit[i]);
    setlength(eror_j[i],hunit[i]);
    hiden[i,0]:=1;
  end;
  setlength(output,ounit);
  setlength(out_in,ounit);
  setlength(eror_k,ounit);
  setlength(vbobot,length(hunit));
  setlength(vbobotold,length(hunit));
  setlength(vbobot[0],iunit);
  setlength(vbobotold[0],iunit);
  for i:=0 to iunit-1 do
  begin
    SetLength(vbobot[0,i], hunit[0]);
    SetLength(vbobotold[0,i], hunit[0]);
  end;

  if high(hunit)>0 then
    for i:=0 to high(hunit)-1 do
    begin
      SetLength(vbobot[i+1], hunit[i]);
      SetLength(vbobotold[i+1], hunit[i]);

      for j:=0 to hunit[i]-1 do
      begin
        SetLength(vbobot[i+1,j], hunit[i+1]);
        SetLength(vbobotold[i+1,j], hunit[i+1]);
      end;
    end;

  jhiden:= length(hunit);
  SetLength(wbobot, hunit[jhiden-1]);
  SetLength(wbobotold, hunit[jhiden-1]);

  for i:=0 to hunit[jhiden-1]-1 do
  begin
    SetLength(wbobot[i], ounit);
    SetLength(wbobotold[i], ounit);
  end;
  InisialisasiBobot(vbobot, wbobot);
end;


   { setlength(vbobot[i+1],hunit[i]);
    setlength(vbobotold[0,i],hunit[0]);
    for j:=0 to hunit[i]-1 do
    begin
      setlength(vbobot[i+1,j],hunit[i+j]);
      setlength(vbobotold[i+1,j],hunit[i+1]);
    end;
  end;
  jhiden:=length(hunit);
  setlength(wbobot,hunit[jhiden-1]);
  setlength(wbobotold,hunit[jhiden-1]);
  for i:=0 to hunit[jhiden-1]-1 do
  begin
    setlength(wbobot[i],ounit);
    setlength(wbobotold[i],ounit);
  end;
  InisialisasiBobot(vbobot,wbobot);
end;

{==============================================================================}
{==============================================================================}
{31. Cek Semua Bobot}
function CekBobotAll(hiden_in, hiden: Tdatabobot; out_in, output: T1dimensi; target: Tdatabobot; jhiden: integer):boolean;
var
  i: integer;
  num: integer;
  kenal: integer;
  sum: double;

begin
  result:= false;
  kenal:= 0;

  for num:=0 to high(masuk) do
  begin
    {Feedforward process}
    LayerIn(masuk[num], hiden_in[0], vbobot[0]);
    FungsiAktivasi(hiden_in[0], hiden[0]);
    if high(hunit)>0 then
      for i:=0 to high(hunit)-1 do
      begin
        LayerIn(hiden[i], hiden_in[i+1], vbobot[i+1]);
        FungsiAktivasi(hiden_in[i+1], hiden[i+1]);
      end;
      LayerIn(hiden[jhiden-1], out_in, wbobot);
      FungsiAktivasi(out_in, output);

      sum:=0;
      for i:=1 to high(output) do
        sum:= sum + abs(output[i] - target[num,i]);
      sum:= sum / jdata;
      if sum < ErorMax then
        inc(kenal);
  end;

  if kenal = jdata then
    result:= true;
end;


{==============================================================================}
{==============================================================================}
{PROSEDUR GUI}
{==============================================================================}
{==============================================================================}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  maksuji := strtoint(ComboBox1.Text);
  with OpenDialog1 do
  begin
    Title:='Buka File Data';
    Filter:='Data File (*.wav)|*.wav';
    DefaultExt:='wav';
    FileName:='';
    InitialDir:=ExtractFileDir(ParamStr(0))+'\data';
    if Execute then
    begin
      inc(PosisiFile);
      RichEdit1.Lines.Add(FileName);
    end;
  end;
  jumlahuji := jumlahuji+1;
  if jumlahuji = maksuji then
  begin
     BitBtn1.Enabled:=false;
    BitBtn2.Enabled:=true;
  end;
end;

{==============================================================================}
{==============================================================================}
procedure TForm1.BitBtn2Click(Sender: TObject);
var
  a:integer;
  i:integer;
  j:integer;
  temp:Tdatabobot;
  pan:integer;
  curr:integer;
  temps:string;

begin
  JData:=strtoint(ComboBox1.Text);
  iterasi:=strtoint(Edit1.Text);
  Alpha:=strtofloat(trim(Edit2.Text));
  Miu:=strtofloat(trim(Edit3.Text));
  ErorMax:=strtofloat(trim(Edit4.Text));
  SetLength(StrIdentitas,JData);
  SetLength(HUnit,JumHidden);

  for a:=0 to JumHidden-1 do
    HUnit[a]:=HTemp[a]+1;

  SetLength(temp,JData);
  pan:=0;

  for a:=0 to JData-1 do
  begin
    BukaFileData(RichEdit1.Lines.Strings[a]);
    temps:= copy(ExtractFileName(Form1.OpenDialog1.FileName),1,length(ExtractFileName(Form1.OpenDialog1.FileName))-length(ExtractFileExt(Form1.OpenDialog1.FileName)));

    if not inputquery('Data Name','Nama Untuk File Data ke '+inttostr(a+1),temps) then
      application.MessageBox(pchar('Anda Tidak Menekan Tombol OK'+#13+'Character Identified as '+temps),'Confirmation',mb_ok or mb_iconexclamation);

    StrIdentitas[a]:=temps;
    pan:=max(pan,length(RealData));
    SetLength(temp[a],length(RealData));

    for i:=0 to high(RealData) do
      temp[a,i]:=RealData[i];
  end;

  PanData:=pan;

  for a:=0 to JData-1 do
  begin
    curr:=length(temp[a]);
    if curr<pan then
    begin
      SetLength(temp[a],pan);
      for i:=curr-1 to pan-1 do
        temp[a,i]:=2;
    end;
  end;

  SetLength(Masuk,JData);
  for a:=0 to JData-1 do
  begin
    SetLength(Cep,0);
    PreProcessing(temp[a]);
    IUnit:=length(Cep)*length(Cep[0])+1;
    SetLength(Masuk[a],IUnit);
    Masuk[a,0]:=1;

    for i:=0 to high(Cep) do
      for j:=0 to high(Cep[i]) do
        Masuk[a,i*length(Cep[i])+j+1]:=Cep[i,j];
  end;

  BitBtn3.Enabled:=true;

end;

{==============================================================================}
{==============================================================================}
procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  jumlahuji:=0;
  BitBtn1.Enabled:=true;
  BitBtn2.Enabled:=false;
end;
{==============================================================================}
{==============================================================================}
procedure TForm1.BitBtn3Click(Sender: TObject);
var
  hasil: integer;

begin
  StatusBar1.Panels[0].Text:= 'Training in Process...';
  hasil:= DoTrain;
  case hasil of
    1: MessageDlg('Maksimum Iteration Reached', mtInformation,[mbOk],0);
    2: MessageDlg('All Data Can Be Identified',mtInformation,[mbOk],0);
  end;

  BitBtn4.Enabled:= true;
end;

end.
