function [roadSeg, Bpts, BptsLR] = findRoad(semanticLabel, roadIdx, erodeSize)
% function roadSeg = findRoad(semanticLabel, roadIdx)
% find road region according to the semtantic label map and road label
% semanticLabel:    semantic label map
% roadIdx:          label of road category
% erodeSize:        size of template for eroding the road regions
% roadSeg:          road mask
% Bpts:             uv coordinates of all boundary points
% BptsLR:           uv coordinates of left and right boundary points

if ~exist('erodeSize', 'var')
    erodeSize = 11;
end

[hei,wid,c] = size(semanticLabel);
[num, c2] = size(roadIdx);
if c == 1 && c2 == c
    roadSeg = double(semanticLabel == roadIdx(1));
    if sum(roadSeg(:)) == 0
        if num >= 2
            roadSeg = zeros(hei,wid);
            for i = 2:num
                roadSeg = roadSeg | (semanticLabel == roadIdx(i));
            end
        else
            error('Can not detect road and sidewalk');
        end
    end
else
    if c == 3 && c2 == c
        roadSeg = double(semanticLabel(:,:,1) == roadIdx(1, 1) &...
            semanticLabel(:,:,2) == roadIdx(1, 2) & semanticLabel(:,:,3) == roadIdx(1, 3) );
        if sum(roadSeg(:)) == 0
            if num >= 2
                roadSeg = zeros(hei,wid);
                for i = 2:num
                    roadSeg = roadSeg | (semanticLabel(:,:,1) == roadIdx(i, 1) &...
                        semanticLabel(:,:,2) == roadIdx(i, 2) & semanticLabel(:,:,3) == roadIdx(i, 3));
                end
            else
                error('Can not detect road and sidewalk');
            end
        end
    else
        error(['The dims of semantic label and road index should be same!']);
    end
end

se = strel('disk',erodeSize);
roadSeg = imerode(roadSeg, se);

B = bwboundaries(roadSeg);
idx = [];
maximum = 0;
for i = 1:length(B)
    boundarySize = size(B{i}, 1);
    if boundarySize > maximum
        maximum = boundarySize;
        idx = i;
    end
end
Bpts = B{idx};
Bidx = (Bpts(:,2) - 1) * hei + Bpts(:,1);

roadSeg(Bidx) = 2;

BptsLR = zeros(hei, 4);
for i = 1:hei
    flag =  find(Bpts(:, 1) == i);
    if length(flag) > 2
        BptsLR(i, :) = [min(Bpts(flag, 2)), i, max(Bpts(flag, 2)), i];
    end
end
flag = BptsLR(:, 1);
BptsLR = BptsLR(flag, :);

end