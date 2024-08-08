
A Matlab APP for split [scanimage](https://docs.scanimage.org/) multi-channel tiff file into single tiff file.


## 功能

主要功能
1. 多通道分割，可指定通道数分割，对大文件Tif分割（超过10GB）做了优化，小内存电脑也能轻松跑！分割过程显示进度条，分割过程可随时取消。
   ![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/Clip_2024-08-08_11-51-33-2024-08-08.png)
2. 分割之后额外保存平均图
   ![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/Clip_2024-08-08_12-15-19-2024-08-08.png)
3. 可选择一个文件夹进行统一分割，也可以选择单个文件分割
    ![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/Clip_2024-08-08_11-51-55-2024-08-08.png)
4. 打包为exe，可独立于Matlab运行
   ![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/Clip_2024-08-08_11-52-41-2024-08-08.png)

其他功能
1. 支持纠正多光子双向扫描成像造成的misalignment
2. 支持图像配准功能
