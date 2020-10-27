function [normalVecMerge, spxLabels, spxLabelsNum, invalidSpxLabels, spxCenter, spxCenterXYZ, spxReflectance, imgOlp] = ...
    calSuperpixelPlaneNormal(img, instanceLabel, XYZ, superpixelsNum, validPixelsForFitting, handleInvalidPixelsForFitting)
% function [normalVec, spxLabels, spxLabelsNum, invalidSpxLabels, spxCenter, spxCenterXYZ, spxReflectance, imgOlp] = ...
%     calSuperpixelPlaneNormal(img, instanceLabel, XYZ, superpixelsNum, validPixelsForFitting)
% img:                              image
% instanceLabel:                    instance label map
% XYZ:                              world coordinates
% superpixelsNum:                   number of super-pixels to be segmented
% validPixelsForFitting:            number of valid pixels for plane fitting
% handleInvalidPixelsForFitting:    handle nan case for super-pixels without plane fitting
% normalVec:                        normal vector within each super-pixel
% spxLabels:                        super-pixel label map
% spxLabelsNum:                     number of super-pixels
% invalidSpxLabels:                 labels of invliad super-pixels for plane fitting
% spxCenter:                        uv coordinate of each super-pixel center
% spxCenterXYZ:                     XYZ coordinate of each super-pixel center @world coordinate system
% spxReflectance:                   mean of maximum refletance within each super-pixel
% imgOlp:                           overlay the super-pixel segmentation on the image

if ~exist('isHandleNan', 'var')
    handleInvalidPixelsForFitting = 0;
end

%calculate illumination
illumination = max(img, [], 3);

%super-pixel segmentation using SLIC; numlabels is the same as number of superpixels
[spxLabels, spxLabelsNum] = slicomex(instanceLabel,superpixelsNum); %spxLabels, 0-start
% mapping = spxLabel2InstanceLabelMapping(instanceLabel, spxLabels, spxLabelsNum);

display = 1;
if display
    [gx, gy] = gradient(double(spxLabels));
    g = sqrt(gx.^2 + gy.^2);
    spxBoudaryMask = uint8(repmat((g <= 0), [1 1 3]));
    imgOlp = instanceLabel .* spxBoudaryMask;
    %     figure; imagesc(imgOlp); axis image;
else
    imgOlp = [];
end

[hei,wid,c] = size(instanceLabel);
imgSize = hei * wid;
xW = [1:wid];
yH = [1:hei];
[u,v] = meshgrid(xW,yH);

normalVec = zeros(4, spxLabelsNum) + nan;
invalidSpxLabels = [];
spxCenter = zeros(2, spxLabelsNum);
spxCenterXYZ = zeros(3, spxLabelsNum);
spxReflectance = zeros(1, spxLabelsNum);
for i = 1:spxLabelsNum
    idx = find(spxLabels == i-1);
    spxPixelsNum = length(idx);
    
    %maximum reflectance within each super-pixel (MRP)
    spxReflectance(1, i) = max(illumination(idx));
    
    spxCenter(1,i) = mean(u(idx));
    spxCenter(2,i) = mean(v(idx));
    
    %spxCenterXYZ(:, i) = mean([XYZ(idx), XYZ(idx+imgSize), XYZ(idx+imgSize*2)]',2);
    spxCenterXYZ(:, i) = median([XYZ(idx), XYZ(idx+imgSize), XYZ(idx+imgSize*2)]',2);
    
    if spxPixelsNum < validPixelsForFitting
        disp(['labels: ', num2str(i), ' superpixel has not enough pixels£º '...
            , num2str(spxPixelsNum), '/', num2str(validPixelsForFitting)]);
        invalidSpxLabels = [invalidSpxLabels, i];
        continue;
    end
    
    %super-pixel plane fitting and SVD-based normal vector calculation
    spxXYZ = [XYZ(idx), XYZ(idx+imgSize), XYZ(idx+imgSize*2), ones(spxPixelsNum, 1)];
    [~,S,Vt] = svd(spxXYZ);
    %the objective funciton should be normalized by plane normal vector,
    %which indeed represent the distance between each point to the fitted
    %plane
    normalVecNorm = sqrt(Vt(1,:).^2 + Vt(2,:).^2 + Vt(3,:).^2);
    Snorm = diag(S) ./ normalVecNorm(:);
    [~, SnormIdxSorted] = sort(Snorm, 'ascend'); %eigenvector corresponding to the minimum eigenvalue
    spxNormalVec = Vt(:,SnormIdxSorted(1));
    spxNormalVec = spxNormalVec / norm(spxNormalVec(1:3), 2);
    normalVec(:, i) = spxNormalVec;
end

%deal with the nan case: small super-pixel region less than validPixelsForFitting pixels
normalVecMerge = normalVec;
invalidSpxLabelsNum = length(invalidSpxLabels);
if invalidSpxLabelsNum > 0 && handleInvalidPixelsForFitting;
    indexValid = find(~isnan(normalVec(1, :)));
    for i = 1:invalidSpxLabelsNum
        label =  invalidSpxLabels(i);

        %depth is not so reliable
        spxCenterXYZC = spxCenterXYZ(:,label);
        dis_xyz = repmat(spxCenterXYZC,  [1, spxLabelsNum]) - spxCenterXYZ;
        dis_xyz = sqrt(sum(dis_xyz.^2, 1));
        spxCenterC = spxCenter(:,label);
        dis_uv = repmat(spxCenterC,  [1, spxLabelsNum]) - spxCenter;
        dis_uv = sqrt(sum(dis_uv.^2, 1));
        dis = dis_xyz .* dis_uv;
        
        [~, disIdxSorted] = sort(dis(indexValid), 'ascend');
        neighborIdx = indexValid(disIdxSorted(1));
        
        normalVecMerge(:, label) =  normalVec(:, neighborIdx);
        
    end
    
end

end