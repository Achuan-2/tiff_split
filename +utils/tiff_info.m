function tagstruct = tiff_info(filepath)
    %tiff_read_volume - 读取 Tiff 图像的信息.
    %
    %   USAGE
    %       tagstruct = tiff_info(path)
    %
    %   INPUT PARAMETERS
    %       path             -   图像文件的路径
    %
    %   OUTPUT PARAMETERS
    %       tagstruct         -   返回图像信息的struct数组
    t = Tiff(filepath, 'r');
    tagstruct.ImageLength = t.getTag('ImageLength');
    tagstruct.ImageWidth = t.getTag('ImageWidth');
    tagstruct.ImageDescription = t.getTag('ImageDescription');
    tagstruct.Artist = t.getTag('Artist');
    tagstruct.ResolutionUnit = t.getTag('ResolutionUnit');
    tagstruct.XResolution = t.getTag('XResolution');
    tagstruct.YResolution = t.getTag('YResolution');
    tagstruct.Orientation = t.getTag('Orientation');
    tagstruct.Photometric = t.getTag('Photometric');
    tagstruct.BitsPerSample = t.getTag('BitsPerSample');
    tagstruct.SamplesPerPixel = t.getTag('SamplesPerPixel');
    tagstruct.SampleFormat = t.getTag('SampleFormat'); % Tiff.SampleFormat.Int/Tiff.SampleFormat.UInt
    tagstruct.RowsPerStrip = t.getTag('RowsPerStrip');
    tagstruct.PlanarConfiguration = t.getTag('PlanarConfiguration');
    tagstruct.Software = t.getTag('Software');
    t.close();
end
