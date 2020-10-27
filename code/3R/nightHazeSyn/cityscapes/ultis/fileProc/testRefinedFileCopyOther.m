%testRefinedFileCopyOther
close all; clear; clc;

root = 'ROOT\CityscapeDatasets\nighttimeHazy\';
fileName = 'foggy_trainval_refined_filenames.mat';
load([root, fileName]);
count = length(fileLines);

rootSrc = 'ROOT\CityscapeDatasets\processed\';
% folderName = 'leftImg8bit_trainvaltest\leftImg8bit\';
% ext = '_leftImg8bit.png';
folderName = 'gtFine_trainvaltest\gtFine\';
% ext = '_gtFine_color.png';
ext = '_gtFine_labelIds.png';

folderSrc = [rootSrc, folderName];
folderDst = [root, folderName];
for i = 1:count
    if mod(i, 100) == 0
        disp(['currently processing ', num2str(i), 'th img: ', fileLines{1, i}]);
    end
    imgName = [strrep(fileLines{1, i}, '/', '\'), ext];
    imgNameSrc = [folderSrc, imgName];
    
    [filepath, name, ~] = fileparts(imgName);
    if ~exist([folderDst, filepath])
        mkdir([folderDst, filepath]);
    end
    imgNameDst = [folderDst, imgName];
    if exist(imgNameSrc, 'file')
        copyfile(imgNameSrc, imgNameDst);
    else
       disp(['Can not find file: ', imgNameSrc]);
    end
end