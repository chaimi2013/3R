%testMiddleburyGenNightHazeImgs
close all; clear; clc;

param = struct;
%-----------------------------light source colors--------------------------------%
addpath(genpath('.\..\core\nightColorStats\'));
nightColorStats = load('.\..\core\nightColorStats\nightColorStats.mat');
nightColorStats = nightColorStats.nightColorStats;
nightColorStats.sampleNum = 1000;
lightSourceColors = sampleColor(nightColorStats.gColor, nightColorStats.p, nightColorStats.etaBSig,...
    nightColorStats.fre, nightColorStats.gCenInterval, nightColorStats.sampleNum);
nightColorStats.lightSourceColors = lightSourceColors;
param.nightColorStats = nightColorStats;

%-------------------read and gen nighttime hazy images----------------------%
param.alpha = rand(nightColorStats.sampleNum, 1) * 0.4 + 0.5;
param.refPtsRatio = rand(nightColorStats.sampleNum, 2);
param.beta = 0.6;
param.augNumPerImg = 5;
param.imgMaxSize = 512;

rootSrc = 'ROOT\middlebury_datasets\clear\';
rootDst = 'ROOT\middlebury_datasets\nighttimeHazySyn\';
imgList = dir([rootSrc, '*view*.png']);
imgNum = length(imgList);

count = 1;
for i = 1:imgNum
    img = double(imread([rootSrc, imgList(i).name])) / 255;
    dispName = strrep(imgList(i).name, 'view', 'disp');
    disparity = double(imread([rootSrc, dispName])) / 255;
    
    [hei,wid] = size(disparity);
    ratio = param.imgMaxSize / max(hei,wid);
    img = imresize(img, ratio);
    disparity = imresize(disparity, ratio);
    
    [hei,wid] = size(disparity);
    [y,x] = meshgrid([1:wid], [1:hei]);
    
    for j = 1:param.augNumPerImg
        refPts = [param.refPtsRatio(count, 1) * hei, param.refPtsRatio(count, 2) * wid];
        depth = 1 ./ max(disparity, 1/255);
        depth = depth / max(depth(:));
        dis = sqrt((x - refPts(1)).^2 + (y - refPts(2)).^2 + (depth - 0));
        dis = dis / max(dis(:));

        t = param.beta * disparity + 1 - param.beta;

        alpha = param.alpha(count);
        L = 1 - alpha * dis;

        eta = param.nightColorStats.lightSourceColors(count, :);

        imgHazy = img;
        for cc = 1:3
            imgHazy(:,:,cc) = img(:,:,cc) .* L * eta(cc) .* t + L * eta(cc) .* (1 - t);
        end

        imgL = img .* repmat(L, [1 1 3]);

%         figure; imshow([img, imgL, imgHazy]);
        
        imgNameSave = strrep(imgList(i).name, '.png', ['_NighttimeHazy_', num2str(j), '.png']);
        imwrite(imgHazy, [rootDst, imgNameSave]);
        imwrite(imgL, [rootDst, strrep(imgNameSave, 'NighttimeHazy', 'lowLight')]);
        
        count = count + 1;
        if mod(count, 10) == 0
            disp(['==> currently processing ', num2str(count), 'th img...']);
        end
        
    end
    
end

param.count = count - 1;
save('param.mat', 'param');