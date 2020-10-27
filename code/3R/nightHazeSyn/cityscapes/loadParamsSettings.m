%loadParamsSettings
%for cityscapes dataset
%-----------------------------param config--------------------------------%
rng('shuffle');
if ~exist('param', 'var')
    %-----------------------------basic config--------------------------------%
    param = struct;
    param.root = 'G:\dataset\CityscapeDatasets\nighttimeHazy\';
    
    pathFileList = [param.root, 'foggy_trainval_refined_filenames.mat'];
    param.pathFileList = pathFileList;
    load(param.pathFileList);
    param.fileList = fileLines;
    param.frameNum = length(param.fileList);
    pathExt = [param.root, '\camera_trainvaltest\camera\'];
    param.pathExt = pathExt;
    pathRoadLampXYZ = [param.root, '\roadLampPos\'];
    param.pathRoadLampXYZ = pathRoadLampXYZ;
    pathImg = [param.root, '\leftImg8bit_trainvaltest\leftImg8bit\'];
    param.pathImg = pathImg;
    pathDepth = [param.root, '\depth_stereoscopic_png_refined\'];
    param.pathDepth = pathDepth;
    pathSeg = [param.root, '\gtFine_trainvaltest\gtFine\'];
    param.pathSeg = pathSeg;
    pathImgsSave = [param.root, '\syntheticNighttimeHazyImgs_T02\syntheticNighttimeHazyImgs_Batch1\'];
    if ~exist(pathImgsSave, 'dir')
        mkdir(pathImgsSave)
    end
    param.pathImgsSave = pathImgsSave;
else
    %-----------------------------specific config for each frame--------------------------------%
    if isfield(param, 'update') && param.update && isfield(param, 'fileName') && ~isempty(param.fileName)
        
        %load the road lamp position (XYZ @world coordinate system) file
        roadLampXYZFileName = [param.pathRoadLampXYZ, param.fileName, '_roadLampPos.mat'];
        if ~exist(roadLampXYZFileName, 'file')
            error(['please specify the roadLampXYZ file: ', roadLampXYZFileName]);
            param.roadLampXYZ = [];
        else
            load(roadLampXYZFileName);
            param.roadLampXYZ = roadLampXYZ;
            param.roadLampUV = roadLampUV;
        end
        
        %load camera parameters file
        cameraParamsFileName = [param.pathExt, param.fileName, '_camera.mat'];
        if ~exist(cameraParamsFileName, 'file')
            error(['please specify the cameraParams file: ', cameraParamsFileName]);
        else
            load(cameraParamsFileName);
            param.K = camera.K;
            param.RT = camera.RT;
            param.C = [0, 0, 1;
                -1, 0, 0;
                0, -1, 0];
        end
        
        %-----------------------------spx params--------------------------------%
        param.downSamplingRatio = 4;
        param.K(3,3) = param.downSamplingRatio; %update the scale factor in the homography form
        param.superpixelsNum = 2000; %2000, default for all experiments
        if param.downSamplingRatio > 1
            param.superpixelsNum = round(param.superpixelsNum / param.downSamplingRatio);
        end
        param.validPixelsForFitting = 1000 / param.downSamplingRatio^2; %10 / ratio
        param.handleInvalidPixelsForFitting = 1;
        
        %-----------------------------illumination param------------------------%
        param.lightAttenuationBeta = 1; %default: 0.5
        param.skyLabel = [70, 130, 180];
        
        param.usingLowPassFilteringAmbientIllumination = 0;
        if param.usingLowPassFilteringAmbientIllumination
            disp(['==> USE low pass filter to filter the ambilent illumination map...']);
        else
            disp(['==> DO NOT USE low pass filter to filter the ambilent illumination map...']);
        end
        
        param.usingImgReflectance = 0;
        if param.usingImgReflectance
            disp(['==> USE image reflectance...']);
        else
            disp(['==> DO NOT USE image reflectance...']);
        end
        
        param.isAggregate = 0;
        if param.isAggregate
            disp(['==> AGGREGATING incident lights IN calIncidentLightFromMultiLightSources...']);
        else
            disp(['==> AGGREGATING incident lights AFTER calIncidentLightFromMultiLightSources...']);
        end
        
        param.ambientLightUsingReflectance = 1;
        if param.ambientLightUsingReflectance
            disp(['==> USE reflectance when calculating ambient illumination']);
        else
            disp(['==> DO NOT use reflectance when calculating ambient illumination']);
        end
        
        param.globalIlluminationNormalization = 0;
        if param.globalIlluminationNormalization
            disp(['==> USE the maximum illumination from the first frame for illumination normalization subsequently (KITTI)']);
        else
            disp(['==> USE the maximum illumination from each frame for illumination normalization (CityScapes)']);
        end
        param.lightSourceColorsKeepFixed = 1;
        if param.lightSourceColorsKeepFixed
            disp(['==> KEEP lightSourceColors FIXED']);
        end
        
        %-----------------------------haze transmission--------------------------------%
        param.GF_r = 16;
        param.GF_epsilon = 0.001;
        param.GF_ds = 4;
        param.transmissionBeta = 0.02; %Luc, beta = 0.005, 0.01, 0.02
        
        %-----------------------------light source colors--------------------------------%
        %sample candidate road lamp colors
        pathColorStats = '.\..\core\';
        nightColorStats = load([pathColorStats, '\nightColorStats\nightColorStats.mat']);
        nightColorStats = nightColorStats.nightColorStats;
        nightColorStats.sampleNum = 1000;
        lightSourceColors = sampleColor(nightColorStats.gColor, nightColorStats.p, nightColorStats.etaBSig,...
            nightColorStats.fre, nightColorStats.gCenInterval, nightColorStats.sampleNum);
        nightColorStats.lightSourceColors = lightSourceColors;
        param.nightColorStats = nightColorStats;
        
        param.usingUniformLightSourceColors = 0;
        if param.usingUniformLightSourceColors
            %every single frame share the same, but they may be different in two frames
            disp(['==> use UNIFORM sampled colors for each road lamp']);
        else
            disp(['==> using DIFFERENT sampled colors for each road lamp']);
        end
        
        param.withGlow = 0;
        if param.withGlow > 0
            disp(['==> use glow scattering term: ', num2str(param.withGlow)]);
        end
        param.hazeScatteringWithConstantAirlihgt = 0.0;
        if param.hazeScatteringWithConstantAirlihgt > 0
            disp(['==> use constant air light in scattering term: ', num2str(param.hazeScatteringWithConstantAirlihgt)]);
        end
        %------------------------------------------------------------------------%
    end
end