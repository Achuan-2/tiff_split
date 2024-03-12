function imgStack = correct_scanphase(imgStack,offset)
    if offset > 0
        imgStack(2:2:end,offset+1:end,: ) = imgStack(2:2:end,1:end-offset,:);
    else
        imgStack(2:2:end,1:end+offset,:)  = imgStack(2:2:end, 1-offset:end,:);
    end
    % 注意不能是imgStack(2:2:end, :,:) =  circshift(imgStack(2:2:end,
    % :,:),offset,2);会导致一侧有交错条纹
end