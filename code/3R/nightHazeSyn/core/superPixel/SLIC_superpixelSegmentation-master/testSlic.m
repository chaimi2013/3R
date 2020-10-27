%testSlic
close all; clear; clc;

pathImg = 'H:\Datasets\AutoDriveDatasets\VirtualKitti\vkitti_1.3.1_rgb\0001\clone\';
pathDepth = 'H:\Datasets\AutoDriveDatasets\VirtualKitti\vkitti_1.3.1_depthgt\0001\clone\';
pathSeg = 'H:\Datasets\AutoDriveDatasets\VirtualKitti\vkitti_1.3.1_scenegt\0001\clone\';

imgNo = 0;
imgName = sprintf('%05d.png', imgNo);
img = imread([pathSeg, imgName]);
imgV = double(max(img, [], 3)) / 255;
superpixelsNum = 2000; %default: 500

[labels1, numlabels1] = slicmex(img,superpixelsNum,20);%numlabels is the same as number of superpixels
[labels2, numlabels2] = slicomex(img,superpixelsNum);%numlabels is the same as number of superpixels


figure;
imagesc([labels1; labels2]);

labels2 = double(labels2);
imgOlp = imgV .* labels2 / max(labels2(:));
figure; imagesc([imgOlp]); axis image;