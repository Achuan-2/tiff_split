
% 获取文件
folder = uigetdir();
% 定义开始和结束的文件序号
startIndex = 1;
endIndex = 6;

if folder == 0
    errordlg('未选择文件夹');
    return;
end


% 定义放置处理图像的文件夹
folderProcessed = fullfile(folder, 'Processed');
% 如果文件夹不存在，创建新的文件夹
if ~exist(folderProcessed, 'dir')
    mkdir(folderProcessed);
end


% 循环读取图像
for idx = startIndex:endIndex
    % 构建文件名
    filename = sprintf('file_%05d.tif', idx);
    fullpath = fullfile(folder, filename);
    
    % 分割通道
    [imgStackCh1,imgStackCh2] = utils.tiff_split(fullpath);
    
    % 消除PMT 的ripple noise：如果某个像素的灰度值小于700，就定义为0
    imgStackCh1(imgStackCh1 < 700) = 0;
    imgStackCh2(imgStackCh2 < 700) = 0;

    % 保存为channel tif
    [~, name, ext] = fileparts(filename);
    utils.tiff_save(fullfile(folderProcessed, [name,'_ch1',ext]),imgStackCh1);
    utils.tiff_save(fullfile(folderProcessed, [name,'_ch2',ext]),imgStackCh2);

    % 保存为average tif
    app.imgAvgCh1 = utils.tiff_save_avg(fullfile(folderProcessed, [name,'_ch1_AVG',ext]),imgStackCh1);
    app.imgAvgCh2 = utils.tiff_save_avg(fullfile(folderProcessed, [name,'_ch2_AVG',ext]),imgStackCh2);

end








