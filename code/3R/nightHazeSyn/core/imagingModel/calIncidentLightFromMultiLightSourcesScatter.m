function [incidentIlluminationMap, incidentIlluminationMapHaze, cosAngle, param] = ...
    calIncidentLightFromMultiLightSourcesScatter(normalVec, spxCenterXYZ, spxReflectance, spxLabels, param)
% function [incidentIlluminationMap, incidentIlluminationMapHaze, cosAngle] = ...
%     calIncidentLightFromMultiLightSourcesScatter(normalVec, spxCenterXYZ, spxReflectance, spxLabels, param)
%calculate the incident light by aggregating incident lights from
%   multiple light sources
% -------------------------------------------------------------
% Please refer https://en.wikipedia.org/wiki/Lambertian_reflectance
% Is = dot(N, L) * C * IL, where N is the normal vector, L is the
% normalized light-direction vector, pointing from the surface to the light source.
% C is the is the color and IL is the intensity of the incoming light.
% Inverse-square law: https://en.wikipedia.org/wiki/Inverse-square_law
% Illuminance: https://zh.wikipedia.org/wiki/%E7%85%A7%E5%BA%A6
% 
% -------------------------------------------------------------
% normalVec:                        normal vector (4*spxLabelsNum)
% spxCenterXYZ:                     world coordinates of super-pixel centers @world coordinate system (3*spxLabelsNum)
% spxReflectance:                   mean of maximum refletance within each super-pixel
% lightSourcePos:                   world coordinates of light sources @world coordinate system (3*lightSourcesNum)
% lightAttenuationBeta:             light attenuation beta scalar in the exponent model
% isAggregate:                      aggregate the incident light from different light sources (default: 1)
% ambientLightUsingReflectance:     flag:using reflectance when calculating ambient light
% incidentLightMed:                 median filtering results
% incidentLightMean:                mean filtering results (ambient light)
% cosAngle:                         mean cosin of incident angles

lightSourcePos = param.roadLampXYZ;
lightAttenuationBeta = param.lightAttenuationBeta;
ambientLightUsingReflectance = param.ambientLightUsingReflectance;
transmissionBeta = param.transmissionBeta;
[hei, wid] = size(spxLabels);

%loop for each light source
spxLabelsNum = size(spxCenterXYZ, 2);
lightSourceNum = size(lightSourcePos, 2);
incidentLightWhole = zeros(lightSourceNum, spxLabelsNum);
incidentLightMeanWhole = zeros(lightSourceNum, spxLabelsNum);
cosAngleWhole = zeros(lightSourceNum, spxLabelsNum);
lightPathDisWhole = zeros(lightSourceNum, spxLabelsNum);
tWhole = zeros(lightSourceNum, spxLabelsNum);
for i = 1:lightSourceNum
    %calculate the incident light-direction vector
    lightSourcePosTmp = lightSourcePos(:, i);
    lightPathVec = repmat(lightSourcePosTmp,  [1, spxLabelsNum]) - spxCenterXYZ;
    lightPathDis = sqrt(sum(lightPathVec.^2, 1)) + eps;
    lightPathVec = lightPathVec ./ repmat(lightPathDis, [3, 1]);
    lightPathDisWhole(i, :) = lightPathDis;

    %calculate the angle between the incident light-direction vector and the super-pixel normal vector
    cosAngle = sum(lightPathVec .* normalVec(1:3, :), 1);
    cosAngleVis = abs(cosAngle); 
    
    %exponent light attenuation model and Lambertian reflectance (cosine model)
    %incidentLight = exp(-lightAttenuationBeta * lightPathDis) .* cosAngleVis; 
    %illuminace according to the Inverse-square law and Lambertian reflectance (cosine model)
    incidentLight = (lightAttenuationBeta ./ lightPathDis .^ 2) .* cosAngleVis; 
    
    %super-pixel based median filtering and mean filtering (ambient light)
    [incidentLightMed, incidentLightMean] = incidentLightFiltering(incidentLight, spxCenterXYZ, ...
        spxReflectance, ambientLightUsingReflectance);
    
    incidentLightWhole(i,:) = incidentLightMed;
    incidentLightMeanWhole(i,:) = incidentLightMean;
    cosAngleWhole(i,:) = cosAngle;
    
    t = exp(-transmissionBeta * lightPathDisWhole(i, :) );%unit, m
    tWhole(i, :) = t;
