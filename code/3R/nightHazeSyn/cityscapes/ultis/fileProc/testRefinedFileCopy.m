%testRefinedFileCopy
close all; clear; clc;

root = 'ROOT\CityscapeDatasetsFoggy\depth_stereoscopic_trainvaltest\';
fileName = 'foggy_trainval_refined_filenames.txt';
fileLines = cell(1, 1000);
count = 1;
fid = fopen([root, fileName], 'rt');
while ~feof(fid)
    line = fgetl(fid);
    fileLines{1, count} = line;
    count = count + 1;
end
count = count - 1;
fileLines = fileLines(1:count);

rootSrc = [root, 'depth_stereoscopic_png\'];
rootDst = [root, 'depth_stereoscopic_png_refined\'];
for i = 1:count
    if mod(i, 100) == 0
        disp(['currently processing ', num2str(i), 'th img: ', fileLines{1, i}]);
    end
    imgName = [strrep(fileLines{1, i}, '/', '\'), '_depth_stereoscopic.png'];
    imgNameSrc = [rootSrc, imgName];
    [filepath, name, ext] = fileparts(imgName);
    if ~exist([rootDst, filepath])
        mkdir([rootDst, filepath]);
    end
    imgNameDst = [rootDst, imgName];
    copyfile(imgNameSrc, imgNameDst)
end