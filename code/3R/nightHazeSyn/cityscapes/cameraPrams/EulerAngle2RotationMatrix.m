function R = EulerAngle2RotationMatrix(xPitch, yYaw, zRoll)
% function R = EulerAngle2RotationMatrix(xPitch, yYaw, zRoll)
% transform the camera paramters from Euler angles to RT, etc.
% please refer https://blog.csdn.net/lql0716/article/details/72597719
%xPitch:    pitch around the x axis
%yYaw:      yaw around the y axis
%zRoll:     roll around the z axis
%R:         the rotation matrix

sx = sin(xPitch);
cx = cos(xPitch);

sy = sin(yYaw);
cy = cos(yYaw);

sz = sin(zRoll);
cz = cos(zRoll);

% Rxyz = Rz * Ry * Rx
R = [cy * cz,   cz * sx * sy - cx * sz,     sx * sz + cx * cz * sy;
     cy * sz,   cz * cx + sx * sy * sz,     cx * sy * sz - cz * sz;
     -sy,       cy * sx,                    cx * cy];
 
 