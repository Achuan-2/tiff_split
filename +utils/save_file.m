function [filename,path]= save_file(fileExtension)
% fileExtension: {'*.jpg';'*.png';'tif'}
	f_dummy = figure('Position', [-100 -100 0 0]); %create a dummy figure so that uigetfile doesn't minimize our GUI
	[filename, path] = uiputfile(fileExtension, 'Save as');
	delete(f_dummy); %delete the dummy figure
end