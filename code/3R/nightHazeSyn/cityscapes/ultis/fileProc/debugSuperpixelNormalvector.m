function [sp, nv] = debugSuperpixelNormalvector(spxLabels, normalVecFilter)
% function [sp, nv] = debugSuperpixelNormalvector(spxLabels, normalVecFilter)

spxLabelsMap = double(spxLabels);
spxLabelsMap = spxLabelsMap / max(spxLabelsMap(:));
[spxLabelsMapGx, spxLabelsMapGy] = gradient(spxLabelsMap);
spxLabelsMapG = sqrt(spxLabelsMapGx.^2 + spxLabelsMapGy.^2) > 0;
spxLabelsMap = spxLabelsMap .* spxLabelsMapG + spxLabelsMapG;
sp = uint8(spxLabelsMap * 255);

normalVecMap = vec2map(normalVecFilter, spxLabels);
nv = (normalVecMap + 1) / 2;
