function [filename,selectedDir]= select_file(fileExtension,matFile)
%select_file  - 打开弹窗，选择文件
%
%   USAGE
%        [filename,selectedDir]= select_file()
%        [filename,selectedDir]= select_file({'.m'},'lastUsedImagePath.mat')
%
%   Input Arguments
%        fileExtension     -   筛选显示文件类型，默认为All Files (*.*)
%        matFile   -   保存上次选择路径的mat文件名
%
%   Output Arguments
%        filename          -   所选文件的文件名
%        selectedDir       -   所选文件的所在路径
%


        %create a dummy figure so that uigetfile doesn't minimize our GUI
        f_dummy = figure('Position', [-100 -100 0 0]); 
        
        if  nargin < 1
            fileExtension = {'*.*',  'All Files (*.*)'};
        end
        if  nargin < 2
            matFile = 'lastUsedDir.mat';
        end

        filePath = mfilename('fullpath'); % get .m  script path
        [currentPath, ~, ~] = fileparts(filePath);
        lastUsedDirFile = fullfile(currentPath,matFile);
        if exist(lastUsedDirFile, 'file')
            load(lastUsedDirFile, 'lastUsedDir');
            [filename,selectedDir] = uigetfile(fileExtension, 'Select a file',lastUsedDir);
        else
            [filename,selectedDir] = uigetfile(fileExtension, 'Select a file');
        end

        % if a dir is selected,save the path to lastUsedDir.mat
        if filename ~= 0
            lastUsedDir = selectedDir;
            save(lastUsedDirFile, 'lastUsedDir');
        end

        %delete the dummy figure
        delete(f_dummy); 

end