end

%calculate the incident light map with sampled color
if ~param.usingUniformLightSourceColors
    %shuffle the sampled lihgt source colors 
    candidateLightColorNum = size(param.nightColorStats.lightSourceColors, 1);
    idxShuffle = randperm(candidateLightColorNum);
    %randomly choose the sampled lihgt source colors
    lightSourceColors = param.nightColorStats.lightSourceColors(idxShuffle(1:lightSourceNum),:);
    if isfield(param,'lightSourceColors')
        lightSourceColors = param.lightSourceColors;
    else
        if param.lightSourceColorsKeepFixed
            param.lightSourceColors = lightSourceColors;
        end
    end
    
    %apply on each illumination map corresponding to each light source
    incidentLightColors = repmat(reshape(lightSourceColors, [lightSourceNum, 3, 1]), [1, 1, spxLabelsNum]);
    incidentLightWhole = repmat(reshape(incidentLightWhole, [lightSourceNum, 1, spxLabelsNum]), [1, 3, 1]) .* incidentLightColors;
    incidentLightMeanWhole = repmat(reshape(incidentLightMeanWhole, [lightSourceNum, 1, spxLabelsNum]), [1, 3, 1]) .* incidentLightColors;
else
    %shuffle the sampled lihgt source colors 
    candidateLightColorNum = size(param.nightColorStats.lightSourceColors, 1);
    idxShuffle = randperm(candidateLightColorNum);
    %randomly choose ONE sampled lihgt source color
    lightSourceColors = param.nightColorStats.lightSourceColors(idxShuffle(1),:);
    
    %apply on each illumination map corresponding to each light source
    incidentLightColors = repmat(reshape(lightSourceColors, [1, 3, 1]), [lightSourceNum, 1, spxLabelsNum]);
    %incident light aggregation
    incidentLightWhole = repmat(reshape(incidentLightWhole, [lightSourceNum, 1, spxLabelsNum]), [1, 3, 1]) .* incidentLightColors;
    incidentLightMeanWhole = repmat(reshape(incidentLightMeanWhole, [lightSourceNum, 1, spxLabelsNum]), [1, 3, 1]) .* incidentLightColors;
end
tWhole = repmat(reshape(tWhole, [lightSourceNum, 1, spxLabelsNum]), [1, 3, 1]);

%calculate the airlight
incidentLightWholeAir = mean(mean(incidentLightWhole .* (1-tWhole), 1), 3);
incidentLightWholeAir = repmat(reshape(incidentLightWholeAir, [1, 3, 1]), [1, 1, spxLabelsNum]);
incidentLightMeanWholeAir = mean(mean(incidentLightMeanWhole .* (1-tWhole), 1), 3);
incidentLightMeanWholeAir = repmat(reshape(incidentLightMeanWholeAir, [1, 3, 1]), [1, 1, spxLabelsNum]);

incidentLightWholeHaze = zeros(lightSourceNum, 3, spxLabelsNum);
incidentLightMeanWholeHaze = zeros(lightSourceNum, 3, spxLabelsNum);
for i = 1:lightSourceNum
    incidentLightWholeHaze(i, :, :) = incidentLightWhole(i,:, :) .* tWhole(i, :, :) + incidentLightWholeAir .* (1 - tWhole(i, :, :));
    incidentLightMeanWholeHaze(i, :, :) = incidentLightMeanWhole(i,:, :) .* tWhole(i, :, :) + incidentLightMeanWholeAir .* (1 - tWhole(i, :, :));
end

