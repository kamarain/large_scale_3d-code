%SHOW_OBJ_WITH_BBOX Shown output image and object bounding box
%
%[] = show_obj_with_bbox(img,bbox,sz,K)
%
% Shows image and plots left, right and frontal plances of the
% bounding box.
%
% NOTE: it is assumed that bbox 3D coordinates are given in camera
% frame, i.e. rotation and translation already applied (the default
% bbox save of render_3d_object).
%
%
% Output:
%   -
%
% Input:
%  img    - Image of an (KIT) object.
%  bbox   - 3xN Bounding box vertices.
%    sz   - Size of the image (should be the same of img, and if
%           not the code needs to be revised)
%     K   - Camera intrinsic matrics (ref. [2])
%
% Author(s):
%    Joni Kamarainen, CoViL in 2011-2012.
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
% See also KIT_BBOX_DEMO.M and READ_COVIS_STEREO_FILE.M .
%
function [] = show_obj_with_bbox(img,bbox,sz,K,varargin)

if nargin > 4
    showImg = varargin{1};
    plotCmnd = varargin{2};
else
    showImg = true;
    plotCmnd = 'g-';
end;

if (showImg)
    imagesc(img);
end;

% Transfor 3D VTK left camera frame coordinates to CoViS display
% coordinates (note that R and t have already being taken care of
% as the bbox saved by render_3d_object are in _camera_ _frame_
% already.
b_C = K*bbox;
b_D = b_C./repmat(b_C(3,:),[3 1]);

% Fix the origin from the top right to the top left
b_D(1,:) = sz(1)-b_D(1,:);

%hold on;
%for bind = 1:size(b_D,2)
%    plot(b_D(1,bind),b_D(2,bind),'go','MarkerSize',10,'LineWidth',2);
%end;
%hold off;

% Make line plots between correct vertices
clear v;
% Frontal plane
v(:,1)  = b_D(:,1); % xmin,ymin,zmin
v(:,2)  = b_D(:,2); % xmax,ymin,zmin
v(:,3)  = b_D(:,5); % xmax,ymax,zmin
v(:,4)  = b_D(:,3); % xmin,ymax,zmin
v(:,5)  = b_D(:,1); % xmin,ymin,zmin
% Right plane
v(:,6)  = b_D(:,4); % xmin,ymin,zmax
v(:,7)  = b_D(:,7); % xmin,ymax,zmax
v(:,8)  = b_D(:,3); % xmin,ymax,zmin
v(:,9)  = b_D(:,1); % xmin,ymin,zmin
%% Bottom plane
%v(:,10) = b_D(:,2); % xmax,ymin,zmin
%v(:,11) = b_D(:,6); % xmax,ymin,zmax
%v(:,12) = b_D(:,4); % xmin,ymin,zmax
%v(:,13) = b_D(:,1); % xmin,ymin,zmin
% Left plane
v(:,10) = b_D(:,2); % xmax,ymin,zmin
v(:,11) = b_D(:,5); % xmax,ymax,zmin
v(:,12) = b_D(:,8); % xmax,ymax,zmax
%v(:,13) = b_D(:,7); % xmin,ymax,zmax - one line to finish the back plane
%v(:,14) = b_D(:,8); % xmax,ymax,zmax - left plane continues
v(:,13) = b_D(:,6); % xmax,ymin,zmax
v(:,14) = b_D(:,2); % xmax,ymin,zmin


hold on;
plot([v(1,1)],[v(2,1)],'gd','LineWidth',2,'MarkerSize',10);
for bind = 1:size(v,2)-1
    plot([v(1,bind) v(1,bind+1)],[v(2,bind) v(2,bind+1)],plotCmnd,'LineWidth',2);
end;
hold off;

