%READ_COVIS_STEREO_FILE Reads camera matrices in CoViS format file
%
% [sz_l K_l k_l R_l t_l] = readCoViSStereoCameraMatrix(fname_);
%
% Output:
%   sz_l - Image size [X Y] (left)
%   K_l  - Intrinsics matrix (left)
%   k_l  - Lens distortion parameters (left)
%   R_l  - Rotation matrix (left)
%   t_l  - Translation vector (left)
%
% Input:
%  fname_ - File to be read.
%
% Author(s):
%    Joni Kamarainen, CoViL in 2011.
%
% Project:
%  -
%
% Copyright:
%
%   Copyright (C) 2011-2012 by Cognitive Vision Laboratory,
%   SDU <norbert@mmmi.sdu.dk> and Joni Kamarainen <Joni.Kamarainen@lut.fi>
%
% References:
%  [1] Kamarainen, J.-K., Buch, A.G., Krueger, N., 3D Object Detection
%      Using Accumulated Early Vision Primitives, submitted.
%  [2] Hartley, R., and Zisserman, A., Multiple View Geometry in Computer
%      Vision, 2003.
%
% See also KIT_BBOX_DEMO.M and SHOW_OBJ_WITH_BBOX.M .
%
function [sz_l K_l k_l R_l t_l] = read_CoViS_stereo_file(fname_);

[fd errmsg] = fopen(fname_,'r');
if (fd == -1)
    error(['Cannot open: ' fname_]);
end;

% num of matrices
mnum = fscanf(fd,'%d',1);

% Left view matrix
sz_l = nan(1,2);
sz_l(1:2) = fscanf(fd,'%d',2);

K_l = nan(3,3);
K_l(1,:) = fscanf(fd,'%f',3);
K_l(2,:) = fscanf(fd,'%f',3);
K_l(3,:) = fscanf(fd,'%f',3);

k_l = nan(1,4);
k_l(1:4) = fscanf(fd,'%f',4);

R_l = nan(3,3);
R_l(1,:) = fscanf(fd,'%f',3);
R_l(2,:) = fscanf(fd,'%f',3);
R_l(3,:) = fscanf(fd,'%f',3);

t_l = nan(3,1);
t_l(1:3) = fscanf(fd,'%f',3);

fclose(fd);


