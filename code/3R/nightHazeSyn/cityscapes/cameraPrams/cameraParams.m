function camera = cameraParams(params)
% function camera = cameraParams(cameraParamsStruct)
% param:    the input camera parameters struct
%           params.extrinsic.pitch, yaw, roll
%           params.intrinsic.fx, fy, u0, v0, baseline
%camera:    the output camera parameters (RT, K, BL)

xPitch = params.extrinsic.pitch;
yYaw = params.extrinsic.yaw;
zRoll = params.extrinsic.roll;

t = [params.extrinsic.x;
     params.extrinsic.y;
     params.extrinsic.z];
 
R = EulerAngle2RotationMatrix(xPitch, yYaw, zRoll);
RT = [R, t];

K = [params.intrinsic.fx,       0,                    params.intrinsic.u0;
     0,                         params.intrinsic.fy,  params.intrinsic.v0;
     0,                         0,                    1];
 
 BL = params.extrinsic.baseline;
 
 camera = struct;
 camera.RT = RT;
 camera.K = K;
 camera.BL = BL;