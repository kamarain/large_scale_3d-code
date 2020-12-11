function [] = plot_prims(coords,C,T,pl);

% Isometry in 3D
Tcoords = T*[coords; ones(1, size(coords,2))];
Tcoords = Tcoords./repMat(Tcoords(4,:), [4 1]);

%camTcoords = C*[Tcoords; ones(1,size(Tcoords,2))];
camTcoords = C*Tcoords;

camcoords = camTcoords./repmat(camTcoords(3,:), [3 1]);

hold on;
plot(camcoords(1,:),camcoords(2,:),pl);
hold off;