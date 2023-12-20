function tiff_save_lib(input_img, filepath, tagstruct)
%tiff_save_lib: Save a 3D image stack as a TIFF volume.
%
%   USAGE
%       tiff_save_lib(img, 'test.tif');
%       ---
%       tagstruct = tiff_read_tag('original.tif');
%       tiff_save_lib(img, 'test.tif', tagstruct);
%
%   Input Arguments
%       input_img     -   the input image,can be 2D or 3D.
%       filepath      -   Path to the TIFF file to be created.
%       tagstruct          -   Optional structure containing TIFF file tags.
%

    arguments
        input_img % the input image,can be 2D or 3D.
        filepath string % Path to the TIFF file to be created.
        tagstruct struct = struct() % Optional structure containing TIFF file properties.
    end
    if ~ismember(ndims(input_img),[2,3])
        error('The number of dimensions of the input image must be 2 or 3.');
    end

    % Set default TIFF file properties if info is not provided.
    if isempty(fieldnames(tagstruct))
        tagstruct = generate_tagstruct(input_img);
    end




    s=whos('input_img');
    if s.bytes > 2^31-1 % 2^32-1约等于4GB,但是考虑加上tag后，文件会偏大，所以设置为2^31-1
        t = Tiff(filepath,'w8');
    else
        t = Tiff(filepath,'w');
    end

    depth = size(input_img, 3);
    for d = 1:depth
        t.setTag(tagstruct);
        t.write(input_img(:, :, d));
        if d ~= depth
            % Tiff对象若需要写入多帧图片，需要使用writeDirectory，将IFD指向下一帧，才能继续写入
            t.writeDirectory();
        end
    end
    t.close();
end


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
    if ismember(class(input_img),{'uint8','uint16','uint32','logical'})
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    else
         tagstruct.SampleFormat = Tiff.SampleFormat.Int;
    end
   
    tagstruct.SamplesPerPixel = 1;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
end