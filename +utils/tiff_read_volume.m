function varargout =  tiff_read_volume(filepath,nChannel)
    %tiff_read_volume - 读取Tiff图像的灰度值.
    %
    %   USAGE
    %       imgStack = tiff_read_volume(filepath);
    %       [imgCh1,imgCh2] = tiff_read_volume(filepath,'nChannel',2);
    %
    %   INPUT PARAMETERS
    %       filepath             -   图像文件的路径
    %       属性
    %         'nChannel'     -  默认为1
    %
    %   OUTPUT PARAMETERS
    %       imgStack         -   输出nChannel个图像
    
    % 设置默认参数
    arguments
        filepath string;
        nChannel double = 1;
    end


    % read info
    imgStack = tiffreadVolume(filepath);
    
    % 如果 Tif 只有一个通道，直接输出读的结果即可
    if nChannel == 1
        varargout{1} = imgStack;
        return
    end

    % 如果 Tif 有多个通道，则需要分割出各个通道图像
    varargout = cell(1,nChannel);
    for iChannel = 1:nChannel
        varargout{iChannel}= imgStack(:, :, iChannel:nChannel:end);
    end
end
