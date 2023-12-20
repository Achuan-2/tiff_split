function imgStd = tiff_projection_std(imgStack)
    imgStack = double(imgStack);
    imgStd = std(imgStack,0,3);
    imgStd = im2uint8(mat2gray(imgStd));
end