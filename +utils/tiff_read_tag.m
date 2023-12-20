function tagstruct = tiff_read_tag(filepath)
    %tiff_read_tag - 读取 Tiff 图像的信息.
    %
    %   USAGE
    %       tagstruct = tiff_read_tag(path)
    %
    %   INPUT PARAMETERS
    %       filepath             -   图像文件的路径
    %
    %   OUTPUT PARAMETERS
    %       tagstruct         -   返回图像信息的struct数组
    t = Tiff(filepath, 'r');

    tagNames = {
    'ImageLength',
    'ImageWidth',
    'ImageDescription',
    'Artist',
    'ResolutionUnit',
    'XResolution',
    'YResolution',
    'Orientation',
    'Photometric',
    'BitsPerSample',
    'SamplesPerPixel',
    'SampleFormat',
    'RowsPerStrip',
    'PlanarConfiguration',
    'Software',
};
    tagstruct = struct();
    % 循环获取每个tag的值
    for k = 1:length(tagNames)
        try
            tagName = tagNames{k};
            tagValue = t.getTag(tagName);
            tagstruct.(tagName) = tagValue;
        catch
            %fprintf('Tag %s cannot be retrieved.\n', tagNames{k});
        end
    end
    t.close();
end