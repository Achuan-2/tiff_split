function imgAvg = tiff_projection_avg(imgStack)
    imgAvg = mean(double(imgStack),3);
    imgAvg = im2uint8(mat2gray(imgAvg));
end