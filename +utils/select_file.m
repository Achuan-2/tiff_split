function [filename,path]= select_file(fileExtension)

        f_dummy = figure('Position', [-100 -100 0 0]); %create a dummy figure so that uigetfile doesn't minimize our GUI
        [filename,path] = uigetfile(fileExtension, 'Open');
        delete(f_dummy); %delete the dummy figure

end