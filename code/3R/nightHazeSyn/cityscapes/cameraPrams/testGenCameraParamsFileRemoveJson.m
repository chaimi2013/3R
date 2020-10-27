%testGenCameraParamsFileRemoveJson
%remove the json file which has no corresponding mat files
close all; clear; clc;

root = 'ROOT\CityscapeDatasets\nighttimeHazy\';
rootSrc = [root, '\camera_trainvaltest\camera\'];

datasetSplit = dir([rootSrc]);
datasetSplit = datasetSplit(3:end);

count = 0;
for i = 1:length(datasetSplit)
    dataset = datasetSplit(i).name;
    folderSrc = [rootSrc, '\', dataset, '\'];
    
    imgsFolder = dir([folderSrc]);
    imgsFolder = imgsFolder(3:end);
    for j = 1:length(imgsFolder)
        imgsFolderSrc = [folderSrc, '\', imgsFolder(j).name, '\'];
        
        fileName = dir([imgsFolderSrc, '*.json']);
        imgsNum = length(fileName);
        for k = 1:imgsNum
            if mod(count, 100) == 0
                disp(['currently processing ', num2str(count), 'th img: ', fileName(k).name]);
            end
            fileNameFull = [imgsFolderSrc, fileName(k).name];
            matFileNameFull = [imgsFolderSrc, strrep(fileName(k).name, '.json', '.mat')];
            if exist(fileNameFull, 'file') && ~exist(matFileNameFull, 'file')
               delete(fileNameFull);
            end
            
            count = count + 1;
        end
    end
    
end