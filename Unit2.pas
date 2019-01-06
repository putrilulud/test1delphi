{$N+,E+}
{*Allow code to use type 'double', run on any iX86 machine *}
{$R-}
{* Turn off range checking... we violate array of bounds rules *}


unit Unit2;

interface

uses Math, Unit1;

function FrameCount(n,m,panjang:integer):integer;
procedure framing(n,m:integer;sinyal:array of double; var hasil:TDataBobot);
procedure pre_emphasis(koefisien:double;var sinyal:array of double);
procedure win_sinyal(nflg:integer;kode:twindow;var win:array of double);

const M_2PI:double=2*3.14159265358979323846;

implementation

function FrameCount(n,m,panjang:integer):integer;
var
  a:integer;
  jum:integer;
begin
  a:=0;
  jum:=0;
  repeat
    inc(jum);
    inc(a,n-m);
  until a> panjang;
    result:=jum;
end;

procedure framing(n,m:integer; sinyal: array of double; var hasil:Tdatabobot);
var
  panjang:integer;
  posisi:integer;
  a:integer;
  b:integer;
begin
  panjang:=high(sinyal)+1;
  posisi:=0;
  b:=0;
  repeat
    for a:=0 to n-1 do
      if posisi+a>=panjang then hasil [b,a] :=0
      else
        hasil[b,a]:=sinyal[posisi+a];
      inc(posisi,n-m);
      inc(b);
  until posisi>panjang;
end;

{
  prosedur pre-emphasis
  koefisien -> nilai dari penguatan berkisar antara 0.9 - 1
  sinyal -> sinyal yang akan dilakukan proses pre-emphasis
}

procedure pre_emphasis(koefisien:double;var sinyal:array of double);
var
  temp:array of double;
  a:integer;
begin
  setlength(temp,high(sinyal));
  for a:=1 to high(sinyal) do
    temp[a]:=sinyal[a]-koefisien*sinyal[a-1];
  for a:=1 to high(sinyal) do
    sinyal[a]:=temp[a];
end;

procedure hanning_win(var win:array of double);
var
  arg:double;
  a:integer;
  panjang:integer;
begin
  panjang:=high(win);
  arg:=M_2PI/panjang;
  for a:=0 to panjang do
    win[a]:=0.5*(1-cos(a*arg));
end;

procedure hamming_win(var win:array of double);
var
  arg:double;
  a:integer;
  panjang:integer;
begin
  panjang:=high(win);
  arg:=M_2PI/panjang;
  for a:=0 to panjang do
    win[a]:=0.54-0.46*cos(a*arg);
end;

procedure blackman_win(var win:array of double);
var
  arg:double;
  x:double;
  a:integer;
  panjang:integer;
begin
  panjang:=high(win);
  arg:=M_2PI/panjang;
  for a:=0 to panjang do
  begin
    x:=a*arg;
    win[a]:=0.42-0.5*cos(x)+0.08*cos(x+x);
  end;
end;

procedure bartlett_win(var win:array of double);
var
  a:integer;
  pan:integer;
  panjang:integer;
begin
  panjang:=high(win);
  pan:=panjang div 2;
  for a:=0 to pan-1 do
    win[a]:=2*a/pan;
  for a:=pan to panjang do
    win[a]:=2-2*a/pan;
end;

{
  prosedur windowing sinyal
  panjang -> panjang dari daerah yang akan di window
  nflg -> normalisasi flag
  0 -> tidak dinormalisasi
  1 -> normalisasi oleh power
  2 -> normalisasi oleh magnitude
  kode -> kode tipe window yang dipakai
  win -> koefisien hasil windowing
}

procedure win_sinyal(nflg:integer;kode:twindow;var win: array of double);
var
  a:integer;
  g:double;
  panjang:integer;
begin
  g:=1;
  panjang:=high(win);
  for a:=0 to panjang do
    win[a]:=0;
  case kode of
    blackman:blackman_win(win);
    hanning:hanning_win(win);
    hamming:hamming_win(win);
    bartlett:bartlett_win(win);
  end;
  case nflg of
    0: g:=1;
    1: begin
          g:=0;
          for a:=0 to panjang do
            g:=g+sqr(win[a]);
          g:=sqrt(g);
       end;
    2: begin
          g:=0;
          for a:=0 to panjang do
            g:= g+win[a];
       end;
  end;
  for a:=0 to panjang do
    win[a]:=win[a]/g;
end;
    
end.
