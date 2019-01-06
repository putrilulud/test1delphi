unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, StdCtrls, Menus, ComCtrls, ExtCtrls, TeeProcs,
  Chart, ALBasicAudioOut, ALAudioOut, LPComponent, ALCommonPlayer,
  ALWavePlayer, Mask, math, XPMan;

type
  Twindow = (blackman, hanning, hamming, bartlett);
  T1dimensi = array of double;
  Tdatabobot= array of T1dimensi;
  T3dimensi = array of Tdatabobot;

  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    ALWavePlayer1: TALWavePlayer;
    ALAudioOut1: TALAudioOut;
    Chart1: TChart;
    RichEdit2: TRichEdit;
    GroupBox1: TGroupBox;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    StatusBar1: TStatusBar;
    File1: TMenuItem;
    BukaFile1: TMenuItem;
    AutoProcess1: TMenuItem;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Series1: TLineSeries;
    Label7: TLabel;
    RichEdit1: TRichEdit;
    ScrollBar1: TScrollBar;
    procedure BukaFile1Click(Sender: TObject);
    procedure AutoProcess1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ScrollBar1Scroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure RichEdit2Change(Sender: TObject);
    procedure RichEdit2KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  MATPHI=3.1415926535897932384626433832795;
  MAXDATA=144000;//15000 sampel
  UKURANFRAME=2048;
  FREKUENSI=48000;//12 KHz sample rate

var
  Form1: TForm1;
  maksuji,jumlahuji : longword;
  PosisiFile        : Byte;
  JData             : integer;
  Iterasi           : integer;
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

implementation
  uses Unit2, Unit3, Unit4, Fourier;
{$R *.dfm}


//prosedur BUATAN
//Open File Data

procedure BukaFileData(const namafile:string);
var
  F: File of Smallint;
  dumdata:Smallint;
  loop:longword;

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

//---------------------------------------------------------

procedure LaporkanKeMemo(const namafile:string);
begin
    with Form1, Memo1.Lines do
  begin
    Clear;
    Add('Buka File : '+namafile);
    Add('File Speech dengan Header File :');
    Add('- RIFF chunck');
    Add('- Mode Mono');
    Add('- 12 KHz sample rate');
    Add('- 16 bit signed data');
    Add('- 15000 sample data = 1.25 s');
  end;
end;

//---------------------------------------------------------

procedure GraphikkanKeWave;
var
  loop:longword;
begin
  with Form1, Series1 do
  begin
    Clear;
    for loop:=0 to MAXDATA-1 do
    Add(RealData[loop]);
  end;
end;

//---------------------------------------------------------

Procedure TampilkanProsess(proses:Byte);
var
  loop1:Byte;
  loop2:Byte;
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

//---------------------------------------------------------
//---------------------------------------------------------

procedure Preprocessing(sinyal:array of double);
var
  p:integer;
  i:integer;
  j:integer;
  win:array of double;
  aut:array of double;
  realtime:Tdatabobot;
  imgtime:Tdatabobot;
  realfrek:Tdatabobot;
  imgfrek:Tdatabobot;
  jumframe:integer;
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

//---------------------------------------------------------

function InitTarget(var target:Tdatabobot):integer;
var
  a:integer;
  b:integer;
  sisa:integer;
  ounit:integer;
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

//---------------------------------------------------------

function CekBobotAll(hiden_in,hiden:Tdatabobot; out_in,output:t1dimensi;
        target:Tdatabobot; jhiden:integer):boolean;
var
  i:integer;
  num:integer;
  kenal:integer;
  sum:double;
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
//---------------------------------------------------------
procedure InitTrain(var vbobotold:T3dimensi;var wbobotold:Tdatabobot;
        var hiden,hiden_in,eror_j:Tdatabobot;var output,out_in,eror_k:T1dimensi;
        ounit:integer);
var
  i:integer;
  j:integer;
  jhiden:integer;
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

//---------------------------------------------------------

function DoTrain:integer;
var
  vbobotold:T3dimensi;
  wbobotold:Tdatabobot;
  output:T1dimensi;
  out_in:T1dimensi;
  eror_k:T1dimensi;
  hiden:Tdatabobot;
  hiden_in:Tdatabobot;
  eror_j:Tdatabobot;
  target:Tdatabobot;
  loop:integer;
  num:integer;
  jhiden:integer;
  i:integer;
  j:integer;
  kenal:integer;
  ounit:integer;
  sum:double;
  sumall:double;
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
          CalculateHidenEror(eror_j[i],hiden_in[i-1],vbobot[i],eror_j[i-1]);

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
//---------------------------------------------------------
procedure InitRead(var hiden_in,hiden:Tdatabobot;
        var out_in,output:T1dimensi;ounit:integer);
var
  i:integer;

begin
  setlength(hiden,length(hunit));
  setlength(hiden_in,length(hunit));
  for i:=0 to high(hunit) do
  begin
    setlength(hiden[i],hunit[i]);
    setlength(hiden_in[i],hunit[i]);
    hiden[i,0]:=1;
  end;
  setlength(output,ounit);
  setlength(out_in,ounit);
