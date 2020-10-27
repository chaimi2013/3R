%testRESIDEGenNightHazeImgs
close all; clear; clc;

param = struct;
%-----------------------------light source colors--------------------------------%
addpath(genpath('.\..\core\nightColorStats\'));
nightColorStats = load('.\..\core\nightColorStats\nightColorStats.mat');
nightColorStats = nightColorStats.nightColorStats;
nightColorStats.sampleNum = 10000;
lightSourceColors = sampleColor(nightColorStats.gColor, nightColorStats.p, nightColorStats.etaBSig,...
    nightColorStats.fre, nightColorStats.gCenInterval, nightColorStats.sampleNum);
nightColorStats.lightSourceColors = lightSourceColors;
param.nightColorStats = nightColorStats;

%-------------------read and gen nighttime hazy images----------------------%
param.alpha = rand(nightColorStats.sampleNum, 1) * 0.4 + 0.5;
param.refPtsRatio = rand(nightColorStats.sampleNum, 2);
param.beta = 0.6;
param.augNumPerImg = 1;
param.imgMaxSize = 640;
param.isResize = 0;

root = 'ROOT\ChallengeData-II-RESIDE\OTS_ALPHA\';
rootDepthSrc = [root, '\depth\'];
rootSrc = [root, '\clear\clear_images\'];
rootDst = [root, '\nighttimeHazy\'];
imgList = dir([rootSrc, '*.jpg']);
imgNum = length(imgList);

count = 1;
for i = 1:imgNum
    img = double(imread([rootSrc, imgList(i).name])) / 255;
    depthName = strrep(imgList(i).name, 'jpg', 'mat');
    load([rootDepthSrc, depthName]);
    depth = depth / max(depth(:));
    
    [hei,wid] = size(depth);
    if param.isResize
        ratio = param.imgMaxSize / max(hei,wid);
        img = imresize(img, ratio);
        depth = imresize(depth, ratio);
        [hei,wid] = size(depth);
    end
    [y,x] = meshgrid([1:wid], [1:hei]);
    
    for j = 1:param.augNumPerImg
        refPts = [param.refPtsRatio(count, 1) * hei, param.refPtsRatio(count, 2) * wid];
        dis = sqrt((x - refPts(1)).^2 + (y - refPts(2)).^2 + (depth - 0));
        dis = dis / max(dis(:));

        disparity = 1 ./ max(depth, 1/255);
        disparity = disparity / max(disparity(:));
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
        
        imgNameSave = strrep(imgList(i).name, '.jpg', ['_NighttimeHazy_', num2str(j), '.png']);
        imwrite(imgHazy, [rootDst, imgNameSave]);
        imwrite(imgL, [rootDst, strrep(imgNameSave, 'NighttimeHazy', 'lowLight')]);
        
        count = count + 1;
        if mod(count, 10) == 0
            disp(['==> currently processing ', num2str(count), 'th img...']);
        end
        
    end
    
end

param.count = count - 1;
save('param_RESIDE.mat', 'param');