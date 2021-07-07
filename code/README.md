# MRP
[Nighttime Dehazing with a Synthetic Benchmark](<a href="https://arxiv.org/abs/2008.03864">Arxiv</a>), ACM MM 2020.

The code has been tested on Win7/10 with Opencv 2.7.

## Installation
Please install opencv 2.4.9 (or copy "opencv_core249.dll" "opencv_highgui249.dll " "opencv_imgproc249.dll" from "OPENCV_DIR/build/x64/vc10/bin/" to the same directory with "NighttimeDehazeOSFD.exe") before running this code.

Then, run the executable code as: "NighttimeDehazeOSFD.exe name.bmp", where "name.bmp" is the input nighttime hazy image, the output dehazed result is named as "name_J_OSFD.bmp". Or run the executable code as: "NighttimeDehazeOSFD.exe name.bmp scale", where "scale" is a int type parameter that indicates the number of scales (1-10) in the OSFD algorithm. 

## Folder Structure
    OSFD
        -NighttimeDehazeOSFD.exe
            The executable code
        -*.dll
            The dependencies
        -*.bmp
            Test images

## Citation
Please cite our paper in your publications if it helps your research:

    @inproceedings{zhang2020nighttime,
        title={Nighttime Dehazing with a Synthetic Benchmark},
        author={Zhang, Jing and Cao, Yang and Zha, Zheng-Jun and Tao, Dacheng},
        booktitle={Proceedings of the 28th ACM International Conference on Multimedia},
        pages={2355--2363},
        year={2020}
    }
    
## Related Work
[1]. Nighttime haze removal based on a new imaging model, ICIP 2014. [NighttimeDehaze: github](https://github.com/chaimi2013/NighttimeDehaze)

[2]. Fast Haze Removal for Nighttime Image Using Maximum Reflectance Prior, CVPR 2017. [MRP_CVPR: github](https://github.com/chaimi2013/MRP)

[3]. Fully Point-wise Convolutional Neural Network for Modeling Statistical Regularities in Natural Images, ACM MM 2018. [FPC-Net: github](https://github.com/chaimi2013/FPCNet)
    
[4]. FAMED-Net: A Fast and Accurate Multi-scale End-to-end Dehazing Network, T-IP, 2019. [FAMED-Net: github](https://github.com/chaimi2013/FAMED-Net)
    
## Contact
[Email](zj.winner@163.com)
