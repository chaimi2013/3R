function normalVecRect = normalVecRectSign(normalVec, spxCenterXYZ, cameraXYZ)
% function normalVecRect = normalVecRectSign(normalVec, spxCenterXYZ, cameraXYZ)
% rectify the sign of normal vectors according to the incident light angle
% normalVec:        normal vector
% spxCenterXYZ:     world coordinates of super-pixel centers
% cameraXYZ:        world coordinate of camera
% normalVecRect:    the rectified normal vector

spxLabelsNum = size(spxCenterXYZ, 2);
lightPathVec = repmat(cameraXYZ,  [1, spxLabelsNum]) - spxCenterXYZ;
lightPathDis = sqrt(sum(lightPathVec.^2, 1)) + eps;
lightPathVec = lightPathVec ./ repmat(lightPathDis, [3, 1]);

cosAngle = sum(lightPathVec .* normalVec(1:3, :), 1);

normalVecRect = normalVec .* repmat(sign(cosAngle),[4,1]);