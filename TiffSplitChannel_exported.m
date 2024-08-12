classdef TiffSplitChannel_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TiffSplitChannelUIFigure       matlab.ui.Figure
        HelpMenu                       matlab.ui.container.Menu
        TabGroup                       matlab.ui.container.TabGroup
        TiffSplitTab                   matlab.ui.container.Tab
        RegisterCheckBox               matlab.ui.control.CheckBox
        OutputFolderEditFieldLabel_2   matlab.ui.control.Label
        nChannelSpinner                matlab.ui.control.Spinner
        nChannelSpinnerLabel           matlab.ui.control.Label
        ScanphaseCorrectDropDown       matlab.ui.control.DropDown
        ScanphaseCorrectDropDownLabel  matlab.ui.control.Label
        ConsoleTextArea                matlab.ui.control.TextArea
        ConsoleTextAreaLabel           matlab.ui.control.Label
        RippleNoiseSpinner             matlab.ui.control.Spinner
        RippleNoiseSpinnerLabel        matlab.ui.control.Label
        OutputFolderEditField          matlab.ui.control.EditField
        OutputFolderEditFieldLabel     matlab.ui.control.Label
        EndSpinner                     matlab.ui.control.Spinner
        EndSpinnerLabel                matlab.ui.control.Label
        StartSpinner                   matlab.ui.control.Spinner
        StartSpinnerLabel              matlab.ui.control.Label
        FolderDropDown                 matlab.ui.control.DropDown
        ScanphaseSpinner               matlab.ui.control.Spinner
        FolderEditField                matlab.ui.control.EditField
        RippleNoiseCheckBox            matlab.ui.control.CheckBox
        OpenFolderButton               matlab.ui.control.Button
        UpdateButton                   matlab.ui.control.Button
        TiffLabel                      matlab.ui.control.Label
        TiffRangeLabel                 matlab.ui.control.Label
        ProcessButton                  matlab.ui.control.Button
        FileSelectButton               matlab.ui.control.Button
        TiffRegTab                     matlab.ui.container.Tab
        ConsoleTextArea_2              matlab.ui.control.TextArea
        ConsoleTextArea_2Label         matlab.ui.control.Label
        MaxregshiftEditField           matlab.ui.control.NumericEditField
        MaxregshiftEditFieldLabel      matlab.ui.control.Label
        Smooth_sigmaEditField          matlab.ui.control.NumericEditField
        Smooth_sigmaEditFieldLabel     matlab.ui.control.Label
        ScanphaseCorrectDropDown_2     matlab.ui.control.DropDown
        ScanphaseCorrectDropDown_2Label  matlab.ui.control.Label
        OutputFolderEditField_2        matlab.ui.control.EditField
        OutputFolderEditField_2Label   matlab.ui.control.Label
        FolderDropDown_2               matlab.ui.control.DropDown
        ScanphaseSpinner_2             matlab.ui.control.Spinner
        FolderEditField_2              matlab.ui.control.EditField
        OpenFolderButton_2             matlab.ui.control.Button
        ProcessButton_2                matlab.ui.control.Button
        FileSelectButton_2             matlab.ui.control.Button
    end


    properties (Access = private)
        folder; 
        folder2; 
        tiffpath; % 选择单个文件进行处理，保存文件路径
        tiffpath2; % 选择单个文件进行处理，保存文件路径
        index_updated = false; % 是否选择文件夹并且点击update成功update了
        fileStartIndex;
        fileEndIndex;
        lastEndIndex;
        onlyOne = false;
        processed = 0;
        cellArrayText;
        cellArrayText2;
        exePath;% app 或者exe地址
        reg_tifFiles;
    end

    methods (Access = private)


        function update_tiff_index(app)
            % 获取指定文件的编号范围
            [app.fileStartIndex,app.fileEndIndex] = utils.get_tiff_num_range(app.folder);

            if isempty(app.fileEndIndex)
                errordlg('该文件夹不存在待分割的tif图片！');
                app.StartSpinner.Enable = "off";
                app.EndSpinner.Enable = "off";
                app.ProcessButton.Enable = "off";
                app.OpenFolderButton.Enable = "off";
                return;
            end

            fileNum = app.fileEndIndex- app.fileStartIndex+1;

            if fileNum > 1
                app.EndSpinner.Limits = [app.fileStartIndex,app.fileEndIndex];
                app.StartSpinner.Limits = [app.fileStartIndex,app.fileEndIndex];
                app.onlyOne = false;
            else
                app.onlyOne = true;
            end
            % 更新文件编号范围
            app.TiffRangeLabel.Text = sprintf('file_%05d ~ file_%05d', app.fileStartIndex,app.fileEndIndex);

            % 点击Update，更新start index 和 end index
            app.StartSpinner.Value = app.fileStartIndex;
            app.EndSpinner.Value =  app.fileEndIndex;

            if  ~isempty(app.lastEndIndex)
                if app.lastEndIndex == app.fileEndIndex
                    % 反复点击update，而文件没有新增，strat index依然为上次处理的文件编号
                    app.StartSpinner.Value = app.lastEndIndex;
                elseif app.lastEndIndex < app.fileEndIndex
                    % 如果文件新增，strat index为上次处理的文件编号+1
                    app.StartSpinner.Value = app.lastEndIndex+1;
                end
            end

            % update ui
            app.StartSpinner.Enable = "on";
            app.EndSpinner.Enable = "on";
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

        function print_console2(app,str)
            time = datetime("now","Format","HH:mm:ss");
            string = sprintf('%s\n%s\n', time,str); % 将数据格式化为字符串或字符向量
            app.cellArrayText2=horzcat(app.cellArrayText2,string); % 水平串联数组
            app.ConsoleTextArea_2.Value = app.cellArrayText2; % 给TextArea赋值
        end
        function process_folder(app)
            % 定义放置处理图像的文件夹
            folderProcessed = fullfile(app.folder, app.OutputFolderEditField.Value);

            % 如果文件夹不存在，创建新的文件夹
            if ~exist(folderProcessed, 'dir')
                mkdir(folderProcessed);
            end


            % 指定的起始和结束编号
            startIdx = app.StartSpinner.Value;
            endIdx = app.EndSpinner.Value;

            % 调用进度条
            progressDlg = uiprogressdlg(app.TiffSplitChannelUIFigure,'Title','Processing',...
                'Cancelable','on','Interpreter','html');
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
                    progressDlg.Message = sprintf('Processing <b>%d/%d</b> files: <b>%s</b>', count, numFiles, filename);

                    % 分割通道
                    split_channel(app,filepath,folderProcessed,app.nChannelSpinner.Value,progressDlg);

                    % 处理完成
                    app.print_console(sprintf('Processed: file_%05d.tif', idx));
                catch ME
                    if ME.identifier == "MATLAB:imagesci:imfinfo:fileOpen"
                        app.print_console('文件不存在或者正在生成！');
                    else
                        app.print_console(ME.message);
                        utils.report_error(ME);
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


        function process_file(app)
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
                'Cancelable','on','Interpreter','html');


            % 构建文件名
            try
                progressDlg.Message = sprintf('Processing files: <b>%s</b>', filename);

                % 分割通道
                split_channel(app,app.tiffpath,folderProcessed,app.nChannelSpinner.Value,progressDlg);

                % 处理完成
                app.print_console(sprintf('Processed: %s', app.tiffpath));
            catch ME
                if ME.identifier == "MATLAB:imagesci:Tiff:unableToOpenFile"
                    app.print_console('文件不存在或者正在生成！');
                else
                    app.print_console(ME.message);
                    utils.report_error(ME);
                end

            end


            % Close the dialog box
            close(progressDlg)
        end

        function split_channel(app,filepath,folderProcessed,nChannels,progressDlg)
            progressDlg_messages = progressDlg.Message;
            [~, fname, ~] = fileparts(filepath);
            % 分割通道
            utils.tiff_split(filepath, nChannels, 'FolderProcessed',folderProcessed, 'AvgOutput', true, 'rippleNoise', app.RippleNoiseSpinner.Value,'progressDlg',progressDlg);

            % scanphase correct
            if app.ScanphaseCorrectDropDown.Value == "Fixed" || app.ScanphaseCorrectDropDown.Value == "Auto"

                scanphase_offset = 0;
                tagstruct = struct();

                for i = 1:nChannels
                    baseFilename = sprintf('%s_ch%d.tif', fname, i); 

                    imgStack = utils.tiff_read(fullfile(folderProcessed, baseFilename));
                    nframes = size(imgStack,3);
                    avgFilename = sprintf('%s_ch%d_%d_Frames_AVG.tif', fname, i, nframes);
                    enhanceFilename = sprintf('%s_ch%d_%d_Frames_AVG_EnhanceContrast.tif', fname, i, nframes);
                    if i == 1
                        if app.ScanphaseCorrectDropDown.Value == "Fixed"
                            scanphase_offset  = app.ScanphaseSpinner.Value;
                        else
                            progressDlg.Message = sprintf('%s丨Predicting Scanphase',progressDlg_messages);
                            progressDlg.Indeterminate = 'on';
                            scanphase_offset = register.scanphase_predict(imgStack);
                            app.print_console(sprintf("Scanphase predicted: %d", scanphase_offset));
                        end
                        if scanphase_offset == 0
                            break;
                        end


                        t = Tiff(fullfile(folderProcessed, baseFilename), 'r');
                        try
                            tagstruct.XResolution = t.getTag('XResolution');
                            tagstruct.YResolution = tagstruct.XResolution;
                        catch
                            
                        end
                        t.close();
                    end
                    progressDlg.Message = sprintf('%s丨Correcting Scanphase',progressDlg_messages);
                    progressDlg.Indeterminate = 'on';
                    imgStack = register.scanphase_correct(imgStack, scanphase_offset);

                    % 保存
                    utils.tiff_save(imgStack,fullfile(folderProcessed, baseFilename),tagstruct);

                    % 计算并保存平均投影
                    imgStackAvg = utils.tiff_projection_avg(imgStack);
                    utils.tiff_save(imgStackAvg, fullfile(folderProcessed, avgFilename), tagstruct);

                    % 自动调整对比度并保存
                    utils.tiff_save(imadjust(imgStackAvg), fullfile(folderProcessed, enhanceFilename), tagstruct);
                    clear imgStack;
                end
                    
            end

            if app.RegisterCheckBox.Value
                progressDlg.Message = sprintf('%s丨Registering',progressDlg_messages);
                progressDlg.Indeterminate = 'on';
                for i = 1:nChannels
                    baseFilename = sprintf('%s_ch%d.tif', fname, i);
                    reg_filepath = fullfile(folderProcessed, baseFilename);
                    registration(app, reg_filepath, folderProcessed);
                end
            end
        end

        function reg_folder(app)
            % 定义放置处理图像的文件夹
            folderProcessed = fullfile(app.folder2, app.OutputFolderEditField_2.Value);

            % 如果文件夹不存在，创建新的文件夹
            if ~exist(folderProcessed, 'dir')
                mkdir(folderProcessed);
            end



            % 调用进度条
            progressDlg = uiprogressdlg(app.TiffSplitChannelUIFigure,'Title','Processing',...
                'Cancelable','on','Indeterminate','on');
            numFiles = length(app.reg_tifFiles); % 要处理的文件数
            count = 1; % 开始计数
            isRight = true;
            for k = 1:numFiles
                % 为了进度条的取消可以中断处理
                if progressDlg.CancelRequested
                    break
                end

                % 构建文件名
                filename = app.reg_tifFiles(k).name;
                filepath = fullfile(app.folder2, filename);
                progressDlg.Message = sprintf('Processing %d/%d files: %s', count, numFiles, filename);

            
                try
                    % 获取图像文件的信息
                    info = imfinfo(filepath);
                    % 获取帧数
                    numFrames = numel(info);
                    if numFrames == 1
                        continue
                    else
                        % 进行配准
                        registration(app,filepath,folderProcessed);
    
                        % 处理完成
                        app.print_console2(sprintf('Processed: %s', filepath));
                    end
                catch ME
                    app.print_console2(ME.message);
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


        function reg_file(app)
            % 定义放置处理图像的文件夹
            [directory, fname, fext] = fileparts(app.tiffpath2);
            filename = strcat(fname, fext);
            folderProcessed = fullfile(directory, app.OutputFolderEditField_2.Value);

            % 如果文件夹不存在，创建新的文件夹
            if ~exist(folderProcessed, 'dir')
                mkdir(folderProcessed);
            end
            


            % 调用进度条
            progressDlg = uiprogressdlg(app.TiffSplitChannelUIFigure,'Title','Processing',...
                'Indeterminate','on');



            try
                progressDlg.Message = sprintf('Processing files: %s', filename);

                % 获取图像文件的信息
                info = imfinfo(app.tiffpath2);
                % 获取帧数
                numFrames = numel(info);
                if numFrames == 1
                    app.print_console2(sprintf('%s: 帧数为1，不进行配准', app.tiffpath2));
                else

                    registration(app,app.tiffpath2,folderProcessed);

                    % 处理完成
                    app.print_console2(sprintf('Processed: %s', app.tiffpath2));
                end

            catch ME

                app.print_console2(ME.message);
            end


            % Close the dialog box
            close(progressDlg)
        end

        function registration(app,filepath,folderProcessed)
            %% 配准
            imgStack = utils.tiff_read(filepath);
            nframes = size(imgStack,3);
            ops = register.suite2p.default_ops();
            ops.smooth_sigma = app.Smooth_sigmaEditField.Value;
            ops.maxregshift = app.MaxregshiftEditField.Value;
            % 获取refimg
            refImg = register.suite2p.compute_reference(imgStack,ops);

            % scanphase correct
            switch app.ScanphaseCorrectDropDown_2.Value
                case 'Fixed'
                    scanphase_offset = app.ScanphaseSpinner_2.Value;
                case 'Off'
                    scanphase_offset = 0;
                case 'Auto'
                    scanphase_offset = register.scanphase_predict(imgStack);
                    app.print_console2(sprintf("Scanphase predicted: %d", scanphase_offset));
            end
            if scanphase_offset
                imgStack = register.scanphase_correct(imgStack, scanphase_offset);
            end


            % 进行配准
            refAndMasks = register.suite2p.compute_reference_masks(refImg, ops);
            [imgStack, ymax, xmax, cmax] = register.suite2p.register_frames(refAndMasks, imgStack,  ops);

            %% save
            % 获取分辨率信息
            t = Tiff(filepath, 'r');
            try
                tagstruct.XResolution = t.getTag('XResolution');
                tagstruct.YResolution = tagstruct.XResolution;
            catch
                tagstruct = struct();
            end
            t.close();
            
            [~, fname, fext] = fileparts(filepath);
            filename = strcat(fname, '_reg',fext);

            avgFilename = sprintf('%s_%d_Frames_AVG.tif', fname, nframes);
            enhanceFilename = sprintf('%s_%d_Frames_AVG_EnhanceContrast.tif', fname, nframes);
            % 保存配准后的图片
            utils.tiff_save(imgStack,fullfile(folderProcessed,filename),tagstruct);


            % 计算并保存平均投影

            imgStackAvg = utils.tiff_projection_avg(imgStack);
            utils.tiff_save(imgStackAvg, fullfile(folderProcessed, avgFilename), tagstruct);

            % 自动调整对比度并保存
            utils.tiff_save(imadjust(imgStackAvg), fullfile(folderProcessed, enhanceFilename), tagstruct);
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)

            app.StartSpinner.Enable = "off";
            app.EndSpinner.Enable = "off";
            app.ProcessButton.Enable = "off";
            app.OpenFolderButton.Enable = "off";
            app.RippleNoiseCheckBox.Enable = "off";
            app.ConsoleTextArea.Value = '';

            app.ProcessButton_2.Enable = "off";
            app.OpenFolderButton_2.Enable = "off";
            app.ConsoleTextArea_2.Value = '';


            today = datetime("now","Format","uuuu-MM-dd");
            app.cellArrayText{1} = sprintf('%s %s\n', 'Date:', today); % 赋初值
            app.cellArrayText2{1} = sprintf('%s %s\n', 'Date:', today); % 赋初值
            app.ConsoleTextArea.Value=app.cellArrayText{1}; % 文本区域中的初始显示信息
            app.ConsoleTextArea_2.Value=app.cellArrayText2{1}; % 文本区域中的初始显示信息
            % 检测是否存在config.json文件，如果没有，则新建

            app.exePath = utils.GetExecutableFolder();

            if isfile(fullfile(app.exePath, 'config.json'))
                text = fileread(fullfile(app.exePath, 'config.json'));
                config = jsondecode(text);
                if isfield(config, 'ripple_noise')
                    app.RippleNoiseSpinner.Value = config.ripple_noise;
                end
                if isfield(config, 'position')
                    app.TiffSplitChannelUIFigure.Position(1) = config.position(1);
                    app.TiffSplitChannelUIFigure.Position(2) = config.position(2);
                end

                if isfield(config, 'last_select_path')
                    app.folder = config.last_select_path;
                    app.folder2 = config.last_select_path;
                end

                if isfield(config, 'nChannel')
                    app.nChannelSpinner.Value = config.nChannel;
                end

            else
                % 创建新的config.json文件
                config.ripple_noise = app.RippleNoiseSpinner.Value;
                config.position = app.TiffSplitChannelUIFigure.Position;
                config.last_select_path = '';
                config.nChannel = app.nChannelSpinner.Value;
                json_data = jsonencode(config);

                fileID = fopen(fullfile(app.exePath, 'config.json'), 'w');
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
                        uialert(app.TiffSplitChannelUIFigure,'未选择文件','Warning','Icon','warning');
                        return;
                    end
                    app.folder = selectedDir;
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
                    process_file(app);
            end


        end

        % Value changed function: StartSpinner
        function StartSpinnerValueChanged(app, event)
            value = app.StartSpinner.Value;
            if app.onlyOne
                app.StartSpinner.Value =app.fileStartIndex;
                app.EndSpinner.Value = app.fileEndIndex;
            else
                if value < app.fileEndIndex
                    app.EndSpinner.Limits = [value,app.fileEndIndex];
                end
            end

        end

        % Value changed function: EndSpinner
        function EndSpinnerValueChanged(app, event)
            value = app.EndSpinner.Value;
            if app.onlyOne
                app.EndSpinner.Value =app.fileEndIndex;
            else
                if value > 1
                    app.StartSpinner.Limits = [1,value];
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
            config.nChannel = app.nChannelSpinner.Value;
            json_data = jsonencode(config);


            fileID = fopen( fullfile(app.exePath, 'config.json'), 'w');
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
            app.StartSpinner.Enable = 'off';
            app.EndSpinner.Enable = 'off';
            app.UpdateButton.Enable = 'off';
            app.ProcessButton.Enable = 'off';
            app.TiffRangeLabel.Text = 'file_0000a ~ file_0000b';
            app.OpenFolderButton.Enable="off";
        end

        % Button pushed function: FileSelectButton_2
        function FileSelectButton_2Pushed(app, event)
            switch app.FolderDropDown_2.Value
                case 'Folder'
                    % 选择文件夹
                    path = utils.select_dir(app.folder2);
                    if path == 0
                        uialert(app.TiffSplitChannelUIFigure,'未选择文件夹','Warning','Icon','warning');
                        return;
                    end
                    % 保存文件夹信息到变量
                    app.folder2 = path;
                    app.FolderEditField_2.Value = app.folder2;
                    filePattern = fullfile(app.folder2, '*.tif');
                    app.reg_tifFiles = dir(filePattern);
                    app.ProcessButton_2.Enable = 'on';
                    app.OpenFolderButton_2.Enable = "on";
                case 'File'
                    [filename,selectedDir] = utils.select_file({'.tif'},app.folder2);
                    if filename == 0 % 如果不选择文件返回为0
                        uialert(app.TiffSplitChannelUIFigure,'未选择文件夹','Warning','Icon','warning');
                        return;
                    end
                    app.folder2 = selectedDir;
                    app.tiffpath2 = fullfile(selectedDir,filename);
                    app.FolderEditField_2.Value = app.tiffpath2;
                    app.ProcessButton_2.Enable = "on";
                    app.OpenFolderButton_2.Enable = "on";
            end

        end

        % Button pushed function: ProcessButton_2
        function ProcessButton_2Pushed(app, event)
            switch app.FolderDropDown_2.Value
                case 'Folder'
                    reg_folder(app);
                case 'File'
                    reg_file(app);
            end
        end

        % Button pushed function: OpenFolderButton_2
        function OpenFolderButton_2Pushed(app, event)
            winopen(app.folder2);
        end

        % Value changed function: FolderDropDown_2
        function FolderDropDown_2ValueChanged(app, event)
            app.FolderEditField_2.Value = '';
            app.ProcessButton_2.Enable = 'off';
            app.OpenFolderButton_2.Enable="off";
        end

        % Value changed function: ScanphaseCorrectDropDown_2
        function ScanphaseCorrectDropDown_2ValueChanged(app, event)
            value = app.ScanphaseCorrectDropDown_2.Value;
            switch value
                case 'Fixed'
                    app.ScanphaseSpinner_2.Visible = 'on';
                case {'Off','Auto'}
                    app.ScanphaseSpinner_2.Visible = 'off';
            end
        end

        % Menu selected function: HelpMenu
        function HelpMenuSelected(app, event)
            message = fileread('README.md');
            uialert(app.TiffSplitChannelUIFigure,message,'Help','Icon','info',"Interpreter","html");
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
            app.TiffSplitChannelUIFigure.Position = [100 100 657 425];
            app.TiffSplitChannelUIFigure.Name = 'Tiff Split Channel';
            app.TiffSplitChannelUIFigure.Icon = fullfile(pathToMLAPP, '+assets', 'split.png');
            app.TiffSplitChannelUIFigure.CloseRequestFcn = createCallbackFcn(app, @TiffSplitChannelUIFigureCloseRequest, true);

            % Create HelpMenu
            app.HelpMenu = uimenu(app.TiffSplitChannelUIFigure);
            app.HelpMenu.MenuSelectedFcn = createCallbackFcn(app, @HelpMenuSelected, true);
            app.HelpMenu.Text = 'Help';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.TiffSplitChannelUIFigure);
            app.TabGroup.Position = [-1 1 659 428];

            % Create TiffSplitTab
            app.TiffSplitTab = uitab(app.TabGroup);
            app.TiffSplitTab.Title = 'Tiff Split';

            % Create FileSelectButton
            app.FileSelectButton = uibutton(app.TiffSplitTab, 'push');
            app.FileSelectButton.ButtonPushedFcn = createCallbackFcn(app, @FileSelectButtonPushed, true);
            app.FileSelectButton.Position = [580 371 25 23];
            app.FileSelectButton.Text = '...';

            % Create ProcessButton
            app.ProcessButton = uibutton(app.TiffSplitTab, 'push');
            app.ProcessButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessButtonPushed, true);
            app.ProcessButton.FontWeight = 'bold';
            app.ProcessButton.Position = [28 47 100 23];
            app.ProcessButton.Text = 'Process';

            % Create TiffRangeLabel
            app.TiffRangeLabel = uilabel(app.TiffSplitTab);
            app.TiffRangeLabel.Position = [81 332 150 22];
            app.TiffRangeLabel.Text = 'file_0000a ~ file_0000b';

            % Create TiffLabel
            app.TiffLabel = uilabel(app.TiffSplitTab);
            app.TiffLabel.FontWeight = 'bold';
            app.TiffLabel.Position = [27 332 25 22];
            app.TiffLabel.Text = 'Tiff';

            % Create UpdateButton
            app.UpdateButton = uibutton(app.TiffSplitTab, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Enable = 'off';
            app.UpdateButton.Position = [240 332 51 23];
            app.UpdateButton.Text = 'Update';

            % Create OpenFolderButton
            app.OpenFolderButton = uibutton(app.TiffSplitTab, 'push');
            app.OpenFolderButton.ButtonPushedFcn = createCallbackFcn(app, @OpenFolderButtonPushed, true);
            app.OpenFolderButton.FontWeight = 'bold';
            app.OpenFolderButton.Position = [170 47 100 23];
            app.OpenFolderButton.Text = 'Open Folder';

            % Create RippleNoiseCheckBox
            app.RippleNoiseCheckBox = uicheckbox(app.TiffSplitTab);
            app.RippleNoiseCheckBox.ValueChangedFcn = createCallbackFcn(app, @RippleNoiseCheckBoxValueChanged, true);
            app.RippleNoiseCheckBox.Text = '';
            app.RippleNoiseCheckBox.Position = [267 215 26 22];

            % Create FolderEditField
            app.FolderEditField = uieditfield(app.TiffSplitTab, 'text');
            app.FolderEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.FolderEditField.Position = [105 371 464 22];

            % Create ScanphaseSpinner
            app.ScanphaseSpinner = uispinner(app.TiffSplitTab);
            app.ScanphaseSpinner.Visible = 'off';
            app.ScanphaseSpinner.Position = [268 175 49 22];

            % Create FolderDropDown
            app.FolderDropDown = uidropdown(app.TiffSplitTab);
            app.FolderDropDown.Items = {'Folder', 'File'};
            app.FolderDropDown.ValueChangedFcn = createCallbackFcn(app, @FolderDropDownValueChanged, true);
            app.FolderDropDown.Position = [24 371 69 22];
            app.FolderDropDown.Value = 'Folder';

            % Create StartSpinnerLabel
            app.StartSpinnerLabel = uilabel(app.TiffSplitTab);
            app.StartSpinnerLabel.FontWeight = 'bold';
            app.StartSpinnerLabel.Position = [27 258 71 22];
            app.StartSpinnerLabel.Text = 'Start :';

            % Create StartSpinner
            app.StartSpinner = uispinner(app.TiffSplitTab);
            app.StartSpinner.Limits = [1 Inf];
            app.StartSpinner.ValueDisplayFormat = '%.0f';
            app.StartSpinner.ValueChangedFcn = createCallbackFcn(app, @StartSpinnerValueChanged, true);
            app.StartSpinner.Position = [69 259 55 22];
            app.StartSpinner.Value = 1;

            % Create EndSpinnerLabel
            app.EndSpinnerLabel = uilabel(app.TiffSplitTab);
            app.EndSpinnerLabel.FontWeight = 'bold';
            app.EndSpinnerLabel.Position = [159 259 32 22];
            app.EndSpinnerLabel.Text = 'End:';

            % Create EndSpinner
            app.EndSpinner = uispinner(app.TiffSplitTab);
            app.EndSpinner.Limits = [1 Inf];
            app.EndSpinner.ValueDisplayFormat = '%.0f';
            app.EndSpinner.ValueChangedFcn = createCallbackFcn(app, @EndSpinnerValueChanged, true);
            app.EndSpinner.Position = [198 258 51 22];
            app.EndSpinner.Value = 1;

            % Create OutputFolderEditFieldLabel
            app.OutputFolderEditFieldLabel = uilabel(app.TiffSplitTab);
            app.OutputFolderEditFieldLabel.FontWeight = 'bold';
            app.OutputFolderEditFieldLabel.Position = [31 94 85 22];
            app.OutputFolderEditFieldLabel.Text = 'Output Folder';

            % Create OutputFolderEditField
            app.OutputFolderEditField = uieditfield(app.TiffSplitTab, 'text');
            app.OutputFolderEditField.HorizontalAlignment = 'right';
            app.OutputFolderEditField.Position = [162 94 100 22];
            app.OutputFolderEditField.Value = 'Processed';

            % Create RippleNoiseSpinnerLabel
            app.RippleNoiseSpinnerLabel = uilabel(app.TiffSplitTab);
            app.RippleNoiseSpinnerLabel.FontWeight = 'bold';
            app.RippleNoiseSpinnerLabel.Position = [28 215 78 22];
            app.RippleNoiseSpinnerLabel.Text = 'Ripple Noise';

            % Create RippleNoiseSpinner
            app.RippleNoiseSpinner = uispinner(app.TiffSplitTab);
            app.RippleNoiseSpinner.Limits = [0 Inf];
            app.RippleNoiseSpinner.Enable = 'off';
            app.RippleNoiseSpinner.Position = [160 215 100 22];
            app.RippleNoiseSpinner.Value = 700;

            % Create ConsoleTextAreaLabel
            app.ConsoleTextAreaLabel = uilabel(app.TiffSplitTab);
            app.ConsoleTextAreaLabel.FontWeight = 'bold';
            app.ConsoleTextAreaLabel.Position = [343 333 53 22];
            app.ConsoleTextAreaLabel.Text = 'Console';

            % Create ConsoleTextArea
            app.ConsoleTextArea = uitextarea(app.TiffSplitTab);
            app.ConsoleTextArea.Position = [343 35 270 295];

            % Create ScanphaseCorrectDropDownLabel
            app.ScanphaseCorrectDropDownLabel = uilabel(app.TiffSplitTab);
            app.ScanphaseCorrectDropDownLabel.FontWeight = 'bold';
            app.ScanphaseCorrectDropDownLabel.Position = [28 175 114 22];
            app.ScanphaseCorrectDropDownLabel.Text = 'Scanphase Correct';

            % Create ScanphaseCorrectDropDown
            app.ScanphaseCorrectDropDown = uidropdown(app.TiffSplitTab);
            app.ScanphaseCorrectDropDown.Items = {'Off', 'Auto', 'Fixed'};
            app.ScanphaseCorrectDropDown.ValueChangedFcn = createCallbackFcn(app, @ScanphaseCorrectDropDownValueChanged, true);
            app.ScanphaseCorrectDropDown.Position = [160 175 100 22];
            app.ScanphaseCorrectDropDown.Value = 'Off';

            % Create nChannelSpinnerLabel
            app.nChannelSpinnerLabel = uilabel(app.TiffSplitTab);
            app.nChannelSpinnerLabel.FontWeight = 'bold';
            app.nChannelSpinnerLabel.Position = [27 298 60 22];
            app.nChannelSpinnerLabel.Text = 'nChannel';

            % Create nChannelSpinner
            app.nChannelSpinner = uispinner(app.TiffSplitTab);
            app.nChannelSpinner.Limits = [1 Inf];
            app.nChannelSpinner.ValueDisplayFormat = '%.0f';
            app.nChannelSpinner.Position = [110 298 51 22];
            app.nChannelSpinner.Value = 2;

            % Create OutputFolderEditFieldLabel_2
            app.OutputFolderEditFieldLabel_2 = uilabel(app.TiffSplitTab);
            app.OutputFolderEditFieldLabel_2.FontWeight = 'bold';
            app.OutputFolderEditFieldLabel_2.Position = [29 136 85 22];
            app.OutputFolderEditFieldLabel_2.Text = 'Register';

            % Create RegisterCheckBox
            app.RegisterCheckBox = uicheckbox(app.TiffSplitTab);
            app.RegisterCheckBox.Text = '';
            app.RegisterCheckBox.Position = [98 136 26 22];

            % Create TiffRegTab
            app.TiffRegTab = uitab(app.TabGroup);
            app.TiffRegTab.Title = 'Tiff Reg';

            % Create FileSelectButton_2
            app.FileSelectButton_2 = uibutton(app.TiffRegTab, 'push');
            app.FileSelectButton_2.ButtonPushedFcn = createCallbackFcn(app, @FileSelectButton_2Pushed, true);
            app.FileSelectButton_2.Position = [570 372 25 23];
            app.FileSelectButton_2.Text = '...';

            % Create ProcessButton_2
            app.ProcessButton_2 = uibutton(app.TiffRegTab, 'push');
            app.ProcessButton_2.ButtonPushedFcn = createCallbackFcn(app, @ProcessButton_2Pushed, true);
            app.ProcessButton_2.FontWeight = 'bold';
            app.ProcessButton_2.Position = [8 165 100 23];
            app.ProcessButton_2.Text = 'Process';

            % Create OpenFolderButton_2
            app.OpenFolderButton_2 = uibutton(app.TiffRegTab, 'push');
            app.OpenFolderButton_2.ButtonPushedFcn = createCallbackFcn(app, @OpenFolderButton_2Pushed, true);
            app.OpenFolderButton_2.FontWeight = 'bold';
            app.OpenFolderButton_2.Position = [150 165 100 23];
            app.OpenFolderButton_2.Text = 'Open Folder';

            % Create FolderEditField_2
            app.FolderEditField_2 = uieditfield(app.TiffRegTab, 'text');
            app.FolderEditField_2.BackgroundColor = [0.9412 0.9412 0.9412];
            app.FolderEditField_2.Position = [95 372 464 22];

            % Create ScanphaseSpinner_2
            app.ScanphaseSpinner_2 = uispinner(app.TiffRegTab);
            app.ScanphaseSpinner_2.Visible = 'off';
            app.ScanphaseSpinner_2.Position = [268 246 49 22];

            % Create FolderDropDown_2
            app.FolderDropDown_2 = uidropdown(app.TiffRegTab);
            app.FolderDropDown_2.Items = {'Folder', 'File'};
            app.FolderDropDown_2.ValueChangedFcn = createCallbackFcn(app, @FolderDropDown_2ValueChanged, true);
            app.FolderDropDown_2.Position = [14 372 69 22];
            app.FolderDropDown_2.Value = 'File';

            % Create OutputFolderEditField_2Label
            app.OutputFolderEditField_2Label = uilabel(app.TiffRegTab);
            app.OutputFolderEditField_2Label.FontWeight = 'bold';
            app.OutputFolderEditField_2Label.Position = [20 207 85 22];
            app.OutputFolderEditField_2Label.Text = 'Output Folder';

            % Create OutputFolderEditField_2
            app.OutputFolderEditField_2 = uieditfield(app.TiffRegTab, 'text');
            app.OutputFolderEditField_2.HorizontalAlignment = 'right';
            app.OutputFolderEditField_2.Position = [151 207 100 22];
            app.OutputFolderEditField_2.Value = 'Registration';

            % Create ScanphaseCorrectDropDown_2Label
            app.ScanphaseCorrectDropDown_2Label = uilabel(app.TiffRegTab);
            app.ScanphaseCorrectDropDown_2Label.FontWeight = 'bold';
            app.ScanphaseCorrectDropDown_2Label.Position = [20 246 114 22];
            app.ScanphaseCorrectDropDown_2Label.Text = 'Scanphase Correct';

            % Create ScanphaseCorrectDropDown_2
            app.ScanphaseCorrectDropDown_2 = uidropdown(app.TiffRegTab);
            app.ScanphaseCorrectDropDown_2.Items = {'Off', 'Auto', 'Fixed'};
            app.ScanphaseCorrectDropDown_2.ValueChangedFcn = createCallbackFcn(app, @ScanphaseCorrectDropDown_2ValueChanged, true);
            app.ScanphaseCorrectDropDown_2.Position = [151 246 100 22];
            app.ScanphaseCorrectDropDown_2.Value = 'Off';

            % Create Smooth_sigmaEditFieldLabel
            app.Smooth_sigmaEditFieldLabel = uilabel(app.TiffRegTab);
            app.Smooth_sigmaEditFieldLabel.FontWeight = 'bold';
            app.Smooth_sigmaEditFieldLabel.Position = [19 313 91 22];
            app.Smooth_sigmaEditFieldLabel.Text = 'Smooth_sigma';

            % Create Smooth_sigmaEditField
            app.Smooth_sigmaEditField = uieditfield(app.TiffRegTab, 'numeric');
            app.Smooth_sigmaEditField.Limits = [0 Inf];
            app.Smooth_sigmaEditField.Position = [149 313 100 22];
            app.Smooth_sigmaEditField.Value = 1.125;

            % Create MaxregshiftEditFieldLabel
            app.MaxregshiftEditFieldLabel = uilabel(app.TiffRegTab);
            app.MaxregshiftEditFieldLabel.FontWeight = 'bold';
            app.MaxregshiftEditFieldLabel.Position = [19 280 72 22];
            app.MaxregshiftEditFieldLabel.Text = 'Maxregshift';

            % Create MaxregshiftEditField
            app.MaxregshiftEditField = uieditfield(app.TiffRegTab, 'numeric');
            app.MaxregshiftEditField.Limits = [0 1];
            app.MaxregshiftEditField.Position = [149 280 100 22];
            app.MaxregshiftEditField.Value = 0.1;

            % Create ConsoleTextArea_2Label
            app.ConsoleTextArea_2Label = uilabel(app.TiffRegTab);
            app.ConsoleTextArea_2Label.FontWeight = 'bold';
            app.ConsoleTextArea_2Label.Position = [336 326 53 22];
            app.ConsoleTextArea_2Label.Text = 'Console';

            % Create ConsoleTextArea_2
            app.ConsoleTextArea_2 = uitextarea(app.TiffRegTab);
            app.ConsoleTextArea_2.Position = [336 28 270 295];

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