{$N+,E+}
{*Allow code to use type 'double', run on any iX86 machine *}
{$R-}
{* Turn off range checking... we violate array of bounds rules *}

unit Fourier;

interface

uses Math, Unit1;

{12. Fast Fourier Transform}
procedure fft (NumSamples: word; var RealIn: array of double; var ImagIn: array of double; var RealOut: array of double; var ImagOut: array of double);
{13. Fourier Transform}
procedure FourierTransform (AngleNumerator: double; NumSamples: word; var realIn: array of double; var ImagIn: array of double; var RealOut: array of double; var ImagOut: array of double);
{14. IsPowerOfTwo}
function IsPowerOfTwo (x: word): boolean;
{15. Number Of Bits Needed}
function NumberOfBitsNeeded(PowerOfTwo : word): word;
{16. Reverse Bits}
function ReverseBits (Index, NumBits: word): word;

implementation

{==============================================================================}
{==============================================================================}
{12. Fast Fourier Transform}
procedure fft (NumSamples: word; var RealIn: array of double; var ImagIn: array of double; var RealOut: array of double; var ImagOut: array of double);
begin
  FourierTransform(2*PI, NumSamples, RealIn, ImagIn, RealOut, ImagOut);
end;

{==============================================================================}
{==============================================================================}
{13. Fourier Transform}
procedure FourierTransform (AngleNumerator: double; NumSamples: word; var realIn: array of double; var ImagIn: array of double; var RealOut: array of double; var ImagOut: array of double);
var
  NumBits, i, j, k, n, BlockSize, BlockEnd: word;
  delta_angle, delta_ar: double;
  alpha, beta: double;
  tr, ti, ar, ai: double;

begin
  if not IsPowerOfTwo(NumSamples) or (NumSamples<2) then
  begin
    write('Error in Procedure Fourier: NumSamples: ', NumSamples);
    writeln('is not a positive integer power of 2');
    halt
  end;

  NumBits:=NumberOfBitsNeeded(NumSamples);
  for i:=0 to NumSamples-1 do
  begin
    j:=ReverseBits(i, NumBits);
    RealOut[j]:=RealIn[i];
    ImagOut[j]:=ImagIn[i];
  end;

  BlockEnd:=1;
  BlockSize:=2;
  while BlockSize <= NumSamples do
  begin
    delta_angle:= AngleNumerator/BlockSize;
    alpha:= sin(0.5 * delta_angle);
    alpha:= 2.0 * alpha * alpha;
    beta:= sin(delta_angle);

    i:=0;
    while i<NumSamples do
    begin
      ar:= 1.0; {cos 0}
      ai:= 0.0; {sin 0}

      j:=i;
      for n:=0 to BlockEnd-1 do
      begin
        k:= j + BlockEnd;
        tr:= ar * RealOut[k] - ai * ImagOut[k];
        ti:= ar * ImagOut[k] + ai *  RealOut[k];
        RealOut[k]:= RealOut[j] - tr;
        ImagOut[k]:= ImagOut[j] - ti;
        RealOut[j]:= RealOut[j] + tr;
        ImagOut[j]:= ImagOut[j] + ti;
        delta_ar:= alpha * ar + beta * ai;
        ar := ar - delta_ar;
        inc(j);
      end;

      i:= i + BlockSize;
    end;

    BlockEnd:= BlockSize;
    BlockSize:= BlockSize SHL 1;
  end;
end;

{==============================================================================}
{==============================================================================}
{14. IsPowerOfTwo}
function IsPowerOfTwo (x: word): boolean;
var
  i,y: word;

begin
  y:=2;
  for i:=1 to 15 do
  begin
   if x=y then
   begin
      IsPowerOfTwo:= TRUE;
      exit;
   end;

   y:= y SHL 1;
  end;
  IsPowerOfTwo := false;

end;

{==============================================================================}
{==============================================================================}
{15. Number Of Bits Needed}
function NumberOfBitsNeeded(PowerOfTwo : word): word;
var
  i: word;

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

{==============================================================================}
{==============================================================================}
{16. Reverse Bits}
function ReverseBits (Index, NumBits: word): word;
var
  i, rev: word;

begin
  rev:= 0;
  for i:=0 to NumBits-1 do
  begin
    rev:=(rev SHL 1) or (Index and 1);
    Index:= Index SHR 1;
  end;

  ReverseBits:= rev;
end;

end.
 
