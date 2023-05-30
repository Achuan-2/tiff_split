function path= select_dir(defaultPath)

        f_dummy = figure('Position', [-100 -100 0 0]); %create a dummy figure so that uigetfile doesn't minimize our GUI
        if nargin < 1
            path = uigetdir();
        else
            path = uigetdir(defaultPath);
        end
        delete(f_dummy); %delete the dummy figure

end


