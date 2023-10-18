function selectedDir = select_dir(default_path)
%select_dir - 打开弹窗，选择文件夹
%
%   USAGE
%        selectedDir = select_dir()
%        selectedDir = select_dir(default_path)
%
%   Input Arguments
%        matFile   -   保存上次选择路径的mat文件名
%
%   Output Arguments
%        selectedDir       -   所选文件的所在路径
        arguments
            default_path = ''
        end
        % create a dummy figure so that uigetfile doesn't minimize our GUI
        f_dummy = figure('Position', [-100 -100 0 0]);
        

        selectedDir = uigetdir(default_path);

        

        delete(f_dummy); %delete the dummy figure
end