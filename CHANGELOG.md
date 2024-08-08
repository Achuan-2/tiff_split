TODO

- [ ] scanphase 现在是分割通道保存文件再读取文件进行预测，而不是分割通道的同时进行预测，读写会耗时。看看能不能优化

## v2.2 / 2024.08.07

* ✨`tiff_split`函数优化大文件的保存，检测[文件大小/通道数] 是否大于4GB，是的话，则用BigTiff格式保存，否则则用标准Tiff保存
* ✨`tiff_split`函数支持显示进度条
* ✨鉴于现在改成了一帧一帧读取，所以分割一个文件的是否也可以直接中断了！
* ✨美化了下进度条，用html解析，对文件数和当前处理帧数进行加粗
* ✨配准的进度条添加`Indeterminate=on`参数，有一个进度条持续变化，不那么枯燥
* 💄界面优化：nChannel的Spinner调窄，start和end放在一排

## v2.1 / 2024.08.05

-✨ 优化大文件读取，新建函数tiff_split：以前分割通道是读取一整个stack之后，再分，会占用比较大内存，文件一大就分割很慢；现在是一帧帧读取，直接把当前帧写入文件里
    - 不过目前有一个问题，就是因为现在是读取一帧就分通道，而之前写的scanphase预测是需要整个imgStack的，所以就需要分割完之后读取，再预测scanphase，会增加读写耗时，不过考虑到scanphase预测不是一个很必要的操作，暂时就不管了，以后有空看看能不能优化

- 🐛 修复一些bug
- ✨优化终端输出，try报错会参考scanimage的方式，可以通过点击参考信息

## v2.0 /2024.08.04

- ✨ 支持调用suite2p配准，支持GPU加速
- 🐛 修复Console显示报错的信息，显示的都是上一次报错的问题（原因是 `warning`函数返回上一次报错）

## v1.9 / 2024.03.12

- ✨ 支持选择通道数目
- ✨ config不加载窗口大小
- ✨ config支持保存nChannel
- ✨ 优化config.json的保存路径：之前是打包为exe，就会创建在桌面，现在希望是放在exe的所在位置

## v1.8 / 2024.03.12

- ✨ 支持预测双向扫描的misalignment，并进行校正
- ✨ 支持选择单个文件，支持切换文件夹还是文件模式

## v1.7 / 2024.03.07

- ✨ 改进Tiff读取和保存，加快读写速度
- ✨ 精简Tiff的信息，只保留resolution信息

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
