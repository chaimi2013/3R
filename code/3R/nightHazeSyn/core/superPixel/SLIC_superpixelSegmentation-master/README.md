#SLIC_superpixelSegmentation
This is the revision of the original implementation, which has mex errors in windows

Please check the segmentation results at:  
input:  https://github.com/DUTFangXiang/SLIC__superpixelSegmentation/blob/master/0007.jpg
output: https://github.com/DUTFangXiang/SLIC__superpixelSegmentation/blob/master/0007_SLIC.jpg
  
#Note:
##reference: 
[1]. Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk, SLIC Superpixels Compared to State-of-the-art Superpixel Methods, IEEE Transactions on Pattern Analysis and Machine Intelligence, vol. 34, num. 11, p. 2274 - 2282, May 2012.
    
[2]. Radhakrishna Achanta, Appu Shaji, Kevin Smith, Aurelien Lucchi, Pascal Fua, and Sabine Süsstrunk, SLIC Superpixels, EPFL Technical Report no. 149300, June 2010.
          
##Revision
The original compiling error "slicmex.c(387) : error C2275: "mwSize"..." is a typical error in c programmes. 
Please refer to http://blog.csdn.net/fx677588/article/details/53694406
Declare the variable mwSize before the function, which is originally defined in Line 387