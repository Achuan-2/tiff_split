## v1.5/2024.01.08
- 文件后缀去掉帧数
- 递增模式连续点击Update适配
    * 新增一个文件后反复点击Update，start index和end index，保持不变，都为最后一个文件索引
    * file00001-file00003没有处理过，反复点击Update，保持不变

## v1.0/2023.10.18 Support for Saving and Loading Configurations
- Upon software startup, check if the config_para.json file exists. If not, create a new one. The saved contents include figure position, ripple_noise, and select_folder.
- Before software shutdown, save the current config settings to the file.