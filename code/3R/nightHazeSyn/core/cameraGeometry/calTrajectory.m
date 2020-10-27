function cameraPos = calTrajectory(extrinsic)
% function cameraPos = calTrajectory(extrinsic)
% calcualte the on-car camera trajectory from the extrinsics
% extrinsic:    the sequence of extrinsic parameters (N * 17); [2:17] --> 4*4
% cameraPos:    the camera positions in the world coordinate system (-R\t)

frameNo = size(extrinsic,1);
cameraPos = zeros(frameNo,3);
for i = 1:frameNo
    RT = reshape(extrinsic(i,2:end), [4,4])';
    cameraPos(i,:) = -RT(1:3,1:3) \ RT(1:3,4);
end
