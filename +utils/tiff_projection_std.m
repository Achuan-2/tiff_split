function imgStd = tiff_projection_std(img)
    img = double(img);
    imgStd = std(img,0,3);
    imgStd = im2uint8(mat2gray(imgStd));
end