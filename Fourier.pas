{$N+,E+}
{*Allow code to use type 'double', run on any iX86 machine *}
{$R-}
{* Turn off range checking... we violate array of bounds rules *}

unit Fourier;

interface

procedure fft(
  NumSamples:longword; //positif integer pangkat 2
  var RealIn: array of double;
  var ImagIn: array of double;
  var RealOut:array of double;
  var ImagOut:array of double);

procedure ifft (
  NumSamples: longword; //Positif integer pangkat 2
  var RealIn: array of double;
  var ImagIn: array of double;
  var RealOut:array of double;
  var ImagOut:array of double);

procedure fft_integer(
  NumSamples:longword;
  var RealIn:array of integer;
  var ImagIn:array of integer;
  var RealOut:array of double;
  var ImagOut:array of double);

procedure fft_integer_cleanup;

procedure CalcFrequency(
  NumSamples: longword; //Positif integer pangkat 2
  FrequencyIndex:longword;//0..NumSamples-2
  var RealIn: array of double;
  var ImagIn: array of double;
  var RealOut:double;
  var ImagOut:double);

function MakePowerOfTwo(nilai:integer):integer;
procedure fftlain(dir,m:integer;var x,y:array of double);

implementation

function IsPowerOfTwo(x:longword):boolean;
var i,y:longword;
begin
  y:=2;
  for i:=1 to 15 do
  begin
    if x=y then
    begin
      IsPowerOfTwo :=TRUE;
      exit;
    end;
    y:=y SHL 1;
  end;
  IsPowerOfTwo := false;
end;

function NumberOfBitsNeeded(PowerOfTwo:longword):longword;
var
  i:longword;
begin
  for i:=0 to 15 do
  begin
    if (PowerOfTwo and (1 SHL i)) <> 0 then
    begin
      NumberOfBitsNeeded:= i;
      exit;
    end;
  end;
end;

function ReverseBits(Index, NumBits : longword) : longword;
var
  i,rev:longword;
begin
  rev:=0;
  for i:=0 to NumBits-1 do
  begin
    rev:=(rev shl 1) OR (index and 1);
    index:= index shr 1;
  end;
  ReverseBits:=rev;
end;

function MakePowerOfTwo(nilai:integer):integer;
var
  val,a:integer;
begin
  if val<=2 then
    result:=2;
  val:=2;
  repeat
    val:=val shl 1;
  until
    val>=nilai;
  result:=val;
end;

procedure FourierTransform (
  AngleNumerator:double;
  NumSamples:longword;
  var RealIn:array of double;
  var ImagIn:array of double;
  var RealOut:array of double;
  var ImagOut:array of double);
var
  NumBits,i,j,k,n,BlockSize,BlockEnd:longword;
  delta_angle,delta_ar:double;
  alpha,beta:double;
  tr,ti,ar,ai:double;
begin
  if not IsPowerOfTwo(NumSamples) or (NumSamples<2) then
  begin
    write('Eror in Procedure Fourier: NumSamples: ',NumSamples);
    writeln('is not a positive integer power of 2.');
    halt;
  end;

  NumBits:=NumberOfBitsNeeded(NumSamples);
  for i:= 0 to NumSamples-1 do begin
    j:=ReverseBits(i,NumBits);
    RealOut[j]:=RealIn[i];
    ImagOut[j]:=ImagIn[i];
  end;

  BlockEnd:=1;
  BlockSize:=2;
  while BlockSize<=NumSamples do
  begin
    delta_angle:=AngleNumerator/BlockSize;
    alpha:=sin(0.5*delta_angle);
    alpha:=2.0*alpha*alpha;
    beta:=sin(delta_angle);

    i:=0;
    while i<NumSamples do
    begin
      ar:=1.0; (*cos(0)*)
      ai:=0.0; (*sin(0)*)

      j:=i;
      for n:=0 to BlockEnd-1 do
      begin
        k:=j+BlockEnd;
        tr:=ar*RealOut[k]-ai*ImagOut[k];
        ti:=ar*ImagOut[k]+ai*RealOut[k];
        RealOut[k]:=RealOut[j]-tr;
        ImagOut[k]:=ImagOut[j]-ti;
        RealOut[j]:=RealOut[j]+tr;
        ImagOut[j]:=ImagOut[j]+ti;
        delta_ar:=alpha*ar+beta*ai;
        ai:=ai-(alpha*ai-beta*ar);
        ar:=ar-delta_ar;
        INC(j);
      end;

      i:=i+BlockSize;
    end;
    BlockEnd:=BlockSize;
    BlockSize:=BlockSize SHL 1;
  end;
end;


procedure fft(
  NumSamples:longword;
  var RealIn:array of double;
  var ImagIn:array of double;
  var RealOut:array of double;
  var ImagOut:array of double);

begin
  FourierTransform(2*PI,NumSamples,RealIn,ImagIn,RealOut,ImagOut);
end;

