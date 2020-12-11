function [] = plot_bb(vtkT,bb,pl,varargin);

if nargin > 3
    cH = varargin{1};
else
    cH = eye(4);
end;

%         X     Y     Z
bbox = [bb(1) bb(3) bb(5); % back side 1
        bb(2) bb(3) bb(5);
        bb(2) bb(4) bb(5);
        bb(1) bb(4) bb(5);
        bb(1) bb(3) bb(5);
        bb(1) bb(3) bb(6); % back side 2
        bb(1) bb(4) bb(6);
        bb(1) bb(4) bb(5);
        bb(1) bb(3) bb(5);
        bb(2) bb(3) bb(5); % back side 3
        bb(2) bb(3) bb(6);
        bb(1) bb(3) bb(6);
        bb(1) bb(3) bb(5);
        bb(2) bb(3) bb(5); % travel to front
        bb(2) bb(4) bb(5);
        bb(2) bb(4) bb(6);
        bb(1) bb(4) bb(6); % front side 1
        bb(1) bb(3) bb(6);
        bb(2) bb(3) bb(6);
        bb(2) bb(4) bb(6)]';

bbmin = [bb(1) bb(3) bb(5)]';
bbmax = [bb(2) bb(4) bb(6)]';

Tbbox = vtkT*[bbox; ones(1, size(bbox,2))];
bbc = Tbbox./repmat(Tbbox(3,:), [3 1]);
bbc = bbc(1:2,:);

Tbbmin = vtkT*[bbmin; ones(1, size(bbmin,2))];
Tbbmax = vtkT*[bbmax; ones(1, size(bbmax,2))];
bbminc = Tbbmin./repmat(Tbbmin(3,:), [3 1]);
bbmaxc = Tbbmax./repmat(Tbbmax(3,:), [3 1]);


hold on;
plot(bbminc(1),bbminc(2),'yd','MarkerSize',10,'LineWidth',2);
plot(bbmaxc(1),bbmaxc(2),'gd','MarkerSize',10,'LineWidth',2);
plot(bbc(1,:),bbc(2,:),pl,'LineWidth',2);
hold off;