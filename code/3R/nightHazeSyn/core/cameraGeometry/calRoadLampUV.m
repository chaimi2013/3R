function roadLampUV = calRoadLampUV(RT, K, roadLampXYZ, C)
% function roadLampUV = calRoadLampUV(RT, K, roadLampXYZ)
% calculate the projected coordinates of road lamps on the image plane given 
% the camera params (RT, K) and world coordinates of road lamps (roadLampXYZ)
% RT:           extrinsic parameters
% K:            intrinsic parameters
% roadLampXYZ:  3*N
% C:            rotation matrix for Cityscapes only
% roadLampUV:   2*N

if ~exist('C', 'var')
    C = eye(3);
end

roadLampPosNum = size(roadLampXYZ, 2);

xyz = RT(1:3, :) * [roadLampXYZ; ones(1, roadLampPosNum)];
xyz(2, :) = xyz(2, :);
roadLampUV = K * (C \ xyz);
roadLampUV = roadLampUV(1:2, :) ./ repmat(roadLampUV(3,:), [2, 1]);
roadLampUV = round(roadLampUV);
