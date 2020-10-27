function mapping = spxLabel2InstanceLabelMapping(instanceLabel, spxLabels, spxLabelsNum)
% function mapping = spxLabel2InstanceLabelMapping(instanceLabel, spxLabels, spxLabelsNum)
% instanceLabel:    instance label map
% spxLabels:        super-pixel label map
% spxLabelsNum:     number of super-pixels
% mapping:          mapping from spxLabels to instancelabel

imgSize = size(instanceLabel, 1) * size(instanceLabel, 2);
mapping = zeros(4, spxLabelsNum);
for i = 1:spxLabelsNum
    index = find(spxLabels == i-1);
    index = index(1);
    label = [instanceLabel(index); instanceLabel(index+imgSize); instanceLabel(index+imgSize*2)];
    
    mapping(:, i) = [i-1; label];
end

end