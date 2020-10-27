function XYZ = calXYZ(RT,K,D,C)
% function XYZ = calXYZ(RT,K,D,C)
% calcualte the world coordinates of pixels given camera parameters and depth map
% RT:   extrinsic parameters
% K:    intrinsic parameters
% D:    depth map
% C:    rotation matrix for Cityscapes only
% dsr:  downSamplingRatio --> use param.K(3,3)=downSamplingRatio instead
% XYZ:  world coordinates

if ~exist('C', 'var') || isempty(C)
    C = eye(3);
end

[hei,wid] = size(D);

xW = [1:wid];
yH = [1:hei];

[u,v] = meshgrid(xW,yH);
u = u(:)';
v = v(:)';

uv = [u; v; ones(1,length(u))];
xyz = K \ uv;
xyz = xyz ./ repmat(xyz(3,:), [3,1]);

xyz = xyz .* repmat(D(:)', [3,1]) / 100; %D's unit is cm, convert to m
xyz = C * xyz;  %for compatibility of cityscapes; please note the C matrix

posXYZ = RT(1:3,1:3)^(-1) * (xyz - repmat(RT(1:3,4),[1, size(xyz,2)])); %world coordinate

XYZ = zeros(hei,wid,3);
XYZ(:,:,1) = reshape(posXYZ(1,:),[hei,wid]);
XYZ(:,:,2) = reshape(posXYZ(2,:),[hei,wid]);
XYZ(:,:,3) = reshape(posXYZ(3,:),[hei,wid]);

