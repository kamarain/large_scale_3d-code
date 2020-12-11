%RANSAC_MATCH_OBJMODEL_ECV Ransac match ecv based object models
%
% [bestObjNum bestDist bestH] = ransac_match_objmodel_ecv(om_, ...
%
% This implements the main matching algorithm used in ref. [1] to
% match input models to models in the database.
%
% Output:
%
% Input:
% <Optional>
%  numOfBestHypotheses - How many best returned (def. 10)
%  randIters           - Num. or RANSAC iters (def. 1000)
%  useLineColour       - Use colour of line/edge primitives to find
%                        matches (def. true)
%  lineColourMatchMethod - Passed to match_matrix_ecv (def. 1)
%  useLocalDistanceHistograms - Use Anders' local distance
%                               histograms (def. false) NEEDS REIMPLEMENTATION
%  localDistanceHistogramMatchMethod - Passed to match_matrix_ecv
%                                      (def. 1)
%  fromObservationToModel - Every observation sample is used, but
%                           only their best matches from the model.
%                           Default: true, but vice versa could
%                           be useful in some situations?
%  locationDistanceMethod - How the match distances are summed
%                           1 - average Euc. distance
%                           2 - median Euc. distance (50% quantile) (Default)
%                           3 - 25% quantile value
%                           4 - 75% quantile value
%                           5 - 90% quantile value
%  posePrior              - Usage of pose prior in matching (Def. false)
%  UmeyamaScale           - Passed to hnd_corresp_umeyama()
%                           0 => similarity (also scale estimated)
%                           1 => isometry (fixed scale) (Default)
%  reEstimate             - Re-estimate best candidates by all
%                           inliers (Def. false)
%  reEstBest              - Proportion of the best points used in
%                           re-estimation (Def. 0.5 ~median)
%  debugLevel             - Select from [0,1,2]
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
% See also OBJMODEL_ECV.M and MATCH_MATRIC_ECV.M .
%
function [bestObjNum bestDist bestH] = ransac_match_objmodel_ecv(om_, tom_,varargin)

% 1. Parse input arguments
conf = struct(...
    'numOfBestHypotheses', 10,...
    'randIters', 1000,...
    'useLineColour',true,...
    'lineColourMatchMethod',1,...
    'useLocalDistanceHistograms',false,...
    'localDistanceHistogramMatchMethod',nan,...
    'fromObservationToModel',true,...
    'locationDistanceMethod',2,...
    'numOfBestMatches', 10,...
    'UmeyamaScale',1,...
    'reEstimate',false,...
    'reEstBest',0.5,...
    'posePrior', false,...
    'debugLevel', 0);
conf = mvpr_getargs(conf,varargin);

bestDist = inf(conf.numOfBestHypotheses,1);
if om_(1).ecv.is2D
  bestH = repmat(eye(3),[1 1 conf.numOfBestHypotheses]);
else
  bestH = repmat(eye(4),[1 1 conf.numOfBestHypotheses]);
end;
bestObjNum = nan(conf.numOfBestHypotheses,1);
for om_i = 1:length(om_) % test every model
    if (conf.fromObservationToModel)
        fromObj = tom_;
        toObj = om_(om_i);
    else
        fromObj = om_(om_i);
        toObj = tom_;
    end;

    [mm mm_mask] = match_matrix_ecv(fromObj, toObj,...
                                    'useLineColour',conf.useLineColour,...
                                    'lineColourMatchMethod',conf.lineColourMatchMethod,...
                                    'useLocalDistanceHistograms',conf.useLocalDistanceHistograms,...
                                    'localDistanceHistogramMatchMethod',conf.localDistanceHistogramMatchMethod,...
                                    'numOfBestMatches', conf.numOfBestMatches,...
                                    'debugLevel',conf.debugLevel);
   
    
    % generate a set of random indences for the model and the image
    % for very big conf.randIters this can explode (should then be
    % generated separately for every rand iter loop)
    % (isometry/similarity: 3)
    from_randinds = ceil((size(mm,1))*rand(conf.randIters,3));
    to_randinds = ceil((size(mm,2))*rand(conf.randIters,3));

    for ii = 1:conf.randIters
        % Estimate a transformation from model to observation using three random point correspondences (the minimum in 3D)
        H = ...
            mvpr_hnd_corresp_umeyama(...
                [toObj.ecv.line_locations(mm(from_randinds(ii,1),to_randinds(ii,1)),:);...
                 toObj.ecv.line_locations(mm(from_randinds(ii,2),to_randinds(ii,2)),:);...
                 toObj.ecv.line_locations(mm(from_randinds(ii,3),to_randinds(ii,3)),:)]',...
                [fromObj.ecv.line_locations(from_randinds(ii,1),:);...
                 fromObj.ecv.line_locations(from_randinds(ii,2),:);...
                 fromObj.ecv.line_locations(from_randinds(ii,3),:)]',conf.UmeyamaScale);
        if conf.posePrior
          % applying spatial prior
          if (sum(isnan(H)))
            continue;
          end;
          
          % Works only in 3D -
          H_translation = sqrt(H(1:3,4)'*H(1:3,4));
          A = H(1:2,1:2);
          [U_H S_H V_H] = svd(H(1:3,1:3));
          H_scale = S_H(1,1);
          R_H = U_H*V_H';
          detR_H = det(R_H);
          if abs(detR_H-1)<10^(-5)%det(R)==1
            if R_H(1,1)>0
              H_angle = asind(-R_H(1,2));
            else
              H_angle = 2*90*sign(asind(-R_H(1,2))) - asind(-R_H(1,2));
            end
          else
            warning('det not equal to 1');
          end
          %if (ii > 1) % at least one will be taken?!? (maybe incorrect)
          %if (H_scale < 0.5 || H_scale > 2)
          %  continue;
          %end;
          if (abs(H_angle) > 20)
            continue;
          end;
          if (H_translation > 9.5*10^8)
            continue;
          end;
          %end;
        end;

        toObj_fromCoords = mvpr_hnd_trans(toObj.ecv.line_locations',H)';
        
        % compute distances from every fromObj point to every toObj point
        dist = (repmat(fromObj.ecv.line_locations,[1 1 toObj.ecv.numOfLinePrimitives])-...
                repmat(shiftdim(toObj_fromCoords',-1), [fromObj.ecv.numOfLinePrimitives 1 1]));
        dist = squeeze(sum(dist.^2,2));

        % mask the best matches for every feature only
        dist(~mm_mask) = inf; 
        
        % Compute the distance between primitives
        if (conf.locationDistanceMethod == 1) % average
            [mindist] = sum(min(dist,[],2))/fromObj.ecv.numOfLinePrimitives;
        elseif (conf.locationDistanceMethod == 2) % median (best50%)
            [mindist] = median(min(dist,[],2));
        elseif (conf.locationDistanceMethod == 3) % best25%
            sorted_dists = sort(min(dist,[],2),1,'ascend');
            mindist = sorted_dists(round(0.25*length(sorted_dists)));
        elseif (conf.locationDistanceMethod == 4) % best75%
            sorted_dists = sort(min(dist,[],2),1,'ascend');
            mindist = sorted_dists(round(0.75*length(sorted_dists)));
        elseif (conf.locationDistanceMethod == 5) % best90%
            sorted_dists = sort(min(dist,[],2),1,'ascend');
            mindist = sorted_dists(round(0.90*length(sorted_dists)));
        end;

        % update if better
        betterInds = find(mindist < bestDist);
        if (~isempty(betterInds))
            % update infos
            bestObjNum(betterInds(1)+1:end) = bestObjNum(betterInds(1):end-1);
            bestObjNum(betterInds(1)) = om_i;
            bestDist(betterInds(1)+1:end) = bestDist(betterInds(1):end-1);
            bestDist(betterInds(1)) = mindist;
            bestH(:,:,betterInds(1)+1:end) = bestH(:,:,betterInds(1):end-1);
            bestH(:,:,betterInds(1)) = H;
            %% DEBUG 2 START %%%
            if (conf.debugLevel > 1 && betterInds(1) == 1)
                H
                clf;
                hold on;
                if (conf.fromObservationToModel) 
                  if om_(1).ecv.is2D
                    plot(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),'ko','MarkerSize',10);
                    plot(toObj_fromCoords(:,1), toObj_fromCoords(:,2),'rx','MarkerSize',10);
                  else
                    plot3(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),fromObj.ecv.line_locations(:,3),'ko','MarkerSize',10);
                    plot3(toObj_fromCoords(:,1), toObj_fromCoords(:,2), toObj_fromCoords(:,3),'rx','MarkerSize',10);
                  end;
                  else
                  if om_(1).ecv.is2D
                    plot(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),'rx','MarkerSize',10);
                    plot(toObj_fromCoords(:,1), toObj_fromCoords(:,2),'ko','MarkerSize',10);
                  else
                    plot3(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),fromObj.ecv.line_locations(:,3),'rx','MarkerSize',10);
                    plot3(toObj_fromCoords(:,1), toObj_fromCoords(:,2), toObj_fromCoords(:,3),'ko','MarkerSize',10);
                  end
                  end;
                fprintf('mod: %s (true is %s) iter: %d\n',om_(bestObjNum(1)).objName,tom_.objName,ii);
                input(['DEBUG[1]: Best hypohtesis updated - (black: ' ...
                       'observation) in 3D (or 2D) space <RET>']);
            end;
            %% DEBUG 2 END %%%
        end;
    end;
end;

% Re-estimate the best candidates
if (conf.reEstimate)
    if (conf.fromObservationToModel)
        for candInd = 1:conf.numOfBestHypotheses
            toObj = om_(bestObjNum(candInd));
            toObj_fromCoords = mvpr_hnd_trans(toObj.ecv.line_locations',bestH(:,:,candInd))';

            [mm mm_mask] = match_matrix_ecv(fromObj, toObj,...
                                            'useLineColour',conf.useLineColour,...
                                            'lineColourMatchMethod',conf.lineColourMatchMethod,...
                                            'useLocalDistanceHistograms',conf.useLocalDistanceHistograms,...
                                            'localDistanceHistogramMatchMethod',conf.localDistanceHistogramMatchMethod,...
                                            'numOfBestMatches', conf.numOfBestMatches,...
                                            'debugLevel',conf.debugLevel);

            % compute distances from every fromObj point to every toObj point
            dist = (repmat(fromObj.ecv.line_locations,[1 1 toObj.ecv.numOfLinePrimitives])-...
                    repmat(shiftdim(toObj_fromCoords',-1), [fromObj.ecv.numOfLinePrimitives 1 1]));
            dist = squeeze(sum(dist.^2,2));
            
            % mask the best matches for every feature only
            dist(~mm_mask) = inf; 
        
            % sort the distances to select only the best ones as
            % "inliers"
            [minDists minDistInds] = min(dist,[],2);
            [sorted_dists sorted_dists_inds ] = sort(minDists,1,'ascend');
            
            lastInd = round(conf.reEstBest*length(minDists));
            from_inlier_points = fromObj.ecv.line_locations(sorted_dists_inds(1:lastInd),:);
            to_inlier_points = toObj.ecv.line_locations(minDistInds(sorted_dists_inds(1:lastInd)),:);
        
            % new transformation
            H = mvpr_hnd_corresp_umeyama(to_inlier_points', ...
                                         from_inlier_points', conf.UmeyamaScale);
        
            toObj_fromCoords = mvpr_hnd_trans(toObj.ecv.line_locations',H)';
            % compute distances from every fromObj point to every toObj point
            dist = (repmat(fromObj.ecv.line_locations,[1 1 toObj.ecv.numOfLinePrimitives])-...
                    repmat(shiftdim(toObj_fromCoords',-1), [fromObj.ecv.numOfLinePrimitives 1 1]));
            dist = squeeze(sum(dist.^2,2));
            
            % mask the best matches for every feature only
            dist(~mm_mask) = inf; 
            
            % Compute the distance between primitives
            if (conf.locationDistanceMethod == 1) % average
                [mindist] = sum(min(dist,[],2))/fromObj.ecv.numOfLinePrimitives;
            elseif (conf.locationDistanceMethod == 2) % median (best50%)
                [mindist] = median(min(dist,[],2));
            elseif (conf.locationDistanceMethod == 3) % best25%
                sorted_dists = sort(min(dist,[],2),1,'ascend');
                mindist = sorted_dists(round(0.25*length(sorted_dists)));
            elseif (conf.locationDistanceMethod == 4) % best75%
                sorted_dists = sort(min(dist,[],2),1,'ascend');
                mindist = sorted_dists(round(0.75*length(sorted_dists)));
            end;
            
            % Update H and update distances
            bestDist(candInd) = mindist;
            bestH(:,:,candInd) = H;
        end;
        % re-sort after re-estimation
        [s sind] = sort(bestDist);
        if (conf.debugLevel > 0 && sind(1) > 1)
            disp('Best candidate updated after the re-estimation:');
            sind'
        end;
        bestDist = bestDist(sind);
        bestH = bestH(:,:,sind);
        bestObjNum = bestObjNum(sind);
        %% DEBUG 2 START %%%
        if (conf.debugLevel > 1)
            H
            clf;
            hold on;
            if (conf.fromObservationToModel) 
              if om_(1).ecv.is2D
                plot(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),'ko','MarkerSize',10);
                plot(toObj_fromCoords(:,1), toObj_fromCoords(:,2), 'rx','MarkerSize',10);
              else
                plot3(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),fromObj.ecv.line_locations(:,3),'ko','MarkerSize',10);
                plot3(toObj_fromCoords(:,1), toObj_fromCoords(:,2), toObj_fromCoords(:,3),'rx','MarkerSize',10);
              end;
            else
            if (conf.fromObservationToModel) 
              plot(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),'rx','MarkerSize',10);
              plot(toObj_fromCoords(:,1), toObj_fromCoords(:,2),'ko','MarkerSize',10);
            else
              plot3(fromObj.ecv.line_locations(:,1), fromObj.ecv.line_locations(:,2),fromObj.ecv.line_locations(:,3),'rx','MarkerSize',10);
              plot3(toObj_fromCoords(:,1), toObj_fromCoords(:,2), toObj_fromCoords(:,3),'ko','MarkerSize',10);
            end;
            end;
            fprintf('mod: %s (true is %s) iter: re-estimation\n',om_(bestObjNum(1)).objName,tom_.objName);
            input(['DEBUG[1]: Best hypohtesis updated - (black: ' ...
                   'observation) in 3D (or 2D) space <RET>']);
        end;
        %% DEBUG 2 END %%%
    else
        warning('Re-estimation to this direction not implemented!');
    end;
end;