end;
//---------------------------------------------------------
function GetDecision(output:T1dimensi; target:Tdatabobot):integer;
var
  i:integer;
  j:integer;
  sum:double;
  min_e:double;

begin
  min_e:=1000;
  result:=0;
  for i:=0 to high(target) do
  begin
    sum:=0;
    for j:=1 to high(target[i]) do
      sum:=sum+abs(output[j]-target[i,j]);
      if min_e>sum then
        begin
        result:=i;
        min_e:=sum;
      end;
    end;
end;

//AKHIR PROSEDUR BUATAN

procedure TForm1.Button1Click(Sender: TObject);
begin
  maksuji:=strtoint(ComboBox1.text); //maksuji = combobox1
  with OpenDialog1 do //komponen untuk membuka dialog / windows explorer
  begin
    Title:='Buka File Data'; //Nama Window
    Filter:='data File (*.wav)|*.wav'; //Filter data yang ditampilkan dalam bentuk wav
    DefaultExt:='wav'; //default ekstension = wav
    FileName:=''; //filename kosong
    InitialDir:=ExtractFileDir(ParamStr(0))+'\data'; //inisialdirektori didapat dari direktori data yg terakhir dibuka
    if Execute then //ketika klik open/OK
    begin
      inc(PosisiFile); //penomoran data yang telah dibuka/execute
      RichEdit1.Lines.Add(FileName);//menambahkan direktori dari filename
    end;
  end;
  jumlahuji:=jumlahuji+1; // jumlahuji=jumlahuji+1
  if jumlahuji = maksuji then //jumlahuji = maksuji
  begin
    Button1.Enabled:=false; // bukafile = disable
    Button2.Enabled:=true; // preproses = enable
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  a:integer;
  i:integer;
  j:integer;
  temp:TDataBobot;
  pan:integer;
  curr:integer;
  temps:string;

