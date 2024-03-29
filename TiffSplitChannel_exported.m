classdef TiffSplitChannel_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TiffSplitChannelUIFigure       matlab.ui.Figure
        FolderDropDown                 matlab.ui.control.DropDown
        ScanphaseSpinner               matlab.ui.control.Spinner
        ScanphaseCorrectDropDown       matlab.ui.control.DropDown
        ScanphaseCorrectDropDownLabel  matlab.ui.control.Label
        RippleNoiseSpinner             matlab.ui.control.Spinner
        RippleNoiseSpinnerLabel        matlab.ui.control.Label
        ConsoleTextArea                matlab.ui.control.TextArea
        ConsoleTextAreaLabel           matlab.ui.control.Label
        OutputFolderEditField          matlab.ui.control.EditField
        OutputFolderEditFieldLabel     matlab.ui.control.Label
        EndIndexSpinner                matlab.ui.control.Spinner
        EndIndexSpinnerLabel           matlab.ui.control.Label
        StartIndexSpinner              matlab.ui.control.Spinner
        StartIndexSpinnerLabel         matlab.ui.control.Label
        FolderEditField                matlab.ui.control.EditField
        RippleNoiseCheckBox            matlab.ui.control.CheckBox
        OpenFolderButton               matlab.ui.control.Button
        UpdateButton                   matlab.ui.control.Button
        TiffLabel                      matlab.ui.control.Label
        TiffRangeLabel                 matlab.ui.control.Label
        ProcessButton                  matlab.ui.control.Button
        FileSelectButton               matlab.ui.control.Button
    end

    
    properties (Access = private)
        folder; % 存放scanimage成像 tiff 的文件夹
        tiffpath; % 选择单个文件进行处理，保存文件路径
        index_updated = false; % 是否选择文件夹并且点击update成功update了
        fileStartIndex; 
        fileEndIndex; 
        lastEndIndex;
        onlyOne = false;
        processed = 0;
        cellArrayText;
    end
    
    methods (Access = private)

        
        function update_tiff_index(app)
            % 获取指定文件的编号范围
            [app.fileStartIndex,app.fileEndIndex] = utils.get_tiff_num_range(app.folder);

            if isempty(app.fileEndIndex)
                errordlg('该文件夹不存在tif图片！');
                app.StartIndexSpinner.Enable = "off";
                app.EndIndexSpinner.Enable = "off";
                app.ProcessButton.Enable = "off";
                app.OpenFolderButton.Enable = "off";
                return;
            end
            
            fileNum = app.fileEndIndex- app.fileStartIndex+1;

            if fileNum > 1
                app.EndIndexSpinner.Limits = [app.fileStartIndex,app.fileEndIndex];
                app.StartIndexSpinner.Limits = [app.fileStartIndex,app.fileEndIndex];
                app.onlyOne = false;
            else
                app.onlyOne = true;
            end
            % 更新文件编号范围
            app.TiffRangeLabel.Text = sprintf('file_%05d ~ file_%05d', app.fileStartIndex,app.fileEndIndex);

            % 点击Update，更新start index 和 end index
            app.StartIndexSpinner.Value = app.fileStartIndex;
            app.EndIndexSpinner.Value =  app.fileEndIndex;

            if  ~isempty(app.lastEndIndex) 
                if app.lastEndIndex == app.fileEndIndex
                    % 反复点击update，而文件没有新增，strat index依然为上次处理的文件编号
                    app.StartIndexSpinner.Value = app.lastEndIndex;
                elseif app.lastEndIndex < app.fileEndIndex
                    % 如果文件新增，strat index为上次处理的文件编号+1
                    app.StartIndexSpinner.Value = app.lastEndIndex+1;
                end
            end

            % update ui
            app.StartIndexSpinner.Enable = "on";
            app.EndIndexSpinner.Enable = "on";
            app.ProcessButton.Enable = "on";
            app.OpenFolderButton.Enable = "on";
            app.RippleNoiseCheckBox.Enable = "on";
            app.index_updated = true;
        end
        
        function print_console(app,str)
            time = datetime("now","Format","HH:mm:ss");
            string = sprintf('%s\n%s\n', time,str); % 将数据格式化为字符串或字符向量
            app.cellArrayText=horzcat(app.cellArrayText,string); % 水平串联数组
            app.ConsoleTextArea.Value = app.cellArrayText; % 给TextArea赋值
        end
        
        function process_folder(app)
            % 定义放置处理图像的文件夹
            folderProcessed = fullfile(app.folder, app.OutputFolderEditField.Value);

            % 如果文件夹不存在，创建新的文件夹
            if ~exist(folderProcessed, 'dir')
                mkdir(folderProcessed);
            end


            % 指定的起始和结束编号
            startIdx = app.StartIndexSpinner.Value;
            endIdx = app.EndIndexSpinner.Value;

            % 调用进度条
            progressDlg = uiprogressdlg(app.TiffSplitChannelUIFigure,'Title','Processing',...
                'Message','1','Cancelable','on');
            numFiles = endIdx-startIdx+1; % 要处理的文件
            count = 1; % 开始计数
            isRight = true;
            for idx = startIdx:endIdx
                % 为了进度条的取消可以中断处理
                if progressDlg.CancelRequested
                    break
                end

                % 构建文件名
                try
                    filename = sprintf('file_%05d.tif', idx);
                    filepath = fullfile(app.folder, filename);
                    progressDlg.Message = sprintf('Processing %d/%d files: %s', count, numFiles, filename);

                    % 分割通道
                    split_channel(app,filepath,folderProcessed);
                    
                    % 处理完成
                    app.print_console(sprintf('Processed: file_%05d.tif', idx));
                catch ME
                    if ME.identifier == "MATLAB:imagesci:imfinfo:fileOpen"
                        app.print_console(warning('文件正在生成，请稍后再试'));
                    else
                        app.print_console(warning(ME.message));
                    end

                    isRight =false;
                end
                % Update progress, report current estimate
                progressDlg.Value = count/numFiles;
                count = count + 1;

            end
            if isRight
                app.lastEndIndex = app.fileEndIndex;
            end
            % Close the dialog box
            close(progressDlg)
        end


        function process_single_file(app)
            % 定义放置处理图像的文件夹
            [directory, fname, fext] = fileparts(app.tiffpath);
            filename = strcat(fname, fext);
            folderProcessed = fullfile(directory, app.OutputFolderEditField.Value);

            % 如果文件夹不存在，创建新的文件夹
            if ~exist(folderProcessed, 'dir')
                mkdir(folderProcessed);
            end

            % 调用进度条
            progressDlg = uiprogressdlg(app.TiffSplitChannelUIFigure,'Title','Processing',...
                'Message','1');


            % 构建文件名
            try
                progressDlg.Message = sprintf('Processing files: %s', filename);

                % 分割通道
                split_channel(app,app.tiffpath,folderProcessed);

                % 处理完成
                app.print_console(sprintf('Processed: %s', app.tiffpath));
            catch ME
                if ME.identifier == "MATLAB:imagesci:imfinfo:fileOpen"
                    app.print_console(warning('文件正在生成，请稍后再试'));
                else
                    app.print_console(warning(ME.message));
                end

            end


            % Close the dialog box
            close(progressDlg)
        end
        
        function split_channel(app,filepath,folderProcessed)
            [imgStackCh1,imgStackCh2] = utils.tiff_read(filepath,2);

            % 把scanimage的int16图像设置为uint16
            imgStackCh1 = uint16(imgStackCh1);
            imgStackCh2 = uint16(imgStackCh2);


            % 消除PMT 的ripple noise：如果某个像素的灰度值小于700，就定义为0
            rippleNoise = app.RippleNoiseSpinner.Value;
            imgStackCh1(imgStackCh1 < rippleNoise) = 0;
            imgStackCh2(imgStackCh2 < rippleNoise) = 0;

            % scanphase correct
            switch app.ScanphaseCorrectDropDown.Value
                case 'Fixed'
                    scanphase_offset = app.ScanphaseSpinner.Value;
                case {'Off'}
                    scanphase_offset = 0;
                case {'Auto'}
                    scanphase_offset = utils.predict_scanphase(imgStackCh1);
                    app.print_console(sprintf("Scanphase predicted: %d",scanphase_offset));
            end
            if scanphase_offset
                imgStackCh1 = utils.correct_scanphase(imgStackCh1,scanphase_offset);
                imgStackCh2 = utils.correct_scanphase(imgStackCh2,scanphase_offset);
            end

            % 获取分辨率信息
            tagstruct.XResolution = utils.tiff_get_resolution(filepath);
            tagstruct.YResolution = tagstruct.XResolution;

            % 保存为channel tif
            [~, fname, fext] = fileparts(filepath);
            utils.tiff_save(imgStackCh1,fullfile(folderProcessed, [fname,'_ch1',fext]),tagstruct);
            utils.tiff_save(imgStackCh2,fullfile(folderProcessed, [fname,'_ch2',fext]),tagstruct);

            % 保存为average tif
            frames = size(imgStackCh1,3);
            imgStackCh1Avg = utils.tiff_projection_avg(imgStackCh1);
            utils.tiff_save(imgStackCh1Avg,fullfile(folderProcessed, sprintf('%s_ch1_%d_Frames_AVG%s', fname,frames, fext)),tagstruct);
            imgStackCh2Avg = utils.tiff_projection_avg(imgStackCh2);
            utils.tiff_save(imgStackCh2Avg,fullfile(folderProcessed, sprintf('%s_ch2_%d_Frames_AVG%s', fname,frames, fext)),tagstruct);

            % 自动调整对比度 EnhanceContrast
            utils.tiff_save(imadjust(imgStackCh1Avg),fullfile(folderProcessed, sprintf('%s_ch1_%d_Frames_AVG_EnhanceContrast%s', fname,frames, fext)),tagstruct);
            utils.tiff_save(imadjust(imgStackCh2Avg),fullfile(folderProcessed, sprintf('%s_ch2_%d_Frames_AVG_EnhanceContrast%s', fname,frames, fext)),tagstruct);

        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)

            app.StartIndexSpinner.Enable = "off";
            app.EndIndexSpinner.Enable = "off";
            app.ProcessButton.Enable = "off";
            app.OpenFolderButton.Enable = "off";
            app.RippleNoiseCheckBox.Enable = "off";
            app.ConsoleTextArea.Value = '';

            today = datetime("now","Format","uuuu-MM-dd");
            app.cellArrayText{1} = sprintf('%s %s\n', 'Date:', today); % 赋初值
            app.ConsoleTextArea.Value=app.cellArrayText{1}; % 文本区域中的初始显示信息

            % 检测是否存在config.json文件，如果没有，则新建
            if isfile('./config_para.json') 
                text = fileread('./config_para.json');
                config = jsondecode(text);
                if isfield(config, 'ripple_noise')
                    app.RippleNoiseSpinner.Value = config.ripple_noise;
                end
                if isfield(config, 'position')
                    app.TiffSplitChannelUIFigure.Position = config.position;
                end

                if isfield(config, 'last_select_path')
                    app.folder = config.last_select_path;
                end
                

            else
                % 创建新的config.json文件
                config.ripple_noise = app.RippleNoiseSpinner.Value;
                config.position = app.TiffSplitChannelUIFigure.Position;
                config.last_select_path = '';
                json_data = jsonencode(config);

                fileID = fopen('./config_para.json', 'w');
                fprintf(fileID, json_data);
                fclose(fileID);

            end

        end

        % Button pushed function: FileSelectButton
        function FileSelectButtonPushed(app, event)
            switch app.FolderDropDown.Value
                case 'Folder'
                    % 选择文件夹
                    path = utils.select_dir(app.folder);
                    if path == 0
                        uialert(app.TiffSplitChannelUIFigure,'未选择文件夹','Warning','Icon','warning');
                        return;
                    end
                    % 保存文件夹信息到变量
                    app.folder = path;
                    app.FolderEditField.Value = app.folder;

                    % 获取文件index范围
                    app.UpdateButton.Enable ='on';
                    app.update_tiff_index()
                case 'File'
                    [filename,selectedDir] = utils.select_file({'.tif'},app.folder);
                    if filename == 0 % 如果不选择文件返回为0
                        uialert(app.TiffSplitChannelUIFigure,'未选择文件夹','Warning','Icon','warning');
                        return;
                    end
                    app.tiffpath = fullfile(selectedDir,filename);
                    app.FolderEditField.Value = app.tiffpath;
                    app.ProcessButton.Enable = "on";
                    app.OpenFolderButton.Enable = "on";
                    app.RippleNoiseCheckBox.Enable = "on";
                    app.index_updated = false;
            end
            

        end

        % Button pushed function: ProcessButton
        function ProcessButtonPushed(app, event)
            switch app.FolderDropDown.Value
                case 'Folder'
                    process_folder(app);
                case 'File'
                    process_single_file(app);
            end
            

        end

        % Value changed function: StartIndexSpinner
        function StartIndexSpinnerValueChanged(app, event)
            value = app.StartIndexSpinner.Value;
            if app.onlyOne
                app.StartIndexSpinner.Value =app.fileStartIndex;
                app.EndIndexSpinner.Value = app.fileEndIndex;
            else
                if value < app.fileEndIndex
                    app.EndIndexSpinner.Limits = [value,app.fileEndIndex];
                end
            end

        end

        % Value changed function: EndIndexSpinner
        function EndIndexSpinnerValueChanged(app, event)
            value = app.EndIndexSpinner.Value;
            if app.onlyOne
                app.EndIndexSpinner.Value =app.fileEndIndex;
            else
                if value > 1
                    app.StartIndexSpinner.Limits = [1,value];
                end
            end
        end

        % Button pushed function: UpdateButton
        function UpdateButtonPushed(app, event)
            app.update_tiff_index()
        end

        % Button pushed function: OpenFolderButton
        function OpenFolderButtonPushed(app, event)

            winopen(app.folder);
        end

        % Value changed function: RippleNoiseCheckBox
        function RippleNoiseCheckBoxValueChanged(app, event)
            value = app.RippleNoiseCheckBox.Value;
            if value
                app.RippleNoiseSpinner.Enable = 'on';
            else
                app.RippleNoiseSpinner.Enable = 'off';
            end
        end

        % Close request function: TiffSplitChannelUIFigure
        function TiffSplitChannelUIFigureCloseRequest(app, event)
            % 软件关闭前，保存ripple设置到文件
            config.ripple_noise = app.RippleNoiseSpinner.Value;
            config.position = app.TiffSplitChannelUIFigure.Position;

            config.last_select_path = strrep(app.folder, '\', '\\');
            json_data = jsonencode(config);

            fileID = fopen('./config_para.json ', 'w');
            fprintf(fileID, json_data);
            fclose(fileID);
            
            
            delete(app)
            
        end

        % Value changed function: ScanphaseCorrectDropDown
        function ScanphaseCorrectDropDownValueChanged(app, event)
            value = app.ScanphaseCorrectDropDown.Value;
            switch value
                case 'Fixed'
                    app.ScanphaseSpinner.Visible = 'on';
                case {'Off','Auto'}
                    app.ScanphaseSpinner.Visible = 'off';
            end
        end

        % Value changed function: FolderDropDown
        function FolderDropDownValueChanged(app, event)
            app.FolderEditField.Value = '';
            app.StartIndexSpinner.Enable = 'off';
            app.EndIndexSpinner.Enable = 'off';
            app.UpdateButton.Enable = 'off';
            app.ProcessButton.Enable = 'off';
            app.TiffRangeLabel.Text = 'file_0000a ~ file_0000b';
            app.OpenFolderButton.Enable="off";
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create TiffSplitChannelUIFigure and hide until all components are created
            app.TiffSplitChannelUIFigure = uifigure('Visible', 'off');
            app.TiffSplitChannelUIFigure.Position = [100 100 684 388];
            app.TiffSplitChannelUIFigure.Name = 'Tiff Split Channel';
            app.TiffSplitChannelUIFigure.Icon = fullfile(pathToMLAPP, 'split.png');
            app.TiffSplitChannelUIFigure.CloseRequestFcn = createCallbackFcn(app, @TiffSplitChannelUIFigureCloseRequest, true);

            % Create FileSelectButton
            app.FileSelectButton = uibutton(app.TiffSplitChannelUIFigure, 'push');
            app.FileSelectButton.ButtonPushedFcn = createCallbackFcn(app, @FileSelectButtonPushed, true);
            app.FileSelectButton.Position = [590 338 25 23];
            app.FileSelectButton.Text = '...';

            % Create ProcessButton
            app.ProcessButton = uibutton(app.TiffSplitChannelUIFigure, 'push');
            app.ProcessButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessButtonPushed, true);
            app.ProcessButton.FontWeight = 'bold';
            app.ProcessButton.Position = [29 56 100 23];
            app.ProcessButton.Text = 'Process';

            % Create TiffRangeLabel
            app.TiffRangeLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.TiffRangeLabel.Position = [91 299 150 22];
            app.TiffRangeLabel.Text = 'file_0000a ~ file_0000b';

            % Create TiffLabel
            app.TiffLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.TiffLabel.FontWeight = 'bold';
            app.TiffLabel.Position = [37 299 25 22];
            app.TiffLabel.Text = 'Tiff';

            % Create UpdateButton
            app.UpdateButton = uibutton(app.TiffSplitChannelUIFigure, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Enable = 'off';
            app.UpdateButton.Position = [250 299 51 23];
            app.UpdateButton.Text = 'Update';

            % Create OpenFolderButton
            app.OpenFolderButton = uibutton(app.TiffSplitChannelUIFigure, 'push');
            app.OpenFolderButton.ButtonPushedFcn = createCallbackFcn(app, @OpenFolderButtonPushed, true);
            app.OpenFolderButton.FontWeight = 'bold';
            app.OpenFolderButton.Position = [171 56 100 23];
            app.OpenFolderButton.Text = 'Open Folder';

            % Create RippleNoiseCheckBox
            app.RippleNoiseCheckBox = uicheckbox(app.TiffSplitChannelUIFigure);
            app.RippleNoiseCheckBox.ValueChangedFcn = createCallbackFcn(app, @RippleNoiseCheckBoxValueChanged, true);
            app.RippleNoiseCheckBox.Text = '';
            app.RippleNoiseCheckBox.Position = [289 180 26 22];

            % Create FolderEditField
            app.FolderEditField = uieditfield(app.TiffSplitChannelUIFigure, 'text');
            app.FolderEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.FolderEditField.Position = [115 338 464 22];

            % Create StartIndexSpinnerLabel
            app.StartIndexSpinnerLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.StartIndexSpinnerLabel.FontWeight = 'bold';
            app.StartIndexSpinnerLabel.Position = [39 261 71 22];
            app.StartIndexSpinnerLabel.Text = 'Start Index ';

            % Create StartIndexSpinner
            app.StartIndexSpinner = uispinner(app.TiffSplitChannelUIFigure);
            app.StartIndexSpinner.Limits = [1 Inf];
            app.StartIndexSpinner.ValueDisplayFormat = '%.0f';
            app.StartIndexSpinner.ValueChangedFcn = createCallbackFcn(app, @StartIndexSpinnerValueChanged, true);
            app.StartIndexSpinner.Position = [171 261 100 22];
            app.StartIndexSpinner.Value = 1;

            % Create EndIndexSpinnerLabel
            app.EndIndexSpinnerLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.EndIndexSpinnerLabel.FontWeight = 'bold';
            app.EndIndexSpinnerLabel.Position = [38 219 66 22];
            app.EndIndexSpinnerLabel.Text = 'End Index ';

            % Create EndIndexSpinner
            app.EndIndexSpinner = uispinner(app.TiffSplitChannelUIFigure);
            app.EndIndexSpinner.Limits = [1 Inf];
            app.EndIndexSpinner.ValueDisplayFormat = '%.0f';
            app.EndIndexSpinner.ValueChangedFcn = createCallbackFcn(app, @EndIndexSpinnerValueChanged, true);
            app.EndIndexSpinner.Position = [170 220 100 22];
            app.EndIndexSpinner.Value = 1;

            % Create OutputFolderEditFieldLabel
            app.OutputFolderEditFieldLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.OutputFolderEditFieldLabel.FontWeight = 'bold';
            app.OutputFolderEditFieldLabel.Position = [39 96 85 22];
            app.OutputFolderEditFieldLabel.Text = 'Output Folder';

            % Create OutputFolderEditField
            app.OutputFolderEditField = uieditfield(app.TiffSplitChannelUIFigure, 'text');
            app.OutputFolderEditField.HorizontalAlignment = 'right';
            app.OutputFolderEditField.Position = [170 96 100 22];
            app.OutputFolderEditField.Value = 'Processed';

            % Create ConsoleTextAreaLabel
            app.ConsoleTextAreaLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.ConsoleTextAreaLabel.FontWeight = 'bold';
            app.ConsoleTextAreaLabel.Position = [353 300 53 22];
            app.ConsoleTextAreaLabel.Text = 'Console';

            % Create ConsoleTextArea
            app.ConsoleTextArea = uitextarea(app.TiffSplitChannelUIFigure);
            app.ConsoleTextArea.Position = [353 46 270 251];

            % Create RippleNoiseSpinnerLabel
            app.RippleNoiseSpinnerLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.RippleNoiseSpinnerLabel.FontWeight = 'bold';
            app.RippleNoiseSpinnerLabel.Position = [37 178 78 22];
            app.RippleNoiseSpinnerLabel.Text = 'Ripple Noise';

            % Create RippleNoiseSpinner
            app.RippleNoiseSpinner = uispinner(app.TiffSplitChannelUIFigure);
            app.RippleNoiseSpinner.Limits = [0 Inf];
            app.RippleNoiseSpinner.Enable = 'off';
            app.RippleNoiseSpinner.Position = [169 178 100 22];
            app.RippleNoiseSpinner.Value = 700;

            % Create ScanphaseCorrectDropDownLabel
            app.ScanphaseCorrectDropDownLabel = uilabel(app.TiffSplitChannelUIFigure);
            app.ScanphaseCorrectDropDownLabel.FontWeight = 'bold';
            app.ScanphaseCorrectDropDownLabel.Position = [38 137 114 22];
            app.ScanphaseCorrectDropDownLabel.Text = 'Scanphase Correct';

            % Create ScanphaseCorrectDropDown
            app.ScanphaseCorrectDropDown = uidropdown(app.TiffSplitChannelUIFigure);
            app.ScanphaseCorrectDropDown.Items = {'Off', 'Auto', 'Fixed'};
            app.ScanphaseCorrectDropDown.ValueChangedFcn = createCallbackFcn(app, @ScanphaseCorrectDropDownValueChanged, true);
            app.ScanphaseCorrectDropDown.Position = [169 137 100 22];
            app.ScanphaseCorrectDropDown.Value = 'Off';

            % Create ScanphaseSpinner
            app.ScanphaseSpinner = uispinner(app.TiffSplitChannelUIFigure);
            app.ScanphaseSpinner.Visible = 'off';
            app.ScanphaseSpinner.Position = [289 137 49 22];

            % Create FolderDropDown
            app.FolderDropDown = uidropdown(app.TiffSplitChannelUIFigure);
            app.FolderDropDown.Items = {'Folder', 'File'};
            app.FolderDropDown.ValueChangedFcn = createCallbackFcn(app, @FolderDropDownValueChanged, true);
            app.FolderDropDown.Position = [34 338 69 22];
            app.FolderDropDown.Value = 'Folder';

            % Show the figure after all components are created
            app.TiffSplitChannelUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TiffSplitChannel_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TiffSplitChannelUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TiffSplitChannelUIFigure)
        end
    end
end