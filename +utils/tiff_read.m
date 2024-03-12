function varargout = tiff_read(filepath, nChannel)
    %tiff_read_volume - 读取Tiff图像的灰度值.
    %
    %   USAGE
    %       imgStack = tiff_read(filepath);
    %       [imgCh1,imgCh2] = tiff_read(filepath,2);
    %
    %   INPUT PARAMETERS
    %       filepath             -   图像文件的路径
    %       属性
    %         'nChannel'     -  默认为1
    %
    %   OUTPUT PARAMETERS
    %       imgStack         -   输出nChannel个图像
    arguments
        filepath string;
        nChannel double = 1;
    end

    t = Tiff(filepath, 'r');

    % get file parameters
    iminfo = imfinfo(filepath); % 由于Tiff库没有记录总帧数，使用imfinfo来获取帧数
    num_frame = length(iminfo);
    w = t.getTag('ImageWidth');
    h = t.getTag('ImageLength');

    % Initialize image data array
    img = read(t);
    imgStack = zeros(h, w, num_frame, class(img));
    imgStack(:, :, 1) = img;

    for i = 2:num_frame
        nextDirectory(t);
        imgStack(:, :, i) = read(t);
    end

    t.close()

    % 如果 Tif 只有一个通道，直接输出读的结果即可
    if nChannel == 1
        varargout{1} = imgStack;
        return
    end

    % 如果 Tif 有多个通道，则需要分割出各个通道图像
    varargout = cell(1, nChannel);

    for iChannel = 1:nChannel
        varargout{iChannel} = imgStack(:, :, iChannel:nChannel:end);
    end

end