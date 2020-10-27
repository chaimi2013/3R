function [depth, depthMinimum, depthMaximum] = depthProcessing(depth_map, depthLevel)
% function [depth, depthMinimum, depthMaximum] = depthProcessing(depth_map)
% replace the inf depth value
% depth_map:        input depth map
% depthLevel:       depth level in the depth map, e.g., 16 for uint16
% depth:            output depth map
% depthMinimum:     minimum of depth values
% depthMaximum:     maximum of depth values

if ~exist('depthLevel', 'var')
    depthLevel = 16;
end

depth = depth_map;

depthMaximum = (2^depthLevel - 1) / 100;
flagInf = (depth_map  == inf);
if ~isempty(flagInf)
    depthMaximum = min(depthMaximum, max(depth_map((~flagInf))) );
end

flag = (depth_map > depthMaximum);
depth(flag) = depthMaximum;

depthMinimum = min(depth(:));
