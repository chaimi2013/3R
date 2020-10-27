%testRoadLampPosStats
close all; clear; clc;

addpath(genpath('ROOT_3R\nightHazeSyn\utils\cityscapes\cameraGeometry'));

root = 'ROOT\CityscapeDatasets\nighttimeHazy\';
fileName = 'foggy_trainval_refined_filenames.mat';
load([root, fileName]);
count = length(fileLines);

pathExt = [root, 'camera_trainvaltest\camera\'];
pathRoadLampXYZ = [root, '\roadLampPos\'];

xyz = [];
for i = 1:min(count, inf)
    if mod(i, 100) == 0
        disp(['currently processing ', num2str(i), 'th img: ', fileLines{1, i}]);
    end
    fileName = fileLines{1, i};
    load([pathRoadLampXYZ, fileName, '_roadLampPos.mat']);
    
    xyz = [xyz, roadLampXYZ];
end

figure; plot(-xyz(2, 1:2:end),  xyz(1, 1:2:end), 'ro'); axis equal
hold on; plot(-xyz(2, 2:2:end), xyz(1, 2:2:end), 'go'); title('(-1)Y-X');