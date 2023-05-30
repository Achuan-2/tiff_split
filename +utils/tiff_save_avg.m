function imgOutput = tiff_save_avg(filepath,imgStack)
    imgAvg = mean(imgStack,3);
    if  ~isa(imgStack, 'uint8')
        % 如果输入图像不是uint8，归一化为0-255，设置为uint8格式
        imgMin = min(imgAvg(:));
        imgMax = max(imgAvg(:));
        imgOutput = (imgAvg-imgMin)/(imgMax-imgMin)*255;
        imgOutput = uint8(imgOutput);
    else
        imgOutput = imgAvg;
    end
    imwrite(imgOutput,filepath,'Compression','none');
end