begin
  JData:=StrtoInt(ComboBox1.Text); //Jdata = Combobox1
  iterasi:=StrToInt(Edit1.Text); //iterasi = edit1
  Alpha:=StrToFloat(trim(Edit2.Text)); //alpha = edit2
  Miu:=StrtoFloat(trim(Edit3.Text)); //miu = edit3
  ErorMax:=StrtoFloat(trim(Edit4.Text));//erormax = edit4
  SetLength(StrIdentitas,JData); //stridentitas = jdata
  SetLength(HUnit,JumHidden); //hunit = jumhidden
  for a:=0 to JumHidden-1 do //looping jumhidden
    HUnit[a]:=HTemp[a]+1; //hunit[jumhidden] = htemp[jumhidden] +1
  setlength(temp,JData); //temp = jdata
  pan:=0; //panjang = 0
  for a:=0 to JData-1 do //looping Jdata (Jumlah Total Suara)
  begin
    BukaFileData(RichEdit1.Lines.Strings[a]); //Buka File Data
    temps:=copy(extractfilename(Form1.OpenDialog1.FileName),1,length(extractfilename(Form1.opendialog1.FileName))- length(extractfileext(Form1.opendialog1.FileName))); //temp = identitas file
    if not inputquery('Data Name','Nama Untuk Data ke '+inttostr(a+1),temps) then
      application.MessageBox(pchar('Anda tidak menekan tombol OK'
      +#13+'Character identified as '+temps),'Confirmation',mb_ok or mb_iconexclamation);
    StrIdentitas[a]:=temps; //Array dari StrIdentitas = temps
    pan:=max(pan,length(RealData)); //pan = nilai maksimal dari pan dan panjang realdata
    setlength(temp[a],length(RealData)); // temp[jdata] =  panjang realdata
    for i:=0 to high(RealData) do //looping realdata
      temp[a,i]:=RealData[i]; //temp[jdata, realdata] = realdata
  end;
  PanData:=pan; //pandata = pan
  for a:=0 to JData-1 do //looping jdata
  begin
    curr:=length(temp[a]); //curr = panjang temp[jdata]
    if curr<pan then //jika curr < pan
    begin
      setlength(temp[a],pan); //temp[jdata] = pan
      for i:=curr-1 to pan-1 do //looping curr s/d pan
        temp[a,i]:=2; //temp[jdata, curr] = 2
    end;
  end;
  setlength(Masuk,JData); //Masuk = Jdata
  for a:=0 to JData-1 do //looping Jdata
  begin
    setlength(Cep,0); //Cep = 0
    PreProcessing(temp[a]); //Procedure PreProcessing dari temp[jdata]
    IUnit:=length(Cep)*length(Cep[0])+1; //IUnit = panjang Cep * panjnag Cep[0] + 1
    setlength(Masuk[a],IUnit);// Masuk[Jdata] = Iunit
    Masuk[a,0]:=1; // Masuk [jdata,0] = 1
    for i:=0 to high(Cep) do //looping Cep
      for j:=0 to high(Cep[i]) do //Looping Cep[cep]
        Masuk[a,i*length(Cep[i])+j+1]:=Cep[i,j]; //Masuk[JData, Cep * panjang Cep[Cep]+j+i] = Cep [i,j]
  end;
  Button3.Enabled:=true;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  jumlahuji:=0;
  Button1.enabled:=true;
  Button2.enabled:=false;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  hasil:integer;
begin
  statusbar1.Panels[0].Text:='Training in Process...';
  hasil:=DoTrain;
  case hasil of
    1:MessageDlg('Maximum Iteration Reached',mtInformation,[mbOk],0);
    2:MessageDlg('All Data Can Be Identified', mtInformation,[mbOk],0);
  end;
  Button4.Enabled:=true;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  output:T1dimensi;
  out_in:T1dimensi;
  hiden:TDatabobot;
  hiden_in:TDatabobot;
  target:TDatabobot;
  i:integer;
  j:integer;
  jhiden:integer;
  curr:integer;
  ounit:integer;

begin
  BukaFile1.Click;
  ALWavePlayer1.FileName:=OpenDialog1.FileName;
  ALWavePlayer1.Enabled:=true;
  curr:=length(RealData);
  begin
    setlength(RealData,pandata);
    if curr<pandata then
      for i:=curr to pandata-1 do
      realdata[i]:=2;
  end;
  setlength(masuk,1);
  setlength(cep,0);
  PreProcessing(RealData);
  setlength(masuk[0],iunit);
  masuk[0,0]:=1;
  for i:=0 to high (Cep) do
    for j:=0 to high(Cep[i]) do
      masuk[0,i*length(cep[i])+j+1]:=cep[i,j];
      ounit:=InitTarget(target);
      InitRead(hiden_in,hiden,out_in,output,ounit);
      jhiden:=length(hunit);
      LayerIn(masuk[0],hiden_in[0],vbobot[0]);
      FungsiAktivasi(hiden_in[0],hiden[0]);
      if high(hunit)>0 then
        for i:=0 to high(hunit)-1 do
        begin
          LayerIn(hiden[i],hiden_in[i+1],vbobot[i+1]);
          FungsiAktivasi(out_in,output);
        end;
        LayerIn(hiden[jhiden-1],out_in,wbobot);
        FungsiAktivasi(out_in,output);
        i:=GetDecision(output,target);
        MessageDlg('Hasil Pengenalan '+StrIdentitas[i],mtInformation,[mbOk],0);
        Label7.Caption:=OpenDialog1.Filename+' adalah suara = '+ StrIdentitas[i];
        ALWavePlayer1.Enabled:=false;
end;

procedure TForm1.BukaFile1Click(Sender: TObject);
begin
  with OpenDialog1 do
  begin
    Title:='Buka File Data';
    Filter:='data File (*.wav)|*.wav';
    DefaultExt:='dat';
    FileName:='';
    InitialDir:=ExtractFileDir(ParamStr(0))+'\data';
    if Execute then
    begin
      BukaFileData(FileName);
      LaporkanKeMemo(FileName);
      GraphikkanKeWave;
    end;
  end;
  AutoProcess1.Enabled:=true;
end;

procedure TForm1.AutoProcess1Click(Sender: TObject);
begin
  PreProcessing(RealData);
end;

procedure TForm1.ComboBox2Change(Sender: TObject);
var
  a:integer;
  temp:string;
begin
  JumHidden:=strtoint(ComboBox2.Text); //JumHidden = ComboBox2
  setlength(HTemp,JumHidden); //HTemp = JumHidden
  for a:=0 to JumHidden-1 do  //Menentukan Jumlah Unit tiap JumHidden(Hidden Layer)
  begin
    temp:='25'; //temp = Variabel untuk input Jumlah Unit
    inputquery('Jumlah Unit Hiden Ke - '+inttostr(a+1),'Jumlah Unit : ', temp); //Popup pengisian Jumlah Unit
    HTemp[a]:=strtoint(temp); //Array HTemp[JumHidden] = Temp;
  end;
end;

procedure TForm1.ScrollBar1Scroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
var x : Integer;
begin
  ScrollBar1.Max := RichEdit2.Lines.Count;
  x := RichEdit2.CaretPos.x;
  RichEdit2.SetFocus;
  RichEdit2.Lines[ScrollPos] := RichEdit2.Lines[ScrollPos];
  RichEdit2.SelStart := RichEdit2.SelStart - Length(RichEdit2.Lines[ScrollPos]) + x;
end;


procedure TForm1.RichEdit2Change(Sender: TObject);
begin
  ScrollBar1.Max := RichEdit2.Lines.Count;
  ScrollBar1.Position := RichEdit2.CaretPos.y;
end;

procedure TForm1.RichEdit2KeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  ScrollBar1.Position := RichEdit2.CaretPos.y;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  ScrollBar1.Max := RichEdit2.Lines.Count;
  ScrollBar1.Position := ScrollBar1.Max;
end;

end.
