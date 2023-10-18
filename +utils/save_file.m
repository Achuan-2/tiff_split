function [filename,selectedDir]= save_file(fileExtension,matFile)
%save_file(  - 打开弹窗，保存文件
%
%   USAGE
%        [filename,selectedDir]= save_file()
%        [filename,selectedDir]= save_file({'.m'},'lastUsedImagePath.mat')
%
%   Input Arguments
%        fileExtension     -   默认保存文件的类型，默认为All Files (*.*)
%        matFile   -   保存上次选择路径的mat文件名
%
%   Output Arguments
%        filename          -   要保存文件的文件名
%        selectedDir       -   要保存文件的所在路径
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
            [filename,selectedDir] = uiputfile(fileExtension, 'Save as',lastUsedDir);
        else
            [filename,selectedDir] = uiputfile(fileExtension, 'Save as');
        end

        % if a dir is selected,save the path to lastUsedDir.mat
        if filename ~= 0
            lastUsedDir = selectedDir;
            save(lastUsedDirFile, 'lastUsedDir');
        end

        %delete the dummy figure
        delete(f_dummy); 

end
