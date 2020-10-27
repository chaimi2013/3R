function [roadLampXYZ, roadLampUV]= calRoadLampXYZ_cs(semanticLabel, depth, roadLabel, ...
    RT, K, C, roadLampZ, deltaY, erodeSize, xInterval, extraNum, DEBUG)
% function [roadLampXYZ, roadLampUV]= calRoadLampXYZ_cs(semanticLabel, depth, roadIdx, ...
%   RT, K, C, roadLampZ, erodeSize, xInterval)
% determine the road lamp positions adaptively using heuristic rules: 1)
% determin the road region; 2) locate the left and right boudaries; 3)
% locate the boudary points for a potential road lamp position (evenly
% spanned along X-axis); 4) extrapolated extra road lamps if needed; 5)
% calculate their XYZ coordinates. 5) Note that the above calculation is
% carried on the original resolution of semantic label map and depth map.
% Therefore, no downsampling issue should be addressed when calculating their 
% XYZ coordinates @camera coordinate system
% semanticLabel:        semantic label map
% depth:                depth map
% roadLabel:            label of road category
% RT:                   camera extrinsic parameters
% K:                    camera intrinsic parameters
% C:                    the C matrix for camera cooridinate system
% roadLampZ:            z cooridinate of road lamps (height)
% deltaY:               shift to the outside of road boundary along the Y-axis (for road lamp position)
% erodeSize:            size of template for eroding the road regions
% xInterval:            interval along the X-axis between adjacent road lamps
% extraNum:             number of extra road lamps to be extrapolated
% DEBUG:                flag for debugging (showing the projection and trajectory)
% roadLampXYZ:          xyz cooridinates of road lamps @camera coordinate systems
% roadLampUV:           uv cooridinates of road lamps @image plane


if ~exist('DEBUG', 'var')
    extraNum = 0;
end

if ~exist('DEBUG', 'var')
    DEBUG = 0;
end

%for cityscapes, rotate XYZ using C to change it to the vehichle coordinate
%(x: forward; y: left; z: upward)
% C = [0, 0, 1;
%     -1, 0, 0;
%     0, -1, 0];

% C^(-1) = [0, -1, 0;
%     0, 0, -1;
%     1, 0, 0];

%find road regions and the boundary points
[roadSeg, Bpts, BptsLR] = findRoad(semanticLabel, roadLabel, erodeSize);

%calcuate the XYZ coordinates of left and right boudary points @camera coordinate system
%the extrapolated Z will be better with polyfitting w.r.t. x
XYZL = calXYZFromUV_cs(RT, K, BptsLR(:,1:2), depth, C);
XYZR = calXYZFromUV_cs(RT, K, BptsLR(:,3:4), depth, C);
if size(XYZL,2) > 2
    pZL = polyfit(XYZL(1, :), XYZL(3, :), 1);
else
    pZL = [];
end
if size(XYZR,2) > 2
    pZR = polyfit(XYZR(1, :), XYZR(3, :), 1);
else
    pZR = [];
end

% sampleing road lamp position according to the inerval rule
% extend xInterval/2 backward along the X-axis, which is the starting point
xMin = min([XYZL(1, :), XYZR(1, :)]) - xInterval / 2; 
xMax = max([XYZL(1, :), XYZR(1, :)]);
roadLampNum = floor((xMax - xMin) / xInterval) + 1; %shift from current position (0) forward

% selected nearest boundary point and shift deltaY
roadLampXYZ = zeros(3, roadLampNum*2);
for i = 1:roadLampNum
    %current target x position according to the interval rule
    roadLampX = xMin + (i - 1) * xInterval;
    
    %find the nearest boundary point at the target x position (left/right)
    disL = abs(XYZL(1, :) - roadLampX);
    [~, idxL] = sort(disL);
    roadLampXYZ(:, (i-1)*2+1) = XYZL(:, idxL(1));
    roadLampXYZ(2, (i-1)*2+1) = roadLampXYZ(2, (i-1)*2+1) + deltaY; %left
    
    disR = abs(XYZR(1, :) - roadLampX);
    [~, idxR] = sort(disR);
    roadLampXYZ(:, i*2) = XYZR(:, idxR(1));
    roadLampXYZ(2, i*2) = roadLampXYZ(2, i*2) - deltaY; %right
