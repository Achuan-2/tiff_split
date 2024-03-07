function resolution = tiff_get_resolution(filepath)
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
    resolution =t.getTag("XResolution");
    t.close();
end