%------------------------
%transform the super-pixel-based incident light to map
incidentLightMapInit = zeros(3, hei,wid,lightSourceNum);
incidentLightMeanMapInit = zeros(3, hei,wid,lightSourceNum);
incidentLightMapInitHaze = zeros(3, hei,wid,lightSourceNum);
incidentLightMeanMapInitHaze = zeros(3, hei,wid,lightSourceNum);
for cc = 1:3
    incidentLightWholeCC = reshape(incidentLightWhole(:,cc,:), [lightSourceNum, spxLabelsNum]);
    incidentLightMapInit(cc, :,:,:) = vec2map(incidentLightWholeCC, spxLabels);
    incidentLightWholeCC = reshape(incidentLightMeanWhole(:,cc,:), [lightSourceNum, spxLabelsNum]);
    incidentLightMeanMapInit(cc, :,:,:) = vec2map(incidentLightWholeCC, spxLabels);
    
    incidentLightWholeCC = reshape(incidentLightWholeHaze(:,cc,:), [lightSourceNum, spxLabelsNum]);
    incidentLightMapInitHaze(cc, :,:,:) = vec2map(incidentLightWholeCC, spxLabels);
    incidentLightWholeCC = reshape(incidentLightMeanWholeHaze(:,cc,:), [lightSourceNum, spxLabelsNum]);
    incidentLightMeanMapInitHaze(cc, :,:,:) = vec2map(incidentLightWholeCC, spxLabels);
end
% cosAngleMap = vec2map(cosAngle, spxLabels);

%calculate the inclident illumination map by combining the direct incident light and ambient light
incidentIlluminationMap = (incidentLightMapInit + incidentLightMeanMapInit);
incidentIlluminationMapHaze = (incidentLightMapInitHaze + incidentLightMeanMapInitHaze);
%keep a small illumination value for dark region --> 0.04 after sum
incidentIlluminationMap = max(incidentIlluminationMap, 0.04 / lightSourceNum); %can handle nan, 0.04 = max(nan, 0.04)
incidentIlluminationMapHaze = max(incidentIlluminationMapHaze, 0.04 / lightSourceNum); %can handle nan, 0.04 = max(nan, 0.04)

%illumination normalization
if param.globalIlluminationNormalization
    %calculate the incidentIlluminationMapMaxGlobal at the first frame
    if ~isfield(param, 'incidentLightMapMaxGlobal')
        incidentIlluminationMapAgg = sum(incidentIlluminationMap, 4); %incident illumination aggregation
        incidentIlluminationMapAggMax= max(incidentIlluminationMapAgg(:));
        param.incidentIlluminationMapMaxGlobal = max(incidentIlluminationMapAggMax, 0);
    end
    incidentIlluminationMap = incidentIlluminationMap / param.incidentIlluminationMapMaxGlobal;
else
    %calculate the incidentIlluminationMapMaxGlobal at each frame
    incidentIlluminationMapAgg = sum(incidentIlluminationMap, 4); %incident illumination aggregation
    incidentIlluminationMapAggMax = max(incidentIlluminationMapAgg, [], 1); %v channle
    incidentIlluminationMapAggMax= sort(incidentIlluminationMapAggMax(:));
    incidentIlluminationMapAggMax = incidentIlluminationMapAggMax(ceil(numel(incidentIlluminationMapAggMax) * 0.95));
    incidentIlluminationMap = incidentIlluminationMapAgg / incidentIlluminationMapAggMax;
    incidentIlluminationMap = min(incidentIlluminationMap, 1);
    incidentIlluminationMap = permute(incidentIlluminationMap, [2,3,1]);
    
    incidentIlluminationMapAgg = sum(incidentIlluminationMapHaze, 4); %incident illumination aggregation
    incidentIlluminationMapAggMax = max(incidentIlluminationMapAgg, [], 1); %v channle
    incidentIlluminationMapAggMax= sort(incidentIlluminationMapAggMax(:));
    incidentIlluminationMapAggMax = incidentIlluminationMapAggMax(ceil(numel(incidentIlluminationMapAggMax) * 0.95));
    incidentIlluminationMapHaze = incidentIlluminationMapAgg / incidentIlluminationMapAggMax;
    incidentIlluminationMapHaze = min(incidentIlluminationMapHaze, 1);
    incidentIlluminationMapHaze = permute(incidentIlluminationMapHaze, [2,3,1]);
end
incidentIlluminationMapHaze = incidentIlluminationMap; %do not use illuminance scattering model


