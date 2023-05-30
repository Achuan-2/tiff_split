function imgStackCombine =  tiff_combine(imgStack)
    nFrames = size(imgStack,3); % 获取总帧数
    imageSize = size(imgStack,1); 
    realFrames = nFrames/10;
    imgStackCombine = zeros(imageSize, imageSize,realFrames );
    
    colNum = floor(imageSize/10);
    % 把10帧图片合并为一帧，合并的规则为取第i帧的i:10:512列
    for iframe = 1:realFrames
        temp_frame =  zeros(imageSize, imageSize);
        count = 1; %计数，十帧里的哪一帧
        for i = 1:10
            img = imgStack(:, :, 10*(iframe-1)+count);
            start_f = i;
            if start_f>10
                % 如果i大于10，自动处理
                start_f = start_f -10;
            end

            start_col = (start_f-1)*colNum +1 ;

            if start_f == 10 % 如果是i=10的填充
                temp_frame(:,start_col:end) = img(:,start_col:end);
            else
                fill_col = start_col:start_col+colNum-1;
                temp_frame(:,fill_col) = img(:,fill_col);
            end

            count = count +1;
        end
        imgStackCombine(:,:,iframe) = temp_frame;
    end
end
% function imgStackCombine =  tiff_combine(imgStack)
%     nFrames = size(imgStack,3);
%     imageSize = size(imgStack,1);
%     realFrames = nFrames/10;
%     imgStackCombine = zeros(imageSize, imageSize,realFrames );
% 
%     % 把10帧图片合并为一帧，合并的规则为取第i帧的i:10:512列
%     for iframe = 1:realFrames
%         temp_frame =  zeros(imageSize, imageSize);
%         count = 1;
%         for i = 1:10
%             img = imgStack(:, :, 10*(iframe-1)+count);
%             start = i;
%             if start>10
%                 start = start -10;
%             end
%             fill_col = start:10:imageSize;
%             temp_frame(:,fill_col) = img(:,fill_col);
% 
%             count = count +1;
%         end
%         imgStackCombine(:,:,iframe) = temp_frame;
%     end
% end