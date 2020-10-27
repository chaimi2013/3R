%testDepthProcStats
close all; clear; clc;

depthLevel = 16;

root = 'ROOT\CityscapeDatasetsFoggy\depth_stereoscopic_trainvaltest\';
rootSrc = [root, '\depth_stereoscopic\'];
rootDst = [root, '\depth_stereoscopic_png\'];

datasetSplit = dir([rootSrc]);
datasetSplit = datasetSplit(3:end);

stats = [];
count = 0;
for i = 1:length(datasetSplit)
    dataset = datasetSplit(i).name;
    folderSrc = [rootSrc, '\', dataset, '\'];
    folderDst = [rootDst, '\', dataset, '\'];
    if ~exist(folderDst, 'dir')
        mkdir(folderDst);
    end
    
    imgsFolder = dir([folderSrc]);
    imgsFolder = imgsFolder(3:end);
    for j = 1:length(imgsFolder)
        imgsFolderSrc = [folderSrc, '\', imgsFolder(j).name, '\'];
        imgsFolderDst = [folderDst, '\', imgsFolder(j).name, '\'];
        if ~exist(imgsFolderDst, 'dir')
            mkdir(imgsFolderDst);
        end
        
        imgsName = dir([imgsFolderSrc, '*.mat']);
        imgsNum = length(imgsName);
        for k = 1:imgsNum
            if mod(count, 100) == 0
                disp(['currently processing ', num2str(count), 'th img: ', imgsName(k).name]);
            end
            load([imgsFolderSrc, imgsName(k).name]);
            [depth, depthMinimum, depthMaximum] = depthProcessing(depth_map, depthLevel);
            stats = [stats; [depthMinimum, depthMaximum]];
            imwrite(uint16(depth*100), [imgsFolderDst, strrep(imgsName(k).name, '.mat', '.png')]);
            
            count = count + 1;
        end
    end
    
end