function [filename,selectedDir] = select_file(fileExtension,default_path)
%select_dir - 打开弹窗，选择文件夹
%
%   USAGE
%        [filename,selectedDir] = select_file() % 选择任意一个文件
%        [filename,selectedDir]= select_file({'.m'},'D:/') % 选择 D盘指定文件
%
%   Input Arguments
%        fileExtension     -   默认保存文件的类型，默认为All Files (*.*)
%        default_path      -   默认先打开的路径
%
%   Output Arguments
%        filename          -   所选文件的文件名
%        selectedDir       -   所选文件的所在路径
%
        arguments
            fileExtension = {'*.*',  'All Files (*.*)'};
            default_path = ''
        end
        % create a dummy figure so that uigetfile doesn't minimize our GUI
        % ref: https://ww2.mathworks.cn/matlabcentral/answers/296305-appdesigner-window-ends-up-in-background-after-uigetfile
        f_dummy = figure('Position', [-100 -100 0 0],'CloseRequestFcn','');  
  
  

        [filename,selectedDir] = uigetfile(fileExtension, 'Select a file',default_path);


        delete(f_dummy); %delete the dummy figure
end