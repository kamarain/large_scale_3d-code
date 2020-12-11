temp_dir = '../TEMPWORK';
slam_prim_file_id = '0.7_0.1_4';

dbNum = 8;
tr_data_file = '../config/kit_5k_tex_first_12.txt';
teNum = (dbNum-1)*9+5;
te_data_file = '../kit-lut_EAZ_10_nozoom_test_set.txt';

invMatch = false;

old_dbNum = nan;
old_teNum = nan;

if ~(old_dbNum == dbNum && old_teNum == teNum) % nothing changed
old_dbNum = dbNum;
old_teNum = teNum;
    fprintf('Read database model...\n');
fh = mvpr_lopen(tr_data_file, 'read','comment','#%');
for cInd = 1:dbNum
    fline = mvpr_lread(fh);
end;
fline{3}
prims = xmlReadPrimitives(...
    fullfile(temp_dir,...
             ['Slam_output_' fline{3}],...
             ['primitives3D_' slam_prim_file_id '.xml']));
mvpr_lclose(fh);
omS = ecv_primitive_objectmodel(prims);
omS.objName = fline{3};
om(1) = omS;
fprintf('Done!\n');

fprintf('Read test model')
fh = mvpr_lopen(te_data_file, 'read','comment','#%');
for cInd = 1:teNum
    fline = mvpr_lread(fh);
end;
fline{3}
prims = xmlReadPrimitives(...
    fullfile(temp_dir,...
             ['Slam_output_' fline{5}],...
             ['primitives3D_' slam_prim_file_id '.xml']));
tomS = ecv_primitive_objectmodel(prims);
tomS.objName = fline{6};
mvpr_lclose(fh);
fprintf('Done!\n');
end;

fprintf('Find the best match')
[cInd cH] = ecv_match_objectmodel(om,tomS,'debugLevel',2,'matchNum',5,'distMethod',2,'revMatching',invMatch);
fprintf('Done!\n');

% Debug plot
clf;
img = imread(fullfile(temp_dir,fline{1}));
imagesc(img);

%% Load and plot ground truth
%genFile = fline{5};
%genFile = [genFile(1:end-5) 'vtkT' genFile(end-5:end)];
%vtkT = load(fullfile(temp_dir,genFile);
%bb = load('../bb_generated_el_-20.00_az_-20.00_zo_1.00.dat');
%
%plot_bb(vtkT,bb,'r-');

% Load original, transform and plot
genFile = fline{6};
genFile = [genFile '_generated_vtkT.dat'];
h_vtkT = load(fullfile(temp_dir,genFile));
genFile = fline{6};
genFile = [genFile '_generated_bb.dat'];
h_bb = load(fullfile(temp_dir,genFile));

cH_fiddle = eye(4);
cH_fiddle(1:3,1:3) = cH(1:3,1:3);
if (invMatch)
    plot_bb(h_vtkT*cH,h_bb,'g-',cH);
else
    plot_bb(h_vtkT*inv(cH),h_bb,'g-',cH);
end;

mc = load(fullfile(temp_dir,fline{3}));
Mc = [mc(1:4); mc(5:8); mc(9:12)]; 
plot_prims(tomS.coords',Mc,eye(4),'y.');
if invMatch
    plot_prims(omS.coords',Mc,cH,'g.');
else
    plot_prims(omS.coords',Mc,inv(cH),'g.');
end;
axis off;