end
roadLampXYZ(3, :) = roadLampXYZ(3, :) + roadLampZ; %road lamp height

% add extra points if needed
roadLampXYZExtra = zeros(3, (roadLampNum + extraNum*2)*2);
roadLampXYZExtra(:, 1:roadLampNum*2) = roadLampXYZ;
for i = 1:extraNum
    %add new light source in x-direction (forward and backward)
    %forward
    extra = roadLampXYZ(:, end-1:end);
    extra(1, :) = extra(1, :) + xInterval * i; 
    if ~isempty(pZL)
        extra(3, 1) = polyval(pZL, extra(1, 1)) + roadLampZ;
    end
    if ~isempty(pZR)
        extra(3, 2) = polyval(pZR, extra(1, 2)) + roadLampZ; 
    end
    roadLampXYZExtra(:, (roadLampNum+i-1)*2+1:(roadLampNum+i)*2) = extra; 
    
    %backward
    extra = roadLampXYZ(:, 1:2);
    extra(1, :) = extra(1, :) - xInterval * i; 
    if ~isempty(pZL)
        extra(3, 1) = polyval(pZL, extra(1, 1)) + roadLampZ;
    end
    if ~isempty(pZR)
        extra(3, 2) = polyval(pZR, extra(1, 2)) + roadLampZ; 
    end
    roadLampXYZExtra(:, (roadLampNum+extraNum+i-1)*2+1:(roadLampNum+extraNum+i)*2) = extra; 
end
roadLampXYZ = roadLampXYZExtra;

% calculate projected UV
roadLampUV = zeros(2, (roadLampNum+extraNum*2)*2);
for i = 1:roadLampNum + extraNum*2
    uv = K * ( C \ (RT * [roadLampXYZ(:, (i-1)*2+1); 1] ) );
    roadLampUV(:, (i-1)*2+1) = uv(1:2) / uv(3);
    
    uv = K * ( C \ (RT * [roadLampXYZ(:, i*2); 1] ) );
    roadLampUV(:, i*2) = uv(1:2) / uv(3);
end

if DEBUG
    figure; imshow(double(semanticLabel)/255 + repmat(roadSeg, [1 1 3]))
    hold on; plot(BptsLR(:,1), BptsLR(:, 2), 'ro')
    hold on; plot(BptsLR(:,3), BptsLR(:, 4), 'go')
%     flag = roadLampXYZ(1, :) > 0;
    flag = [1:(roadLampNum + extraNum*2)*2] <= roadLampNum*2;
    hold on; plot(roadLampUV(1, flag), roadLampUV(2, flag), 'b*', 'MarkerSize', 10);
    hold on; plot(roadLampUV(1, ~flag), roadLampUV(2, ~flag), 'bd', 'MarkerSize', 10);
    
    figure; 
    subplot(1,3,1); plot(-XYZL(2, :),  XYZL(1, :), 'ro'); axis equal
    hold on; plot(-XYZR(2, :), XYZR(1, :), 'go'); title('(-1)Y-X');
    hold on; plot(-roadLampXYZ(2, :), roadLampXYZ(1, :), 'b*', 'MarkerSize', 10);
    
    subplot(1,3,2); plot(XYZL(2, :),  XYZL(3, :), 'ro'); axis equal
    hold on; plot(XYZR(2, :), XYZR(3, :), 'go'); title('Y-Z');
    
    subplot(1,3,3); plot(XYZL(3, :),  XYZL(1, :), 'ro'); axis equal
    hold on; plot(XYZR(3, :), XYZR(1, :), 'go'); title('Z-X');
      
end

end