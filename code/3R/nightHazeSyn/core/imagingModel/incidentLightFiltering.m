function [incidentLightMed, incidentLightMean] = incidentLightFiltering(incidentLight, spxCenterXYZ,...
    spxReflectance, ambientLightUsingReflectance)
% function [incidentLightFilter] = incidentLightFiltering(incidentLight, spxCenterXYZ)
% Apply median filtering on the incident light at each super-pixel
% incidentLight:                incident light at each super-pixel
% spxCenterXYZ:                 world coordinates of the super-pixels
% spxReflectance:               maximum reflectance of each super-pixel
%ambientLightUsingReflectance:  flag:using reflectance when calculating ambient light
% incidentLightMed:             neighbor-based median filtering results
% incidentLightMean:            neighbor-based mean filtering results

if ~exist('spxReflectance', 'var') || ~exist('ambientLightUsingReflectance', 'var')
    ambientLightUsingReflectance = 0;
end

incidentLightMed = incidentLight;
incidentLightMean = incidentLight;

spxLabelsNum = size(spxCenterXYZ,2);
r = max(round(spxLabelsNum * 0.01), 5); % 1%: 5000-> 50; 2000 -> 20

for i = 1:spxLabelsNum
    %for each spx, search its neighbors based on spatial distance
    spxCenterXYZc = spxCenterXYZ(:,i);
    dis = repmat(spxCenterXYZc,  [1, spxLabelsNum]) - spxCenterXYZ;
    dis = sqrt(sum(dis.^2, 1));
    [~, disIdxSorted] = sort(dis, 'ascend');
    
    %for median filtering incident light
    medNeighborCandIdx = disIdxSorted(2:min(2+r-1,spxLabelsNum)); % r neighbors
    incidentLightMedNeighbor = incidentLight(1,medNeighborCandIdx);
    incidentLightMed(1,i) = median(incidentLightMedNeighbor); %median one
    
    %for mean filtering incident light in a larger neighborhood --> ambient light
    neighborRatio = 10; % 1% --> 5%
    meanNeighborCandIdx = disIdxSorted(2:min(2+ neighborRatio*r-1,spxLabelsNum)); %neighborRatio*r neighbors
    incidentLightMeanNeighbor = incidentLight(1,meanNeighborCandIdx);
    if ambientLightUsingReflectance
        spxReflectanceMeanNeighbor = spxReflectance(1,meanNeighborCandIdx);
        incidentLightMean(1,i) = mean(incidentLightMeanNeighbor .* spxReflectanceMeanNeighbor);
    else
        incidentLightMean(1,i) = mean(incidentLightMeanNeighbor);
    end

end

end
