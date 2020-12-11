%OBJMODEL_ECV Build object model from ECV extracted
%                   primitives
%
%[ob] = objmodel_ecv(prims_,:)
%
% Forms a 3D object model from 3D ECV extracted
% primitives. Basically only stores XML information into a
% structure which is easier to manipulate in the later steps.
%
% NOTE: Everything assumes that only the line primitives are used,
% when new primitive types are added, this can completely break down.
%
% Output:
%   ob    - Object model structure (ECV primitives under .ecv)
%
% Input:
%  prims  - Extracted primitives as returned from
%           xmlReadPrimitives()
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
% See also XMLREADPRIMITIVES.M and RANSAC_MATCH_OBJMODEL_ECV.M .
%
function [ob] = objmodel_ecv(prims_,varargin);

% 1. Parse input arguments
conf = struct(...
    'loadColourCovariances', false,...
    'use2D',false,...
    'prims2D', [],...
    'method2D', 1,...
    'debugLevel', 0);
conf = mvpr_getargs(conf,varargin);

if conf.use2D && isempty(conf.prims2D)
  error(['In 2D mode the additional 2D primitives must be ' ...
           'provided!']);
end;

% Construct model of coordinates and corresponding features
ob.ecv.numOfPrimitives = length(prims_);
if (ob.ecv.numOfPrimitives <= 13)
  warning(['Only ' num2str(ob.ecv.numOfPrimitives) ' 3D primitives extracted!']);
end;
ob.ecv.numOfLinePrimitives = 0;
%ob.ecv.line_locations = nan(length(prims_),3); % number of line
                                                %primitives not known in advance
%ob.ecv.line_leftcolour = nan(length(prims_),3);
%ob.ecv.line_middlecolour = nan(length(prims_),3);
%ob.ecv.line_rightcolour = nan(length(prims_),3);
if (conf.loadColourCovariances) % Using these would be very slow
    %ob.ecv.line_leftColourCov = nan(length(prims_),3,3);
    %ob.ecv.line_middleColourCov = nan(length(prims_),3,3);
    %ob.ecv.line_rightColourCov = nan(length(prims_),3,3);
end;

% Store location coordinates and features (line primitives only)
if conf.use2D && conf.method2D == 2
  % Select the same number as 3D primitives but at least N proportion
  randInd = randperm(length(conf.prims2D));
  randInd = randInd(1:max([ob.ecv.numOfPrimitives,round(length(conf.prims2D)*0.8)]));
  for ii = 1:randInd
    ob.ecv.is2D = true;
    ob.ecv.numOfLinePrimitives = ob.ecv.numOfLinePrimitives+1;
    ob.ecv.line_locations(ob.ecv.numOfLinePrimitives,:) = ...
        [conf.prims2D(ii).x conf.prims2D(ii).y];
    ob.ecv.type(ii) = 'l';
    ob.ecv.line_leftcolour(ob.ecv.numOfLinePrimitives,:)   = ...
        conf.prims2D(ii).leftRGB;
    ob.ecv.line_middlecolour(ob.ecv.numOfLinePrimitives,:) = ...
        conf.prims2D(ii).middleRGB;
    ob.ecv.line_rightcolour(ob.ecv.numOfLinePrimitives,:)  = ...
        conf.prims2D(ii).rightRGB;
    end;
end;

if (conf.use2D == false) || (conf.use2D == true && conf.method2D == 1)
  for ii = 1:length(prims_)
    if (prims_(ii).type == 'l')
      if (~conf.use2D)
        ob.ecv.is2D = false;
        ob.ecv.numOfLinePrimitives = ob.ecv.numOfLinePrimitives+1;
        ob.ecv.line_locations(ob.ecv.numOfLinePrimitives,:) = prims_(ii).location.cartesian_coords;
        ob.ecv.type(ii) = prims_(ii).type;
        ob.ecv.line_leftcolour(ob.ecv.numOfLinePrimitives,:)   = prims_(ii).colors.left.rgb;
        ob.ecv.line_middlecolour(ob.ecv.numOfLinePrimitives,:) = prims_(ii).colors.middle.rgb;
        ob.ecv.line_rightcolour(ob.ecv.numOfLinePrimitives,:)  = prims_(ii).colors.right.rgb;
        if (conf.loadColourCovariances)
          ob.ecv.line_leftColourCov(ob.ecv.numOfLinePrimitives,:,:)   = prims_(ii).colors.left.covariance;
          ob.ecv.line_middleColourCov(ob.ecv.numOfLinePrimitives,:,:) = prims_(ii).colors.middle.covariance;
          ob.ecv.line_rightColourCov(ob.ecv.numOfLinePrimitives,:,:)  = prims_(ii).colors.right.covariance;
        end;
      else
        ob.ecv.is2D = true;
        % Select the corresponding 2D primitive in the left image
        % (First+1) (+1 since indeces start from 1 in Matlab and 0 in C)
        leftInd = prims_(ii).Source2D.First+1;
        ob.ecv.numOfLinePrimitives = ob.ecv.numOfLinePrimitives+1;
        ob.ecv.line_locations(ob.ecv.numOfLinePrimitives,:) = ...
            [conf.prims2D(leftInd).x conf.prims2D(leftInd).y];
        ob.ecv.type(ii) = prims_(ii).type;
        ob.ecv.line_leftcolour(ob.ecv.numOfLinePrimitives,:)   = ...
            conf.prims2D(leftInd).leftRGB;
        ob.ecv.line_middlecolour(ob.ecv.numOfLinePrimitives,:) = ...
            conf.prims2D(leftInd).middleRGB;
        ob.ecv.line_rightcolour(ob.ecv.numOfLinePrimitives,:)  = ...
            conf.prims2D(leftInd).rightRGB;
      end;
    else
      warning('ecv_primitive_objectmodel::wrong_primitive_type',...
              'Unsupported primitive type: ''%s''', ...
              prims_(ii).type);
    end;
  end;
end;

%% DEBUG 2 START %%%
if (conf.debugLevel > 1)
    clf;
    set(gca,'ZDir','reverse');
    set(gca,'YDir','reverse');
    hold on;
    for ii = 1:ob.ecv.numOfLinePrimitives
      if conf.use2D
        plotd = plot(ob.ecv.line_locations(ii,1), ob.ecv.line_locations(ii,2),'.','MarkerSize',20);
      else
        plotd = plot3(ob.ecv.line_locations(ii,1), ob.ecv.line_locations(ii,2), ob.ecv.line_locations(ii,3),'.','MarkerSize',20);
      end;
      set(plotd, 'Color',ob.ecv.line_rightcolour(ii,:));
    end;
    axis equal;
    if conf.use2D
      input('DEBUG[1]: Object model primitives plotted in 2D space <RET>');
    else
      input('DEBUG[1]: Object model primitives plotted in 3D space <RET>');
    end;
end;
%% DEBUG 2 END %%%
