function varargout =  tiff_read_stack(filepath,varargin)
    %tiff_read_Volume - 读取Tiff图像的灰度值.
    %
    %   USAGE
    %       imgStack = tiff_read_stack(filepath);
    %       [imgCh1,imgCh2] = tiff_read_stack(filepath,'nChannel',2);
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
    info = imfinfo(filepath); 
    nFrames = numel(info)/nChannel; 
    firstFrame = imread(filepath,1); % 为了读取第一帧的数据类型
    
    
    % read image stack
    varargout = cell(1,nChannel);
    for iChannel = 1:nChannel
        varargout{iChannel} = zeros(info(1).Height, info(1).Width, nFrames, ...
            'like',firstFrame);
        for iFrame = 1:nFrames
            varargout{iChannel}(:, :, iFrame) = imread(filepath, ...
                'Index', nChannel*(iFrame-1)+iChannel, ...
                'Info', info);
        end
    end
end
