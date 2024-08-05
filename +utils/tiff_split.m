function tiff_split(inputFilePath, numChannels, options)
    % tiff_split - 将多通道TIFF文件分割为单通道TIFF文件，并可选择去除涟漪噪
    %
    % 输入:
    %   inputFilePath   - 输入TIFF文件的完整路径 (字符串)
    %   numChannels     - 要分割的通道数 (正整数)
    %
    % 名称-值对参数:
    %   'FolderProcessed' - 存放分割后文件的文件夹路径 (字符串, 可选)
    %                       如果是相对路径，则作为输入文件目录的子文件夹
    %                       如果是绝对路径，则直接使用该路径
    %                       默认为输入文件目录下的'Processed'子文件夹
    %   'AvgOutput'       - 是否计算并保存平均投影 (逻辑值, 可选, 默认为true)
    %   'rippleNoise'     - 去除涟漪噪声的阈值 (数值, 可选, 默认为700)
    %                       将小于此阈值的像素值设为0，用于去除低强度噪声
    %
    % 示例:
    %   tiff_split('input.tif', 3)
    %   tiff_split('input.tif', 3, 'FolderProcessed', 'output_folder')
    %   tiff_split('input.tif', 3, 'FolderProcessed', 'C:\absolute\path\to\output')
    %   tiff_split('input.tif', 3, 'AvgOutput', true)
    %   tiff_split('input.tif', 3, 'rippleNoise', 500)
    %   tiff_split('input.tif', 3, 'FolderProcessed', 'output_folder', 'AvgOutput', true, 'rippleNoise', 600)
    %


    arguments
        inputFilePath (1,1) string
        numChannels (1,1) {mustBePositive, mustBeInteger}
        options.FolderProcessed (1,1) string = "Processed"
        options.AvgOutput (1,1) logical = true
        options.rippleNoise = 700
    end

    % 获取输入文件的目录
    [inputDir, inputName, inputExt] = fileparts(inputFilePath);
    
    % 判断FolderProcessed是否为绝对路径
    if isabs(options.FolderProcessed)
        folderProcessed = options.FolderProcessed;
    else
        folderProcessed = fullfile(inputDir, options.FolderProcessed);
    end
    
    % 创建输出文件夹（如果不存在）
    if ~exist(folderProcessed, 'dir')
        mkdir(folderProcessed);
    end
    
    % 获取TIF文件信息并验证
    info = imfinfo(inputFilePath);
    numFrames = numel(info);
    if numFrames <= numChannels
        warning("Tiff的帧数小于待分割的通道数")
        return
    end

    % 打开输入文件
    inputTiff = Tiff(inputFilePath, 'r');
    cleanupObj = onCleanup(@() close(inputTiff));

    % 创建输出文件
    outputTiffs = cell(1, numChannels);
    for ch = 1:numChannels
        outputFilePath = fullfile(folderProcessed, sprintf('%s_ch%d%s', inputName, ch, inputExt));
        outputTiffs{ch} = Tiff(outputFilePath, 'w');
    end

    % 初始化累加器和帧计数器
    accumulators = cell(1, numChannels);
    frameCounts = zeros(1, numChannels);

    % 处理每一帧
    tagstructs = struct();
    for frameIdx = 1:numFrames
        inputTiff.setDirectory(frameIdx);
        frame = inputTiff.read();
        channelIdx = mod(frameIdx - 1, numChannels) + 1;
            
        % remove ripple noise
        frame(frame<options.rippleNoise) = 0;
        % 转化为uint16
        frame = uint16(frame);


        % write 
        if isempty(fieldnames(tagstructs))
            try
                resolutionTags.XResolution = inputTiff.getTag('XResolution');
                resolutionTags.YResolution = resolutionTags.XResolution;
            catch
                resolutionTags = struct();
            end

            tags = resolutionTags;
            default_tags = generate_tagstruct(frame);
            if isempty(fieldnames(tags))
                % Set default TIFF file properties if info is not provided.
                tags = default_tags;
            else
                % 如果本身有传入options，传入的tag和默认tag进行合并
                fields1 = fieldnames(tags);
                fields2 = fieldnames(default_tags);
                % 遍历fields2
                for i = 1:length(fields2)
                    % 判断字段是否在fields1中存在
                    if ~ismember(fields2{i}, fields1)
                        % 如果不存在则将该字段添加到struct1中
                        tags.(fields2{i}) = default_tags.(fields2{i});
                    end
                end
            end
            tagstructs = tags;
        end
        outputTiffs{channelIdx}.setTag(tagstructs);
        outputTiffs{channelIdx}.write(frame);
        if frameIdx ~= numFrames
            outputTiffs{channelIdx}.writeDirectory();
        end
        % 累加图像并增加帧计数
        if options.AvgOutput
            if isempty(accumulators{channelIdx})
                accumulators{channelIdx} = single(frame);
            else
                accumulators{channelIdx} = accumulators{channelIdx} + single(frame);
            end
            frameCounts(channelIdx) = frameCounts(channelIdx) + 1;
        end
    end

    % 关闭所有输出文件
    cellfun(@close, outputTiffs);
    
    % 如果需要，计算并保存平均投影
    if options.AvgOutput
        for i = 1:numChannels
            avgFilename = sprintf('%s_ch%d_%d_Frames_AVG.tif', inputName, i, frameCounts(i));
            enhanceFilename = sprintf('%s_ch%d_%d_Frames_AVG_EnhanceContrast.tif', inputName, i, frameCounts(i));
            
            % 计算平均投影
            imgStackAvg = accumulators{i} / frameCounts(i);
            imgStackAvg = im2uint8(mat2gray(imgStackAvg));

            
            % 保存平均投影
            utils.tiff_save(imgStackAvg, fullfile(folderProcessed, avgFilename), resolutionTags);

            % 自动调整对比度并保存
            utils.tiff_save(imadjust(imgStackAvg), fullfile(folderProcessed, enhanceFilename), resolutionTags);
        end
    end
end

function tagstruct = generate_tagstruct(input_img)
    tagstruct.ImageLength = size(input_img, 1);
    tagstruct.ImageWidth = size(input_img, 2);
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    switch class(input_img)
        case {'uint8', 'int8'}
            tagstruct.BitsPerSample = 8;
        case {'uint16', 'int16'}
            tagstruct.BitsPerSample = 16;
        case {'uint32', 'int32'}
            tagstruct.BitsPerSample = 32;
        case {'single'}
            tagstruct.BitsPerSample = 32;
        case {'double', 'uint64', 'int64'}
            tagstruct.BitsPerSample = 64;
    end
    if ismember(class(input_img),{'uint8','uint16','uint32','logical'})
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    else
         tagstruct.SampleFormat = Tiff.SampleFormat.Int;
    end
    tagstruct.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
end
function result = isabs(path)
    % 判断路径是否为绝对路径
    if ispc
        % Windows系统
        result = ~isempty(regexp(path, '^[a-zA-Z]:\\', 'once')) || ...
                 ~isempty(regexp(path, '^\\\\', 'once'));
    else
        % Unix-like系统 (包括 macOS)
        result = startsWith(path, '/');
    end
end
