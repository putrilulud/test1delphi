{$N+,E+}
{*Allow code to use type 'double', run on any iX86 machine *}
{$R-}
{* Turn off range checking... we violate array of bounds rules *}

unit Unit3;

interface

uses math, Unit1;

function LPCAnalisis(sinyal:array of double; framelength,p:integer;var a:array of double):integer;
function MakeOrder(BandWith:integer):integer;
procedure lpc2cepstral(p1,p2:integer;a:array of double;var c:array of double);
procedure weightingcepstral(p:integer;var c:array of double);

const M_PI:double=3.14159265358979323846;

implementation

function MakeOrder(BandWith:integer):integer;
begin
  result:=2*(BandWith div 1000+1);
end;

//---------------------------------------------------//
{
  fungsi autokorelasi untuk meminimalisasi mse dari LPC
  p->order dari prediksi
  r->koefisien autokorelasi
  frame_length->panjang frame
  sinyal->data sinyal
  hasil prosedur adalah
        KOEFISIEN AUTOKORELASI
}
//---------------------------------------------------//

procedure autocorelation(sinyal:array of double;frame_length:integer;p:integer;var r:array of double);
var
  a,b:integer;
  temp:double;
begin
  for a:=0 to p do
  begin
    temp:=0;
    for b:=0 to frame_length-1-a do
      temp:=temp+sinyal[b]*sinyal[b+a];
    r[a]:=temp;
  end;
end;

//---------------------------------------------------//
{
  fungsi untuk mencari koefisien prediksi dari LPC
  r -> koefisien autokorelasi
  p -> order dari prediksi
  eps -> singular check
  kp -> koefisien prediksi
  hasil fungsi adalah :
  0 -> normally completed
  1 -> abnormally completed
  2 -> unstable LPC
}
//---------------------------------------------------//

function CariKoefisienPrediksi(r:array of double; p:integer; eps:double; var kp:array of double):integer;
var
  rmd,mue:double;
  a,b,flag:integer;
  c: array of double;
begin
  flag := 0;
  setlength(c,p+1);
  if eps<0.0 then eps:=1.0e-6;
  rmd:=r[0];
  kp[0]:=0;
  for a:=1 to p do
  begin
    mue:=-r[a];
    for b:=1 to a-1 do
    mue:=mue-c[b]*r[a-b];
    mue:=mue/rmd;
    for b:=1 to a-1 do
      kp[b]:=c[b]+mue*c[a-b];
    kp[a]:=mue;
    rmd:=(1.0 - mue * mue)*rmd;
    if rmd<0 then
      rmd:=-rmd;
    if rmd<=eps then
    begin
      result:=1;
      exit;
    end;
    if mue<0 then
      mue:=-mue;
    if mue>=1 then
      flag:=2;
    for b:=0 to a do
      c[b]:=kp[b];
  end;
  kp[0]:=sqrt(rmd);
  result:=flag;
end;

function Gain(p:integer;a:array of double;r:array of double):double;
var
  b:integer;
  temp:double;
begin
  temp:=0;
  for b:=1 to p do
    temp:=temp+a[b]*r[b];
  temp:=r[0]-temp;
  result:=sqrt(temp);
end;

//---------------------------------------------------//
{
  prosedur untuk menganalisa LPC
  frame_length  -> panjang frame
  sinyal        -> data sinyal
  p             -> order dari LPC
  a             -> koefisien LPC
  hasilnya adalah apakah lpc kita stabil atau tidak
}
//---------------------------------------------------//

function LPCAnalisis(sinyal:array of double; framelength,p:integer; var a:array of double):integer;
var
  r:array of double;
  flag,b,c:integer;
  temp:double;
  sinpred:array of double;
begin
  setlength(r,p+1);
  setlength(sinpred,framelength);
  autocorelation(sinyal,framelength,p,r);
  flag:=CariKoefisienPrediksi(r,p,-1,a);
  for b:=1 to framelength-1 do
  begin
    temp:=0;
    for c:=1 to p do
      if b-c>=0 then
        temp:=temp+sinyal[b-c]*a[c];
    sinpred[b]:=temp;
  end;
  result:=flag;
end;

//---------------------------------------------------//
{
  prosedur untuk mencari koefisien cepstral
  p1  -> order dari lpc
  p2  -> order dari cepstral
  a   -> koefisien dari lpc
  c   -> koefisien dari cepstral
  hasilnya adalah koefisien cepstral -> c
}
//---------------------------------------------------//

procedure lpc2cepstral(p1,p2:integer; a:array of double; var c:array of double);
var
  i,j,k : integer;
  temp  : double;
begin
  c[0]:=log10(a[0]);
  c[1]:=-a[1];
  for i := 2 to p2 do
  begin
    j:=i;
    if i>p1 then k:=i-p1
    else k:=1;
    temp:=0;
    repeat
      temp:=temp+k*c[k]*a[i-k];
      inc(k);
    until
      k>=j;
    c[i]:=-temp/i;
    if i<=p1 then c[i]:=c[i]-a[i];
  end;
end;

//---------------------------------------------------//
{
  prosedur untuk pembobotan koefisien cepstral untuk mengurangi sensitivitas
  p -> order dari cepstral
  c -> koefisien dari cepstral
  hasilnya adalah koefisien cepstral yang telah di boboti -> c
}
//---------------------------------------------------//

procedure weightingcepstral(p:integer;var c:array of double);
var
  a:integer;
  w:array of double;
  arg:double;
begin
  setlength(w,p+1);
  arg:=M_PI/p;
  for a:=1 to p do
    w[a]:=1+(p/2)*sin(a*arg);
  for a:=1 to p do
    c[a]:=c[a]*w[a];
end;

end.
