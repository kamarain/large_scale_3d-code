%KIT_DEMO KIT Web Database 3D object model recognition demo
%
% Just type kit_database_demo in your Matlab prompt.
%
% This demo script was used to produce the experimental results in
% ref. [1]
%
% For this demo you need to:
%   * Extract primitives for the training set images (see ../Readme.txt)
%   * Extract primitives for the test set images (see ../Readme.txt)
%   * Give a properly written config file in KIT_CONFIG variable (see
%     kit_database_demo_conf.m.svn)
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
% See also KIT_BBOX_DEMO.M .
%
fprintf('-------------------------------------------\n');
fprintf('3D object recognition demo for objects in  \n');
fprintf('the KIT dataset                            \n');
fprintf('-------------------------------------------\n');

% Run the config script
if (exist('KIT_CONFIG','var'))
    fprintf(['Using user given config KIT_CONFIG=''' KIT_CONFIG ''' to read parameters...']);
    run(KIT_CONFIG);
    fprintf('...Done!!\n');
else
    fprintf('Loading parameters from kit_demo_conf.m...');
    run('./kit_demo_conf');
    fprintf('...Done!!\n');
end;

% Form the object database
if (~conf.skip_trainmodel)
    fprintf('[1] Reading training primitives and forming object models...\n');
    clear om;
    numOfClasses = mvpr_lcountentries(conf.tr_data_file,'comment','#%');
    fh = mvpr_lopen(conf.tr_data_file, 'read','comment','#%');
    for cInd = 1:numOfClasses
        fline = mvpr_lread(fh);
        fprintf(['\r Forming model %4d/%4d (' fline{3} ')                 '],cInd,numOfClasses);
        % Load and store 3D primitives by Slam
        prims = xmlReadPrimitives(...
            fullfile(conf.temp_dir,...
                     ['Slam_output_' fline{3}],...
                     ['primitives3D_' conf.slam_prim_file_id '.xml']));
        if (conf.use2DPrimitives)
          prims2D = read2DPrimitives(fullfile(conf.temp_dir,...
                                              ['Slam_output_' fline{3}],...
                                              ['primitives_left_' ...
                              conf.slam_2d_prim_file_id '.primitives'])); 
          omS = objmodel_ecv(prims,'use2D',conf.use2DPrimitives,'prims2D',prims2D,'method2D',conf.method2D,'debugLevel',conf.debugLevel);
        else
          omS = objmodel_ecv(prims,'debugLevel',conf.debugLevel);          
        end;

        % Additional fields for the experiments
        omS.objName = fline{3};
        trueClasses{cInd} = fline{3};
        % Load and store the bounding box
        bbox = load(fullfile(conf.temp_dir, [fline{3} '_render_bbox_vtk_left_camera_frame.dat']))';
        [sz K k R t] = read_CoViS_stereo_file(fullfile(conf.temp_dir,...
                                                       [fline{3} '_render_cam_mat_CoViS_canonic.dat']));
        omS.bbox = bbox;
        omS.K_left = K;
        if (conf.useLocalHists)
            % Error
            error(['Not implemented, should use Anders'' code to ' ...
                   'form histograms per primitive given primitive ' ...
                   'locations and colours.']);
            % This is how it was done in the stupid ref. [1] experiments
            %dHist = dlmread(fullfile(conf.hist_temp_dir,...
            %                         ['Slam_output_' fline{3}],...
            %                         ['dhist-' conf.histFilePostId '.txt']));
            %omS.dHist = dHist(:,4:end); % removed coordinates
        end;
        om(cInd) = omS;
    end;
    mvpr_lclose(fh);
    fprintf('[1] done!\n');
else
    fprintf('[1] Model training skipped!\n');
end;

if (~conf.skip_testing)
    numOfTestItems = mvpr_lcountentries(conf.te_data_file,'comment','#%');
    fprintf(['[2] Reading primitive test files and matching to database models...\n']);
    fh = mvpr_lopen(conf.te_data_file, 'read','comment','#%');
    if (exist(conf.testing_saveFile,'file') && conf.testing_continue)
        fprintf(' ===> CONTINUING INTERRUPTED TESTING!\n');
        confNew = conf;
        load(conf.testing_saveFile);
        cInd_cont = cInd;
        confInterrupted = conf;
        conf = confNew;
        clear confNew;
    else
        detClass = nan(numOfTestItems,1);
        trueClass = nan(numOfTestItems,1);
        cInd_cont = 0;
    end;

    for cInd = 1:numOfTestItems
        fline = mvpr_lread(fh);
        if (conf.testing_continue && cInd < cInd_cont) % skip until continuation point
            continue; % jump out from the for-loop
        end;
        fprintf(['\r Reading %4d/%4d (curr accuracy %f) %s'], cInd, numOfTestItems,...
                sum((detClass(1:cInd-1)-trueClass(1:cInd-1)) == 0)/(cInd-1),strtrim(fline{4}));
        prims = xmlReadPrimitives(...
            fullfile(conf.temp_dir,...
                     ['Slam_output_' fline{4}],...
                     ['primitives3D_' conf.slam_prim_file_id '.xml']));
        if (conf.use2DPrimitives)
          prims2D = read2DPrimitives(fullfile(conf.temp_dir,...
                                              ['Slam_output_' fline{4}],...
                                              ['primitives_left_' ...
                              conf.slam_2d_prim_file_id '.primitives'])); 
          tomS = objmodel_ecv(prims,'use2D',conf.use2DPrimitives,'prims2D',prims2D,'method2D',conf.method2D,'debugLevel',conf.debugLevel);
        else
          tomS = objmodel_ecv(prims,'debugLevel',conf.debugLevel);
        end;
        % Additional fields for the experiments
        tomS.objName = fline{5};
        % Load and store the bounding box
        bbox = load(fullfile(conf.temp_dir, fline{6}));
        [sz K k R t] = read_CoViS_stereo_file(fullfile(conf.temp_dir, fline{3}));
        tomS.bbox = bbox;
       
        tomS.K_left = K;
        if (conf.useLocalHists)
            error(['Not implemented, should use Anders'' code to ' ...
                   'form histograms per primitive given primitive ' ...
                   'locations and colours.']);
        end;
        
        % Match the object to the database
        [bestObjNum bestDist bestH] = ransac_match_objmodel_ecv(om,tomS,'debugLevel',conf.debugLevel);
        detClass(cInd) = bestObjNum(1);
        detH(:,:,cInd) = bestH(:,:,1);
        trueClass(cInd) = strmatch(tomS.objName,trueClasses,'exact');
    
        save(conf.testing_saveFile); % temporary save
        %% DEBUG 2 START ##
        if (conf.debugLevel >= 1)
            clf;
            dbg_img = imread(fullfile(conf.temp_dir, fline{1}));
            dbg_bbox = load(fullfile(conf.temp_dir, fline{6}))';
            dbg_bbox2 = om(bestObjNum(1)).bbox;
            dbg_bbox2H = mvpr_hnd_trans(dbg_bbox2,squeeze(bestH(:,:,2)));
            bestDist(1)
            [dbg_sz dbg_K dbg_k dbg_R dbg_t] = ...
                read_CoViS_stereo_file(fullfile(conf.temp_dir,fline{3}));
            show_obj_with_bbox(dbg_img,dbg_bbox,dbg_sz,dbg_K);
            show_obj_with_bbox(dbg_img,dbg_bbox2H,dbg_sz,dbg_K,false,'r-');
            title(fline{4},'interpreter','none');
            input(['[DEBUG 2] True and estimated bounding box (green ' ...
                   'is the ground truth) <RET>']);
        end;
        %% DEBUG 2 END ##
    end;
    mvpr_lclose(fh);
    fprintf([' => Final accuracy %f\n'],sum((detClass(1:cInd)-trueClass(1:cInd)==0))/cInd);
    fprintf('[1] done!\n');
    confMatr = zeros(max(trueClass));
    % Confusion matrix
    for coi1 = 1:max(trueClass)
        for coi2 = 1:max(trueClass)
            confMatr(coi1,coi2) = sum(detClass(find(coi1==trueClass))==coi2);
        end;
    end;
else
    fprintf('[1] Model testing skipped!\n');
end;
