function imgAdjusted = tiff_adjust(filepath,img)
    imgAdjusted = imadjust(img);
    imwrite(imgAdjusted,filepath,'Compression','none');
end