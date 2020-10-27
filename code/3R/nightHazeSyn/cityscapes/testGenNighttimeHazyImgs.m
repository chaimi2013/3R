%testGenNighttimeHazyImgs
close all; clear; clc;
addpath(genpath('.\..\core\cameraGeometry\'));
addpath(genpath('.\..\core\imagingModel\'));
addpath(genpath('.\..\core\nightColorStats\'));
addpath(genpath('.\..\core\superPixel\'));
% addpath(genpath('.\ultis\fileProc\'));
addpath(genpath('.\ultis\fast-guided-filter-code-v1\'));

addpath(genpath('.\cameraPrams\'));

loadParamsSettings;

%debug
% imageList = {'train\aachen\aachen_000173_000019','train\aachen\aachen_000172_000019','train\aachen\aachen_000138_000019',...
%     'train\aachen\aachen_000125_000019', 'train\aachen\aachen_000152_000019', 'train\aachen\aachen_000157_000019'};
% imageList = {'train\aachen\aachen_000173_000019'}; 
% imageNum = length(imageList);

isWriteSyntheticImgs = 1;
isWriteSyntheticImgs_PartAndRename = 1;
DEBUG_RoadLampPos = 0;
m = inf;
for fileNo = 1:min(param.frameNum, m) %imageNum
    disp(['-----------------------------------------------------------------------------------']);
    disp(['==> currently processing ', num2str(fileNo), '/', num2str(param.frameNum), 'th img...']);
    
    param.update = 1;
    param.fileName = strrep(param.fileList{fileNo}, '/', '\');
    %param.fileName = imageList{fileNo}; %debug
    loadParamsSettings;
    
    img = double(imread([param.pathImg, param.fileName, '_leftImg8bit.png'])) / 255;
    depth = double(imread([param.pathDepth, param.fileName, '_depth_stereoscopic.png']));
    instanceLabel = imread([param.pathSeg, param.fileName, '_gtFine_color.png']);
    if param.downSamplingRatio > 1
        imgOri = img;
        depthOri = depth;
        instanceLabelOri = instanceLabel;
        
        img = imresize(img, 1/param.downSamplingRatio, 'bilinear');
        depth = imresize(depth, 1/param.downSamplingRatio, 'nearest');
        instanceLabel = imresize(instanceLabel, 1/param.downSamplingRatio, 'nearest');
    end
    
    %iteratively run the kernel function
    t1 = clock;
    [imgHazy, param_update, L, Leta, t, imgLowLight, imgLowLightColor, imgR, imgDatimeHazy] = ...
        genNighttimeHazyImgsScatter(img, instanceLabel, depth, param);
    t2 = clock;
    disp(['==> total time @genNighttimeHazyImgs_cs: ', num2str(etime(t2,t1))]);
    
%     figure; imshow([imgR, imgLowLightColor; imgHazy, imgDatimeHazy]);
    if isWriteSyntheticImgs
        [filepath, name, ext] = fileparts([pathImgsSave, param.fileName, '.png']);
        if isWriteSyntheticImgs_PartAndRename
            fileNameSave = strrep(param.fileName, '\', '_');
        else
            fileNameSave = param.fileName;
        
            if ~exist(filepath, 'dir')
                mkdir(filepath);
            end
        
        end
        
        imwrite(img, [pathImgsSave, fileNameSave, '.png']);
        imwrite(imgHazy, [pathImgsSave, fileNameSave, '_nightHazy.png']);
        imwrite(imgLowLight, [pathImgsSave, fileNameSave, '_lowLight.png']);
%         imwrite(imgLowLightColor, [pathImgsSave, fileNameSave, '_lowLightColor.png']);
%         imwrite(imgDatimeHazy, [pathImgsSave, fileNameSave, '_dayHazy.png']);
%         imwrite(L, [pathImgsSave, fileNameSave, '_light.png']);
%         eta = Leta ./ (repmat(L, [1 1 3]) + 0.001);
%         imwrite(eta, [pathImgsSave, fileNameSave, '_lightColor.png']);
%         imwrite(t, [pathImgsSave, fileNameSave, '_t.png']);
        
        if ~isWriteSyntheticImgs_PartAndRename
            imwrite(imgLowLightColor, [pathImgsSave, fileNameSave, '_lowLightColor.png']);
            imwrite(L, [pathImgsSave, fileNameSave, '_light.png']);
            imwrite(Leta, [pathImgsSave, fileNameSave, '_lightColor.png']);
            imwrite(t, [pathImgsSave, fileNameSave, '_t.png']);
            if param.usingImgReflectance
                imwrite(img, [pathImgsSave, fileNameSave, '_imgR.png']);
            end
            imwrite([imgR; imgLowLightColor], [pathImgsSave, fileNameSave, '_all.png']);
%         imwrite([imgR, Leta; imgLowLightColor, imgHazy], [pathImgsSave, fileNameSave, '_all.png']);
        end
    end
    
    if DEBUG_RoadLampPos
        %     figure; imshow([imgR, repmat(L,[1 1 3]); imgLowLightColor, imgHazy]);
%         figure; imshow([imgR; imgLowLightColor])
        figure; imshow([imgR, Leta; imgLowLightColor, imgHazy])
        %     figure; plot(param.roadLampXYZ(2, :), param.roadLampXYZ(1, :), 'ro'); axis equal;
        %     param.roadLampXYZ(3, :) = -2; %for visualization (projection on road surface)
        flag = param.roadLampXYZ(1, :) > 0;
        roadLampUV = calRoadLampUV(param.RT, param.K, param.roadLampXYZ, param.C);
        hold on; plot(roadLampUV(1, flag), roadLampUV(2, flag), 'ro');
        hold on; plot(roadLampUV(1, ~flag), roadLampUV(2, ~flag), 'yo'); %virtual image
    end
    
    param = param_update;
    
end
