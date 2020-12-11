%MATCH_MATRIX_ECV Match matrix between ECV primitives
%
%[mm,mm_mask] = match_matrix_ecv(om1_,om2_,varargin)
%
% For the ECV "primitives" (N in om1 and M in om2) this function
% constructs a match matrix of the size N x M where the matrix
% entries denote the match quality between each primitive (zero
% being the best value and Inf the worst). The function also
% returns a mask which is one only for the selected number of the
% best matches of each N (def. 10).
%
% NOTE: Utilisation of multiple feature types not implemented yet,
%       i.e. useLineColour=true and useLocalDistanceHistogram=true
%       will provide unpredictable results. These two distances
%       should be nicely combined if possible.
%
% Output:
%  mm      - N times M match matrix.
%  mm_mask - Mask of the best candidates in om2 for each primitive
%            in om1.
% Input:
%  om1_    - ECV based object model of N primitives
%  om2_    - ECV based object model of M primitives
% <Optional>
%  'useLineColour' - Colours of line/edge primitives used in
%                    matching (Def. true)
%  'lineColourMatchMethod' - Used method
%         1 - Left/middle/right colour diff. sum (L2 distance, no
%             normalisation) (Default)
%         2 - Left/middle/right colour diff. sum (Mahalanobis
%             distance, requires covariances, bloody slow) (NEEDS
%             TO BE FIXED)
%  'useLocalDistanceHistograms' - Local primitive distance
%                                 histograms used in matchin
%                                 (def. false) 
%  'localDistanceHistogramMatchMethod' -
%         1 - L2 distance, no normalisation. (Default) (NEEDS TO BE FIXED) 
%  'numOfBestMatches' - Number of matches for which the mask is
%                       positive (def. 10).
%  'debugLevel' - [0,1,2] (Def. 0)
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
% See also RANSAC_MATCH_OBJMODE_ECV.M .
%
function [mm,mm_mask] = match_matrix_ecv(om1_,om2_,varargin)

% 1. Parse input arguments
conf = struct(...
    'useLineColour', true,...
    'lineColourMatchMethod',1,...
    'useLocalDistanceHistograms', false,...
    'localDistanceHistogramMatchMethod', 1,...
    'numOfBestMatches', 10,...
    'debugLevel', 0);
conf = mvpr_getargs(conf,varargin);

% All match (no descriptors used)
if (~conf.useLineColour && ~conf.useLocalDistanceHistograms)
    error('All matching approaches distable, cannot produce anything useful!');
end;

% Compute distance matrices using user specified features and
% distance functions

