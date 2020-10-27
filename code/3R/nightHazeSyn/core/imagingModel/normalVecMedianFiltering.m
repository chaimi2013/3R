function [normalVecFilter] = normalVecMedianFiltering(normalVec, spxCenterXYZ)
% function normalVecFilter = normalVecMedianFiltering(normalVec, spxCenterXYZ)
% neighbor-based median filtering of the nromal vector
% normalVec:        normal vector
% spxCenterXYZ:     world coordinates of super-pixel centers
% normalVecFilter:  normal vector after neighbor-based median filtering

normalVecFilter = normalVec;

spxLabelsNum = size(spxCenterXYZ,2);
r = max(round(spxLabelsNum * 0.01), 5); %5000-> 50
for i = 1:spxLabelsNum
    spxCenterXYZc = spxCenterXYZ(:,i);
    dis = repmat(spxCenterXYZc,  [1, spxLabelsNum]) - spxCenterXYZ;
    dis = sqrt(sum(dis.^2, 1));
    [~, disIdxSorted] = sort(dis, 'ascend');
    neighborIdx = disIdxSorted(2:2+r-1);
    
    normalVecNeighbor = normalVec(1:3,neighborIdx);
    %quantizization
    angleQ = round(acos(normalVecNeighbor(1,:)) / pi * 180) + round(acos(normalVecNeighbor(1,:)) / pi * 180) * 10^3 + ...
        round(acos(normalVecNeighbor(1,:)) / pi * 180) * 10^6;
    [~, angleQIdxSorted] = sort(angleQ, 'ascend');
    neighborIdxMed = angleQIdxSorted(floor(r/2+0.5));
    
    normalVecFilter(:,i) = normalVec(:, neighborIdx(neighborIdxMed));
end
