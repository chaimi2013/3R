function glow = calGlow(XYZ, lightSourcePos, lightAttenuationBeta)
% function glow = calGlow(XYZ, lightSourcePos, lightAttenuationBeta)

[hei,wid, ~] = size(XYZ);
lightSourceNum = size(lightSourcePos, 2);
glow = zeros(hei,wid, lightSourceNum);
for i = 1:lightSourceNum
    lightSourcePosTmp = repmat(reshape(lightSourcePos(:,i), [1 1 3]), [hei, wid, 1]);
    lightPathDis = sqrt(sum( (XYZ - lightSourcePosTmp).^2, 3));
    incidentLight = exp(-lightAttenuationBeta * lightPathDis);
    glow(:,:,i) = incidentLight;
end