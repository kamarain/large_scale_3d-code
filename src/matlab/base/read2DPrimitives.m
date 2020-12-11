%READ2DPRIMITIVES Read extracted 2D primitives into Matlab structure
% 
% [primitives] = read2DPrimitives(primFile_)
%
% Primitives in the primFile_ is read to a Matlab
% structure array. It is assumed that the primitives are stored as
% described in
% CoViS/trunk/source/Features/{lineSegment2D.cpp,commonPrimitive2D.cpp}
% read() methods, e.g. (tot 34 in SVN revision 4488)
% <num_of_prims>
% <img_width> <img_height>
% <ind> <x-coord> <y-coord> <len> <conf> <confIDimg0C> <confIDim1C> \
%  <confIDim2C> <posCov11> <posCov12> <PosCov21> <PosCov22> \
%  <gAngleC> <gxC> <gyC> <thetab> <dThetaConfC> <or_VAR_C> <phaseC> \
%  <dPhaseConfC>  <colLeftR> <colLeftG> <colLeftB> <colConfleft> \
%  <colMidR> <colMidG> <colMidB> <colConfMid> <colRigR> <colRigG> \
%  <colRigB> <colConfRig> <u> <v>
%
% NOTE: The current version read only the following fields:
%       <ind> <x-coord< <y-coord> + colours of the left/righ/middle
%
% Output:
%   primitives  - Struct containing the primitives with their
%                 "attributes".
%
% Input:
%   primFile_  - Full path to the .primitives file generated by the
%                CoViS/Demos/Slam.
%
% Author(s):
%    Joni Kamarainen, CoVil in 2011-2012.
%
% Project:
%  Render3D
%
% References:
%
%  -
%
% Copyright:
%
%   Copyright (C) 2011 by Joni-Kristian Kamarainen (Joni.Kamarainen@lut.fi)
%
% See also XMLREAD.M .
%
function [primitives] = read2DPrimitives(primFile_)

fh = fopen(primFile_,'r');
if (fh == -1)
  error(['Cannot open ''' primFile_ ''' to read!']);
end;
numOfPrims = fscanf(fh, '%d',1);
imgWidth = fscanf(fh, '%d',1);
imgHeight = fscanf(fh, '%d',1);

for primInd = 1:numOfPrims
  primLine = fscanf(fh,'%f',34);
  if (length(primLine) ~= 34)
    error(['Mismatch in the number of elements in '...
           primFile_]);
  end;
  primitive.ind = primLine(1);
  primitive.x = primLine(2);
  primitive.y = primLine(3);
  primitive.leftRGB(1) = primLine(21);
  primitive.leftRGB(2) = primLine(22);
  primitive.leftRGB(3) = primLine(23);
  primitive.middleRGB(1) = primLine(25);
  primitive.middleRGB(2) = primLine(26);
  primitive.middleRGB(3) = primLine(27);
  primitive.rightRGB(1) = primLine(29);
  primitive.rightRGB(2) = primLine(30);
  primitive.rightRGB(3) = primLine(31);
  primitives(primInd) = primitive;
end;
fclose(fh);

% --------------------------------------------------------------------
% Internal functions

function pri = primitive_init()


pri = [];
