function [imgHazy, param_update, L, Leta, t, imgLowLight, imgLowLightColor, imgR, imgDatimeHazy, skyMask] = ...
    genNighttimeHazyImgsScatter(img, instanceLabel, depth, param)
% function [imgHazy, param_update, L, Leta, t, imgLowLight, imgLowLightColor, imgR] = ...
%     genNighttimeHazyImgsScatter(img, instanceLabel, depth, param)
% img:              clear image
% instanceLabel:    instance (semantic) label map
% depth:            depth map
% param:            param struct
% imgHazy:          synthetic nighttime hazy image
% param_update:     updated parameters
% L:                illumination intensity map
% Leta:             illumination map under uniform/non-uniform artificial lights
% t:                transmission map
% imgLowLight:      low light image
% imgLowLightColor: low light image with uniform/non-uniform ligth colors
% imgR:             clear image with illumination correction (gamma coorection)

if param.usingImgReflectance
    imgR = img ./ repmat(max(img, [], 3) + 0.01, [1 1 3]) .^ (1/2);
else
    imgR = img;
end

[hei, wid] = size(depth);

%generate the world cooridates @world coordinate system from depth based on the camera parameters
XYZ = calXYZ(param.RT, param.K, depth, param.C);

%generate the super-pixel segmentation by applying SLIC alogirthm
[normalVec, spxLabels, spxLabelsNum, invalidSpxLabels, spxCenter, spxCenterXYZ, spxReflectance, spxImgOlp]  = ...
    calSuperpixelPlaneNormal(imgR, instanceLabel, XYZ, param.superpixelsNum, param.validPixelsForFitting, param.handleInvalidPixelsForFitting);

%calculate the world coordinate of each super-pixel center
%---> use the mean esitmation from XYZ and calSuperpixelPlaneNormal instead
% spxCenterXYZ = calXYZFromUV_cs(param.RT, param.K, round(spxCenter)', depth, 0, param.C);

%calculate the world coordinate of the camera (No C matrix here); (0,0,0)@camera coordinate system --> (x,y,z)@world coordinate system
cameraXYZ = param.RT(1:3,1:3)^(-1) * (- param.RT(1:3,4));

%rectify the sign of normal vectors
normalVecRect = normalVecRectSign(normalVec, spxCenterXYZ, cameraXYZ);

%neighbor-based median filtering of the normal vector
[normalVecFilter] = normalVecMedianFiltering(normalVecRect, spxCenterXYZ);

%[sp, nv] = debugSuperpixelNormalvector(spxLabels, normalVecFilter(1:3, :));

%calculate the incident light by aggregating incident lights from multiple light sources
%incidentLight: the direct incident light
%incidentLightMean: the ambient light
[incidentIlluminationMap, incidentIlluminationMapHaze, cosAngle, param] = ...
    calIncidentLightFromMultiLightSourcesScatter(normalVecFilter, spxCenterXYZ, spxReflectance, spxLabels, param);

%filtering the inclident light map using image guided filter
% %generate the guided image by filtering the semantic label map (with coarse edges)
% guidedImg = double(instanceLabel)/255;
% for cc = 1:3
%     guidedImg(:,:,cc) = fastguidedfilter_color(imgR, guidedImg(:,:,cc), ...
%         param.GF_r/2, param.GF_epsilon/10, param.GF_ds); %1/2, 1/10
% end
%filtering the inclident light map under the guidance of the filted semantic label map
guidedImg = double(instanceLabel)/255;
Leta = zeros(hei,wid,3);
LetaHaze = zeros(hei,wid,3);
for cc = 1:3
    Leta(:,:,cc) = fastguidedfilter_color(guidedImg, incidentIlluminationMap(:,:,cc), ...
        param.GF_r, param.GF_epsilon, param.GF_ds); %1, 1
    LetaHaze(:,:,cc) = fastguidedfilter_color(guidedImg, incidentIlluminationMapHaze(:,:,cc), ...
        param.GF_r, param.GF_epsilon, param.GF_ds); %1, 1
end

%----------------deal with sky region--------------
%choose the sky regions
skyMask = (instanceLabel(:,:,1) == param.skyLabel(1) & ...
    instanceLabel(:,:,2) == param.skyLabel(2) & instanceLabel(:,:,3) == param.skyLabel(3) );
% filtering the sky region mask (with coarse boundaries)
if sum(skyMask(:)) > 0
    skyMask = fastguidedfilter_color(imgR, skyMask, ...
        param.GF_r, param.GF_epsilon, param.GF_ds);
end
skyMask = repmat(skyMask, [1 1 3]);

%keep the sky region dark (0)
Leta = (1 - skyMask) .* Leta;
LetaHaze = (1 - skyMask) .* LetaHaze;
%the illumination intensity map
L = max(Leta, [], 3);
LHaze = max(LetaHaze, [], 3);

%calcuate the transmission
%----------exponent model ----------------------
t = exp(-param.transmissionBeta * depth / 100);%100: cm -> m
t = min(max(t, 0), 1);

%generate the nighttime hazy images
imgHazy = imgR .* LetaHaze .* repmat(t, [1 1 3]) + LetaHaze .* repmat(1-t, [1 1 3]);
imgDatimeHazy = imgR .* repmat(t, [1 1 3]) + 1 .* repmat(1-t, [1 1 3]);
imgLowLight = imgR .* repmat(L, [1 1 3]);
imgLowLightColor = imgR .* Leta;

%update the params
param_update = param;