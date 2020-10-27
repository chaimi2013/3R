function rgb = sampleColor(gColor, p, etaBSig, fre, gCenInterval, candidateNum)
% function rgb = sampleColor(gColor, p, etaBSig, fre, gCenInterval, candidateNum)
% sample colors accoding to the prior blue/green distributions
% gColor:           green color candidates (evenly sampled)
% p:                the poly fit coefficients between blue and green colors
% etaBSig:          sigma of blue color at each green color candidate
% fre:              frequency at each green color candidate
% gCenInterval:     interval between two consecutive green bins (color candidates)
% candidateNum:     number of sampled colors

if ~exist('candidateNum', 'var')
    candidateNum = 1;
end

rgb = zeros(candidateNum, 3);
for i = 1:candidateNum
    freCum = cumsum(fre);
    prob = rand;
    idx = find(prob <= freCum);
    idx = idx(1);
    
    gColorCand = rand * gCenInterval * 2 + gColor(idx) - gCenInterval;
    
    bColorCen = 0;
    for k = 1:length(p)
        bColorCen = bColorCen + p(k) * gColorCand.^(length(p)-k);
    end
    bColorCandSig = etaBSig(idx);
    bColorCand = rand * bColorCandSig * 2 + bColorCen - bColorCandSig;
    
    rgb(i, :) = [1, gColorCand, bColorCand];
end