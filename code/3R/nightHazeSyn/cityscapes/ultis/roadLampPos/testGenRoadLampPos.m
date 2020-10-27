%testGenRoadLampPos
close all; 
clear; clc;

addpath(genpath('ROOT_3R\nightHazeSyn\utils\cityscapes\cameraGeometry'));

root = 'ROOT\CityscapeDatasets\nighttimeHazy\';
fileName = 'foggy_trainval_refined_filenames.mat';
load([root, fileName]);
count = length(fileLines);

pathExt = [root, 'camera_trainvaltest\camera\'];
pathDepth = [root, '\depth_stereoscopic_png_refined\'];
pathSeg = [root, '\gtFine_trainvaltest\gtFine\'];
pathRoadLampXYZ = [root, '\roadLampPos\'];

roadIdx = [128, 64,  128; %road (priority)
           244, 35,  232; %sidewalk
           250, 170, 160; %parking
           230, 150, 140; %rail track
           81,  0,   81; % ground
           ]; % 
C = [0, 0, 1;
    -1, 0, 0;
    0, -1, 0];
roadLampHeight = 5; %0 for test projection location 
roadLampZ = roadLampHeight; %height; car height 2
deltaY = 1; %delta from road to lamp rod
erodeSize = 10;
xInterval = 15; %0.1 for test trajectory
extraNum = max(round(30 / xInterval), 1); %30m; add extra light sources in x-direction (forward and backward; extraNum*2)
DEBUG = 0;
for i = 1:min(count, inf)
    if mod(i, 100) == 0
        disp(['currently processing ', num2str(i), 'th img: ', fileLines{1, i}]);
    end
    fileName = fileLines{1, i};
    load([pathExt, fileName, '_camera.mat']);
    
    depth = double(imread([pathDepth, fileName, '_depth_stereoscopic.png']));
    semanticLabel = double(imread([pathSeg, fileName, '_gtFine_color.png']));
    
    %run the kernel function
    [roadLampXYZ, roadLampUV] = calRoadLampXYZ_cs(semanticLabel, depth, roadIdx, ...
        camera.RT, camera.K, C, roadLampZ, deltaY, erodeSize, xInterval, extraNum, DEBUG);
    
    saveFileName = [pathRoadLampXYZ, fileName, '_roadLampPos.mat'];
    [filepath, name, ext] = fileparts(saveFileName);
    if ~exist(filepath, 'dir')
        mkdir(filepath);
    end
    
    save(saveFileName, 'roadLampXYZ', 'roadLampUV');
    
end