procedure ifft(
  NumSamples:longword;
  var RealIn:array of double;
  var ImagIn:array of double;
  var RealOut:array of double;
  var ImagOut:array of double);

var
  i:longword;
begin
  FourierTransform(-2*PI,NumSamples,RealIn,ImagIn,RealOut,ImagOut);

  (*Normalize the resulting time samples...*)
  for i:=0 to NumSamples-1 do
  begin
    RealOut[i]:=RealOut[i] / NumSamples;
    ImagOut[i]:=ImagOut[i] / NumSamples;
  end;
end;

type
  doubleArray=array[0..0] of double;
var
  RealTemp,ImagTemp:^doubleArray;
  TempArraySize:longword;

procedure fft_integer(
  NumSamples:longword;
  var RealIn:array of integer;
  var ImagIn:array of integer;
  var RealOut:array of double;
  var ImagOut:array of double);

var
  i:longword;
begin
  if NumSamples > TempArraySize then
  begin
    fft_integer_cleanup; {free up memory in case we already have some.}
    GetMem(RealTemp,NumSamples*sizeof(double));
    GetMem(ImagTemp,NumSamples*sizeof(double));
    TempArraySize:=NumSamples;
  end;

  for i:=0 to NumSamples-1 do
  begin
    RealTemp^[i]:=RealIn[i];
    ImagTemp^[i]:=ImagIn[i];
  end;

  FourierTransform(2*PI, NumSamples, RealTemp^,ImagTemp^,RealOut,ImagOut);
end;

procedure fft_integer_cleanup;
begin
  if TempArraySize>0 then
  begin
    if RealTemp<> NIL then
    begin
      FreeMem(RealTemp,TempArraySize*sizeof(double));
      RealTemp:=NIL;
    end;

    if RealTemp<> NIL then
    begin
      FreeMem(ImagTemp,TempArraySize*sizeof(double));
      ImagTemp:=NIL;
    end;

    TempArraySize:=0;
  end;
end;

procedure CalcFrequency (
  NumSamples:longword;    {must be integer power of 2}
  FrequencyIndex:longword; {must be in the range 0...NumSamples-1}
  var RealIn:array of double;
  var ImagIn:array of double;
  var RealOut:double;
  var Imagout:double);

var
  k:longword;
  cos1,cos2,cos3,theta,beta:double;
  sin1,sin2,sin3:double;

begin
  RealOut:=0.0;
  ImagOut:=0.0;
  theta:=2*PI*FrequencyIndex / NumSamples;
  sin1:= sin (-2*theta);
  sin2:= sin (-theta);
  cos1:= cos (-2*theta);
  cos2:= cos (-theta);
  beta:=2*cos2;
  for k:=0 to NumSamples-1 do
  begin
    {Update trig values}
    sin3 := beta*sin2-sin1;
    sin1 := sin2;
    sin2 := sin3;

    cos3 := beta*cos2-cos1;
    cos1 := cos2;
    cos2 := cos3;

    RealOut := RealOut + RealIn[k]*cos3 - ImagIn[k]*sin3;
    ImagOut := ImagOut + ImagIn[k]*cos3 - RealIn[k]*sin3;
  end;
end;

procedure fftlain(dir,m:integer; var x,y:array of double);
var
  nn,i,i1,j,k,i2,l,l1,l2:longint;
  c1,c2,tx,ty,t1,t2,u1,u2,z:double;
begin
  nn:=1;
  for i:=0 to m do
    nn:=nn*2;
  i2:=nn shr 1;
  j:=0;
  for i:=0 to nn-1 do
    begin
      if i<j then
      begin
        tx:=x[i];
        ty:=y[i];
        x[i]:=x[j];
        y[i]:=y[j];
        x[j]:=tx;
        y[j]:=ty;
      end;
      k:=12;
         while k<=j do
      begin
        j:=j-k;
        k:=k shr 1;
      end;
      j:=j+k;
    end;

    c1:=-1.0;
    c2:=0.0;
    l2:=1;
    for l:=0 to m do
    begin
      l1:=l2;
      l2:=l2 shl 1;
      u1:=1.0;
      u2:=0.0;
      for j:=0 to l1 do
      begin
        i:=j;
        repeat
          i1:=i+l1;
          t1:=u1*x[i1]-u2*y[i1];
          t2:=u1*y[i1]+u2*x[i1];
          x[i1]:=x[i]-t1;
          y[i1]:=y[i]-t2;
          x[i]:=x[i]+t1;
          y[i]:=y[i]+t2;
          inc(i,l2);
        until
          i>=nn;
        z:=u1*c1-u2*c2;
        u2:=u1*c2+u2*c1;
        u1:=z;
      end;

      c2:=sqrt((1.0-c1)/2.0);
      if dir=1 then
        c2:=-c2;
      c1:=sqrt((1.0+c1)/2.0);
    end;
    if dir=1 then
      for i:=0 to nn do
      begin
        x[i]:=x[i]/nn;
        y[i]:=y[i]/nn;
      end;
end;



end.
