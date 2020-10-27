%testGenCameraParams
close all; clear; clc;

root = 'ROOT\CityscapeDatasets\nighttimeHazy\';
fileName = 'foggy_trainval_refined_filenames.mat';
load([root, fileName]);
count = length(fileLines);

rootSrc = [root, 'camera_trainvaltest\camera\'];
for i = 1:count
    if mod(i, 100) == 0
        disp(['currently processing ', num2str(i), 'th img: ', fileLines{1, i}]);
    end
    jsonFileName = [strrep(fileLines{1, i}, '/', '\'), '_camera.json'];
    cameraJsonFileName = [rootSrc, jsonFileName];
    camera = loadjson(cameraJsonFileName);
    
    camera = cameraParams(camera);
    
    cameraMatFileName = strrep(cameraJsonFileName, '.json', '.mat');
%     if ~isempty(strfind(fileLines{1, i}, 'val'))
%         save(cameraMatFileName, 'camera');
%     end
    save(cameraMatFileName, 'camera');
end