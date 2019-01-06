{$N+,E+}
{*Allow code to use type 'double', run on any iX86 machine *}
{$R-}
{* Turn off range checking... we violate array of bounds rules *}

unit Unit4;

interface

uses math, Unit1;

procedure InisialisasiBobot(var vbobot:array of Tdatabobot; var wbobot:Tdatabobot);
procedure LayerIn (prev:array of double; var next:T1dimensi;bobot:Tdatabobot);
procedure FungsiAktivasi(inp:array of double; var hasil:array of double);
procedure CalculateOutputEror(target,output,out_in:array of double; var eror_k:array of double);
procedure CalculateHidenEror(eror_next,hiden_in:array of double;bobot:Tdatabobot; var eror_j:array of double);
procedure UpdateBobot(alpha,miu:double;eror_next,prev_data:array of double;var bobot,oldbobot:TDatabobot);

implementation

procedure RandomBobot(var bobot:Tdatabobot);
var
  a,b:integer;
begin
  for a:=0 to high(bobot) do
    for b:=0 to high(bobot[a]) do
      bobot[a,b]:=random-0.5;
end;

procedure NguyenWidrow(var bobot:tdatabobot);
var
  beta:double;
  a,b:integer;
  old:double;
  UnitInput,UnitHiden:integer;
begin
  UnitInput:=high(bobot);
  UnitHiden:=high(bobot[0]);
  beta:=0.7*(power(UnitHiden,1/UnitInput));
  for a:=1 to UnitHiden do
  begin
    old:=0;
    for b:=1 to UnitInput-1 do
      old:=old+sqr(bobot[b,a]);
    old:=sqrt(old);
    for b:=1 to UnitInput-1 do
      bobot[b,a]:=beta*bobot[b,a]/old;
    bobot[0,a]:=beta*(1-2*random);
  end;
end;

function sigmoid(nilai:real):real;
begin
  result:=1/(1+(exp(-nilai)));
end;

function TurunanSigmoid(nilai:real):real;
begin
  result:=sigmoid(nilai)*(1-sigmoid(nilai));
end;

procedure InisialisasiBobot(var vbobot:array of Tdatabobot;var wbobot:Tdatabobot);
var
  a:integer;
begin
  RandomBobot(vbobot[0]);
  NguyenWidrow(vbobot[0]);
  if high(vbobot)>0 then
    for a:=1 to high(vbobot) do
      RandomBobot(vbobot[a]);
  RandomBobot(wbobot);
end;

procedure LayerIn(prev:array of double;var next:T1dimensi;bobot:tdatabobot);
var
  a,b:integer;
begin
  for a:=1 to high(next) do
  begin
    next[a]:=bobot[0,a];
    for b:=1 to high(prev) do
      next[a]:=next[a]+bobot[b,a]*prev[b];
  end;
end;

procedure FungsiAktivasi(inp:array of double; var hasil:array of double);
var
  a:integer;
begin
  for a:=1 to high(hasil) do
    hasil[a]:=sigmoid(inp[a]);
end;

procedure CalculateOutputEror(target,output,out_in:array of double;var eror_k:array of double);
var
  a:integer;
begin
  for a:=1 to high(target) do
    eror_k[a]:= (target[a]-output[a])*TurunanSigmoid(out_in[a]);
end;

procedure CalculateHidenEror(eror_next,hiden_in:array of double; bobot:Tdatabobot; var eror_j:array of double);
var
  a,b:integer;
  eror_in:double;
begin
  for a:=1 to high(bobot) do
  begin
    eror_in:=0;
    for b:=1 to high(bobot[a]) do
      eror_in:=eror_in+eror_next[b]*bobot[a,b];
    eror_j[a]:=eror_in*TurunanSigmoid(hiden_in[a]);
  end;
end;

procedure UpdateBobot(alpha,miu:double; eror_next,prev_data:array of double; var bobot,oldbobot:Tdatabobot);
var
  a,b:integer;
  temp:Tdatabobot;
begin
  setlength(temp,high(bobot)+1);
  for a:=0 to high(bobot) do
  begin
    setlength(temp[a],high(bobot[a])+1);
    for b:=0 to high(bobot[a]) do
      temp[a,b]:=bobot[a,b]
  end;
  for a:=0 to high(bobot) do
    for b:=0 to high(bobot[a]) do
      bobot[a,b]:=bobot[a,b]+alpha*eror_next[b]*prev_data[a]+miu*(bobot[a,b]-oldbobot[a,b]);
  for a:=0 to high(bobot) do
    for b:=0 to high(bobot[a]) do
      oldbobot[a,b]:=temp[a,b];
end;



end.
