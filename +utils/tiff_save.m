function tiff_save(filepath,imgStack,tagstruct)
    s=whos('imgStack');
    if s.bytes > 2^32-1 % 约等于4GB
        t = Tiff(filepath,'w8');
    else
        t = Tiff(filepath,'w');
    end
    depth = size(imgStack, 3);
    for d = 1:depth
        t.setTag(tagstruct);
        t.write(imgStack(:, :, d));
        if d ~= depth
    	    % Tiff对象若需要写入多帧图片，需要使用writeDirectory，将IFD指向下一帧，才能继续写入
            t.writeDirectory();
        end
    end
    t.close();
end