function [startNum,endNum] = get_tiff_num_range(folder)
    % 获取所有以file_开头，以.tif结尾的文件信息
    files = dir(fullfile(folder, 'file_*.tif')); 
    % 获取文件名
    filenames = {files.name}; 
    % 获取文件名命名规则为 file_00001,file_00002,...file_00099 的文件名
    tifFiles = filenames(~cellfun(@isempty, regexp(filenames, '^file_\d{5}\.tif$', 'once')));
    % 获取文件名中的数字部分
    fileNums = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), tifFiles);
    % 获取起始和结束编号
    startNum = min(fileNums);
    endNum = max(fileNums);
end