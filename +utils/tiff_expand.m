function tiff_expand(inputFilePath, outputFilePath, expansionFactor)
    % expandTiff - Expand a TIFF file by a given factor
    %
    % Syntax:
    %   expandTiff(inputFilePath, outputFilePath, expansionFactor)
    %
    % Description:
    %   This function reads a TIFF file from the specified input path,
    %   expands it by the given expansion factor, and saves the expanded
    %   TIFF file to the specified output path.
    %
    % Inputs:
    %   inputFilePath - string, path to the input TIFF file
    %   outputFilePath - string, path to save the expanded TIFF file
    %   expansionFactor - numeric, factor by which to expand the TIFF file
    %
    % Example:
    %   expandTiff('input.tif', 'output.tif', 50)
    
    arguments
        inputFilePath (1,1) string
        outputFilePath (1,1) string
        expansionFactor (1,1) {mustBePositive, mustBeInteger}
    end
    
    % 获取输入文件信息
    fileInfo = dir(inputFilePath);
    inputFileSize = fileInfo.bytes;
    info = imfinfo(inputFilePath);
    numFrames = numel(info);
    
    % 计算输出文件大小
    estimatedOutputFileSize = inputFileSize * expansionFactor;
    
    % 决定是否使用BigTiff
    useBigTiff = estimatedOutputFileSize > 4 * 1024^3; % 4GB in bytes
    
    % 创建输出文件
    if useBigTiff
        outputTiff = Tiff(outputFilePath, 'w8'); % 使用BigTiff格式
        disp('使用BigTiff格式存储输出文件');
    else
        outputTiff = Tiff(outputFilePath, 'w');
        disp('使用标准Tiff格式存储输出文件');
    end
    
    % 读取输入文件信息
    inputTiff = Tiff(inputFilePath, 'r');
    
    % 读取第一帧以获取图像信息
    inputTiff.setDirectory(1);
    A = inputTiff.read();
    
    % 生成tagstruct
    tagstruct = generate_tagstruct(A);
    tagstruct.Software = 'MATLAB';
    
    % 逐帧处理
    for k = 1:numFrames
        % 读取一帧
        inputTiff.setDirectory(k);
        A = inputTiff.read();
        
        % 写入expansionFactor次
        for i = 1:expansionFactor
            outputTiff.setTag(tagstruct);
            outputTiff.write(A);
            if (k < numFrames) || (i < expansionFactor)
                outputTiff.writeDirectory();
            end
        end
        
        % 显示进度
        fprintf('已处理 %d/%d 帧\n', k, numFrames);
    end
    
    % 关闭文件
    inputTiff.close();
    outputTiff.close();
    
    % 计算并显示输出文件大小
    outputFileInfo = dir(outputFilePath);
    outputFileSize = outputFileInfo.bytes;

    
    fprintf('处理完成\n');
    fprintf('原文件大小: %.2f GB\n', inputFileSize/ (1024^3));
    fprintf('扩充倍数: %d 倍\n', expansionFactor);
    fprintf('输出文件大小: %.2f GB\n', outputFileSize / (1024^3));
    
    % 辅助函数：生成tagstruct
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
        
        if ismember(class(input_img), {'uint8', 'uint16', 'uint32', 'logical'})
            tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
        else
            tagstruct.SampleFormat = Tiff.SampleFormat.Int;
        end
        
        tagstruct.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
        tagstruct.SamplesPerPixel = 1;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    end
end