% Using colours
if (conf.useLineColour)
    % Best match by colour 
    if (conf.lineColourMatchMethod == 1)
        % Compute colour distances: left/middle/right (covariance not used)
        distLeftColour = (repmat(om1_.ecv.line_leftcolour,[1 1 om2_.ecv.numOfLinePrimitives])-...
                          repmat(shiftdim(om2_.ecv.line_leftcolour',-1),[om1_.ecv.numOfLinePrimitives 1 1]));
        distLeftColour = squeeze(sum(distLeftColour.^2,2));
        distRightColour = (repmat(om1_.ecv.line_rightcolour,[1 1 om2_.ecv.numOfLinePrimitives])-...
                           repmat(shiftdim(om2_.ecv.line_rightcolour',-1),[om1_.ecv.numOfLinePrimitives 1 1]));
        distRightColour = squeeze(sum(distRightColour.^2,2));
        distMiddleColour = (repmat(om1_.ecv.line_middlecolour,[1 1 om2_.ecv.numOfLinePrimitives])-...
                            repmat(shiftdim(om2_.ecv.line_middlecolour',-1),[om1_.ecv.numOfLinePrimitives 1 1]));
        distMiddleColour = squeeze(sum(distMiddleColour.^2,2));
        dist = (distLeftColour+distRightColour+distMiddleColour)/3;

        [sortdist sortdistind] = sort(dist,2,'ascend');
        mm = sortdistind(:,1:min([size(sortdistind,2) conf.numOfBestMatches]));
        mm_mask = zeros(om1_.ecv.numOfLinePrimitives,om2_.ecv.numOfLinePrimitives);
        for ii = 1:om1_.ecv.numOfLinePrimitives
            mm_mask(ii,mm(ii,:)) = 1;
        end;
    end;
    
    % Best match by colour with covariance
    if (conf.lineColourMatchMethod == 2)
        error(['Current implementation needs to be re-checked and ' ...
               'anyway using covariances can be too slow for real ' ...
               'applications with many objects!']);
        % Take (fixed) covariances
        om1LeftCov = fix_covariance(om1_.feat_leftCov);
        om1middleCov = fix_covariance(om1_.feat_middleCov);
        om1rightCov = fix_covariance(om1_.feat_rightCov);
        
        om2LeftCov = fix_covariance(om2_.feat_leftCov);
        om2middleCov = fix_covariance(om2_.feat_middleCov);
        om2rightCov = fix_covariance(om2_.feat_rightCov);
        
        % Compute colour distances: left/middle/right (covariance not used)
        distLeft   = nan(size(om1_,1),size(om2_,1));
        distRight  = nan(size(om1_,1),size(om2_,1));
        distMiddle = nan(size(om1_,1),size(om2_,1));
        for om1i = 1:om1_.numOfPoints
            for om2i = 1:om2_.numOfPoints
                d = squeeze(om1_.feat_leftcolour(om1i,:)-om2_.feat_leftcolour(om2i,:))';
                P = squeeze((om1LeftCov(om1i,:,:)+om2LeftCov(om2i,:,:))/2);
                detP1 = det(squeeze(om1LeftCov(om1i,:,:)));
                detP2 = det(squeeze(om2LeftCov(om2i,:,:)));
                distLeft(om1i,om2i) = 1/8*d'*inv(P)*d+1/2*log(det(P)/sqrt(detP1+detP2));
            end;
        end;
        
        dist = real(distLeft);
        
        [sortdist sortdistind] = sort(dist,2,'ascend');
        mm = sortdistind(:,1:conf.matchNum);
        mm_mask = zeros(om1_.numOfPoints,om2_.numOfPoints);
        for ii = 1:om1_.numOfPoints
            mm_mask(ii,mm(ii,:)) = 1;
        end;
    end;
end;

% Using local histograms ("context")
if (conf.useLocalDistanceHistograms)
    error(['Not supported in the current re-implementation - needs ' ...
           'to be re-checked (with Anders in CoViL)']);
    % Best match by colour with covariance
    if (conf.method == 666)
        
        % Use Anders' provided code
        dist = hcosts(om1_.dHist, om2_.dHist,'Method','CumulativeEuclidean', 'Normalization', 'Relative');
        
        [sortdist sortdistind] = sort(dist,2,'ascend');
        mm = sortdistind(:,1:conf.matchNum);
        mm_mask = zeros(om1_.numOfPoints,om2_.numOfPoints);
        for ii = 1:om1_.numOfPoints
            mm_mask(ii,mm(ii,:)) = 1;
        end;
    end;
    
    % Best match by colour with covariance
    if (conf.method == 667)
        % Use Anders' provided code
        ddist = hcosts(om1_.dHist, om2_.dHist,'Method','CumulativeEuclidean', 'Normalization', 'Relative');
        cldist = hcosts(om1_.clHist, om2_.clHist,'Method','CumulativeEuclidean', 'Normalization', 'Relative');
        dist = ddist+cldist;
        
        [sortdist sortdistind] = sort(dist,2,'ascend');
        mm = sortdistind(:,1:conf.matchNum);
        mm_mask = zeros(om1_.numOfPoints,om2_.numOfPoints);
        for ii = 1:om1_.numOfPoints
            mm_mask(ii,mm(ii,:)) = 1;
        end;
    end;
end;

%%% INTERNALS
function [fixcov] = fix_covariance(cov_)

for covi = 1:size(cov_,1)
    C = squeeze(cov_(covi,:,:));
    fixinds = find(diag(C) == 0);
    for fixi = fixinds'
        C(fixi,fixi) = eps;
    end;
    fixcov(covi,:,:) = C;
end;
