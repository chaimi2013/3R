function map = vec2map(vec, spxLabels)
% function map = vec2map(vec, mapSize)
% transform the super-pixel-based incident light to map
% vec:          vecotrs to be transformed (NumLight x NumSpx)
% spxLabels:    super-pixel label map; hei x wid
% map:          transformed map: hei x wid x NumLight

[hei,wid] = size(spxLabels);
spxLabelsNum = size(vec,2);
c = size(vec,1);
map = zeros(hei,wid,c);

for i = 1:spxLabelsNum
    idx = find(spxLabels == i-1);
    for cc = 1:c
        map(idx + (cc-1)*hei*wid) = vec(cc, i);
    end
end