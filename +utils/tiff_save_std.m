function imgStd = tiff_save_std(filepath,imgStack)
    
    if  isa(imgStack, 'uint16')
        imgMin = min(imgStack(:));
        imgMax = max(imgStack(:));
        imgOutput = (imgStack-imgMin)/(imgMax-imgMin)*255;
        imgOutput = double(imgOutput);
        imgStd = std(imgOutput,0,3);
    else
        imgStd = std(imgStack,0,3);
    end
    imwrite(uint8(imgStd),filepath,'Compression','none');
end