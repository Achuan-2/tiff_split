## v1.8 / 2024.03.12

- ✨ 支持预测双向扫描的misalignment，并进行校正
- ✨ 支持选择单个文件，支持切换文件夹还是文件模式

## v1.7 / 2024.03.07

- ✨ 改进Tiff读取和保存，加快读写速度

## v1.6 / 2024.01.11

* 🔥平均图文件名再添加回帧数，感觉还是有意义的
* ✨平均图添加resolution信息

## v1.5/2024.01.08

- 文件后缀去掉帧数
- 递增模式连续点击Update适配
    * 新增一个文件后反复点击Update，start index和end index，保持不变，都为最后一个文件索引
    * file00001-file00003没有处理过，反复点击Update，保持不变

## v1.0/2023.10.18 Support for Saving and Loading Configurations
- Upon software startup, check if the config_para.json file exists. If not, create a new one. The saved contents include figure position, ripple_noise, and select_folder.
- Before software shutdown, save the current config settings to the file.