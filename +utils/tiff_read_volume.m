function varargout =  tiff_read_volume(filepath,varargin)
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
    p = inputParser;            % 函数的输入解析器
    addParameter(p,'nChannel',1);      % 设置变量名和默认参数
    parse(p,varargin{:});       % 对输入变量进行解析，如果检测到前面的变量被赋值，则更新变量取值
    nChannel = p.Results.nChannel;   

    % read info
    imgStack = tiffreadVolume(filepath);
    
    % 如果 Tif 只有一个通道，直接输出读的结果即可
    if nChannel == 1
        varargout{1} = imgStack;
        return
    end

    % 如果 Tif 有多个通道，则需要分割出各个通道图像
    [height, width, nSlices] = size(imgStack);
    nFrames = nSlices/nChannel;
    dataType = class(imgStack);



    varargout = cell(1,nChannel);
    for iChannel = 1:nChannel
        varargout{iChannel} = zeros(height, width, nFrames, dataType);
        for iFrame = 1:nFrames
            varargout{iChannel}(:, :, iFrame) = imgStack(:, :, nChannel*(iFrame-1)+iChannel);
        end
    end
end
