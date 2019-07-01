function tracking_GUI()
% program for tracking particles
% A lot of stuff adapted from bleaching_GUI 

%adjustment for OS
pc = computer;
if strcmp(pc(1:3),'MAC') == 1
    sliderwidth = 0;
else
    sliderwidth = 12;
end

% set predefined values
data.values.noise_slider_min = 1;
data.values.noise_slider_max = 20;
data.values.noisefactor = 1.4;
data.values.noisefactor_max = 10;
data.values.num_images = 100;
data.values.frame = 1;
data.values.tracking_factor = 5;
data.values.dotsize = 5;
data.values.dot = 1;
data.values.run_plot = 1;
data.values.peakvalues = zeros(3,1);
data.values.path_save = pwd;
data.values.path_load = pwd;
data.values.FIONA_mode = 0;
data.values.Diffusion_mode = 0;
data.values.multicolor_mode = 0;
data.values.parallel_computing_mode = 0;

% Load Java for LIF file handling
import java.util.*;

% set values for GUI
background = [1 1 1];
fontsize = 14;


% Create main figure
data.handles.figures.main = figure('Color',background,'Units','normalized','Position',[0.05 0.1 0.9 0.8]);
data.handles.axes.main = axes('Position',[0.15 0.1 0.5 0.85]);
data.handles.tabs.main = uitabgroup('Position',[0.65 0.3 0.35 0.5]);
data.handles.tabs.plots = uitab('Parent',data.handles.tabs.main,'Title','Plot','Background',background);
data.handles.tabs.info = uitab('Parent',data.handles.tabs.main,'Title','Info','Background',background);
data.handles.tabs.histogram = uitab('Parent',data.handles.tabs.main,'Title','Speed','Background',background);
data.handles.tabs.run_length = uitab('Parent',data.handles.tabs.main,'Title','Run Length','Background',background);
data.handles.tabs.surface = uitab('Parent',data.handles.tabs.main,'Title','Surface','Background',background);
data.handles.axes.secondary = axes('Parent',data.handles.tabs.plots,'Position',[0.1 0.1 0.9 0.9]); 
data.handles.axes.histogram = axes('Parent',data.handles.tabs.histogram,'Position',[0.1 0.1 0.9 0.9]);
data.handles.axes.run_length_hist = axes('Parent',data.handles.tabs.run_length,'Position',[0.1 0.1 0.9 0.9]);
data.handles.axes.surface = axes('Parent',data.handles.tabs.surface,'Position',[0.1 0.1 0.9 0.9]);


% initiate all the controls
image_position = get(data.handles.axes.main,'Position');

% NOISE scroller and Java handling
data.handles.gui.scroll.noise = uicontrol('Style','slider','Min',data.values.noise_slider_min,'Max',data.values.noise_slider_max,'Value',data.values.noisefactor,'Units','normalized','Position',[image_position(1:2) sliderwidth image_position(4)],'Sliderstep',[0.01 0.1]);
data.handles.gui.scroll.noise.Units = 'points'; pos = data.handles.gui.scroll.noise.Position; data.handles.gui.scroll.noise.Position = [pos(1)-sliderwidth pos(2) sliderwidth pos(4)]; data.handles.gui.scroll.noise.Units = 'normalized';
%make this slider continous
data.handles.gui.scroll.noise_java = addlistener(data.handles.gui.scroll.noise,'Value','PostSet',@(s,e) slider_noise_function(data.handles.gui.scroll.noise,0,data.handles));

% NOISE_MAX scroller and Java handling
data.handles.gui.scroll.noise_max = uicontrol('Style','slider','Min',data.values.noise_slider_min,'Max',data.values.noise_slider_max,'Value',data.values.noisefactor_max,'Units','normalized','Position',[image_position(1:2) sliderwidth image_position(4)],'SliderStep',[0.001 0.01]); % [image_position(1:2) sliderwidth image_position(4)]
data.handles.gui.scroll.noise_max.Units = 'points';data.handles.gui.scroll.noise_max.Position = [pos(1)-sliderwidth pos(2) sliderwidth pos(4)]- [15 0 0 0];data.handles.gui.scroll.noise_max.Units = 'normalized';
% make this slider continous
data.handles.gui.scroll.noise_max_java = addlistener(data.handles.gui.scroll.noise_max,'Value','PostSet',@(s,e) slider_noise_max_function(data.handles.gui.scroll.noise_max,0,data.handles));

% FRAME scroller and Java handling
data.handles.gui.scroll.frame = uicontrol('Style','slider','Min',1,'Max',data.values.num_images,'Value',data.values.frame,'Units','normalized','Position',[image_position(1:2) image_position(3) sliderwidth],'Sliderstep',[1/data.values.num_images 1/data.values.num_images*10]);%'Callback',{@slider_stack,handles}
data.handles.gui.scroll.frame.Units = 'points'; pos2 = data.handles.gui.scroll.frame.Position; data.handles.gui.scroll.frame.Position = [pos2(1) pos2(2)-sliderwidth pos2(3) sliderwidth]; data.handles.gui.scroll.frame.Units = 'normalized';
%make this slider continous
data.handles.gui.scroll.frame_java = addlistener(data.handles.gui.scroll.frame,'Value','PostSet',@(s,e) slider_stack(data.handles.gui.scroll.frame,0,data.handles));

%get handles to the functions in the handles struct
data.handles.gui.function.noise = @slider_noise_function;
data.handles.gui.function.noise_max = @slider_noise_max_function;
data.handles.gui.function.frame = @slider_stack;

% STATIC TEXT for the main GUI
data.handles.gui.texts.dotsize = uicontrol('Style','text','BackgroundColor',background,'String','Dotsize','Units','normalized','Position',[0 0.64 0.1 0.03]);
data.handles.gui.texts.noise = uicontrol('Style','text','BackgroundColor',background,'String','min SNR','Units','normalized','Position',[0 0.54 0.1 0.03]);
%data.handles.gui.texts.tracking_factor = uicontrol('Style','text','BackgroundColor',background,'String','Tracking threshold','Units','normalized','Position',[0 0.34 0.1 0.03]);
data.handles.gui.texts.noise_max = uicontrol('Style','text','BackgroundColor',background,'String','max SNR','Units','normalized','Position',[0 0.44 0.1 0.03]);

% VARIABLE DISPLAY TEXT for the main GUI
data.handles.gui.displays.evaluate = uicontrol('Style','text','BackgroundColor',background,'String','   ','FontSize',20,'Units','normalized','Position',[0 0.83 0.1 0.05]);
data.handles.gui.displays.dot_number = uicontrol('Style','text','BackgroundColor',background,'String','#','Units','normalized','Position',[0 0.75 0.1 0.05]);

% INPUT TEXT for the main GUI
data.handles.gui.input.noise = uicontrol('Style','edit','String',num2str(data.values.noisefactor),'Units','normalized','Position',[0 0.5 0.1 0.05],'FontSize',fontsize,'Callback',{@update_values,data.handles});
data.handles.gui.input.noise_max = uicontrol('Style','edit','BackgroundColor',background,'String',num2str(data.values.noisefactor_max),'Units','normalized','Position',[0 0.4 0.1 0.05],'FontSize',fontsize,'Callback',{@update_values,data.handles});
%data.handles.gui.input.tracking_factor = uicontrol('Style','edit','String',num2str(data.values.tracking_factor),'Units','normalized','Position',[0 0.3 0.1 0.05],'FontSize',fontsize,'Callback',{@update_values,data.handles});
data.handles.gui.input.dotsize = uicontrol('Style','edit','String',num2str(data.values.dotsize),'Units','normalized','Position',[0 0.6 0.1 0.05],'FontSize',fontsize,'Callback',{@update_values,data.handles});

%INPUT TEXT for the Info Tab
data.handles.gui.texts.info.filetype = uicontrol('Parent',data.handles.tabs.info,'Style','text','BackgroundColor',background,'String','Filetype','Units','normalized','Position',[0 0.7 0.5 0.2]);
data.handles.gui.input.info.filetype = uicontrol('Parent',data.handles.tabs.info,'Style','edit','String','','Units','normalized','Callback',{@input_info,data.handles},'Position',[0.5 0.7 0.5 0.2]);
data.handles.gui.texts.info.pixelconversion = uicontrol('Parent',data.handles.tabs.info,'Style','text','BackgroundColor',background,'String','Pixel Converion','Units','normalized','Position',[0 0.4 0.5 0.2]);
data.handles.gui.input.info.pixelconversion = uicontrol('Parent',data.handles.tabs.info,'Style','edit','String','','Units','normalized','Callback',{@input_info,data.handles},'Position',[0.5 0.4 0.5 0.2]);
data.handles.gui.texts.info.cycletime = uicontrol('Parent',data.handles.tabs.info,'Style','text','BackgroundColor',background,'String','Cycle Time','Units','normalized','Position',[0 0.1 0.5 0.2]);
data.handles.gui.input.info.cycletime = uicontrol('Parent',data.handles.tabs.info,'Style','edit','String','','Units','normalized','Callback',{@input_info,data.handles},'Position',[0.5 0.1 0.5 0.2]);


% BUTTONS for the main GUI
data.handles.gui.buttons.evaluate = uicontrol('Style','pushbutton','String','evaluate','Callback',{@button_evaluate,data.handles},'Units','normalized','Position',[0 0.85 0.1 0.05]);
data.handles.gui.buttons.load_file = uicontrol('Style','pushbutton','String','load file','Callback',{@button_load,data.handles},'Units','normalized','Position',[0 0.95 0.1 0.05]);
data.handles.gui.buttons.save_data = uicontrol('Style','pushbutton','String','save data','Callback',{@button_save,data.handles},'Units','normalized','Position',[0 0.9 0.1 0.05]);
data.handles.gui.buttons.change_series = uicontrol('Style','pushbutton','String','change series','Callback',{@button_change_series,data.handles},'Units','normalized','Position',[0 0.85 0.1 0.05]);
data.handles.gui.buttons.forward = uicontrol('Style','pushbutton','String','>>','Callback',{@button_step,1,data.handles},'Units','normalized','Position',[0.83 0.8 0.04 0.03]);
data.handles.gui.buttons.backwards = uicontrol('Style','pushbutton','String','<<','Callback',{@button_step,-1,data.handles},'Units','normalized','Position',[0.79 0.8 0.04 0.03]);
data.handles.gui.buttons.cancel = uicontrol('Style','pushbutton','String','cancel','Callback',{@button_cancel,data.handles},'Units','normalized','Position',[0 0.1 0.1 0.05]);
data.handles.gui.buttons.speed_calculation = uicontrol('Style','pushbutton','String','speed calculation','Callback',{@button_speed,data.handles},'Units','normalized','Position',[0.75 0.1 0.1 0.05]);
data.handles.gui.buttons.pic_by_pic = uicontrol('Style','pushbutton','String','pic by pic','Callback',{@button_pic_by_pic,data.handles},'Units','normalized','Position',[0.75 0.05 0.1 0.05]);
data.handles.gui.buttons.dots_v2 = uicontrol('Style','pushbutton','String','dots v2','Callback',{@button_dots_v2,data.handles},'Units','normalized','Position',[0.75 0 0.1 0.05]);
data.handles.gui.buttons.run_length = uicontrol('Style','pushbutton','String','run length','Callback',{@button_run_length,data.handles},'Units','normalized','Position',[0.75 0.15 0.1 0.05]);
data.handles.gui.buttons.speed_plot = uicontrol('Style','pushbutton','String','speed hist','Callback',{@button_speed_hist,data.handles},'Units','normalized','Position',[0.85 0.1 0.1 0.05]);
data.handles.gui.buttons.speed_export = uicontrol('Style','pushbutton','String','->','Callback',{@button_speed_export,data.handles},'Units','normalized','Position',[0.95 0.1 0.05 0.05]);
data.handles.gui.buttons.run_length_plot = uicontrol('Style','pushbutton','String','run length hist','Callback',{@button_run_length_hist,data.handles},'Units','normalized','Position',[0.85 0.15 0.1 0.05]);
data.handles.gui.buttons.run_length_export = uicontrol('Style','pushbutton','String','->','Callback',{@button_run_length_export,data.handles},'Units','normalized','Position',[0.95 0.15 0.05 0.05]);
data.handles.gui.buttons.all_export = uicontrol('Style','pushbutton','String','->>>','Callback',{@button_all_export,data.handles},'Units','normalized','Position',[0.95 0.2 0.05 0.05]);
data.handles.gui.buttons.reconnect_runs = uicontrol('Style','pushbutton','String','reconnect runs','Callback',{@button_reconnect_runs,data.handles},'Units','normalized','Position',[0.85 0.05 0.1 0.05]);


% CHECKBOXES for the main GUI
data.handles.gui.checkboxes.tracking_all = uicontrol('Style','checkbox','String','mark all traces','Units','normalized','Position',[0.7 0.23 0.15 0.05],'BackgroundColor',background);
data.handles.gui.checkboxes.FIONA_mode = uicontrol('Style','checkbox','String','FIONA mode','Units','normalized','Callback',{@update_values,data.handles},'Position',[0.9 0.23 0.1 0.05],'BackgroundColor',background);
data.handles.gui.checkboxes.Diffusion_mode = uicontrol('Style','checkbox','String','Diffusion mode','Units','normalized','Callback',{@update_values,data.handles},'Position',[0.8 0.23 0.1 0.05],'BackgroundColor',background);
data.handles.gui.checkboxes.multicolor = uicontrol('Style','checkbox','String','multicolor_mode','Units','normalized','Callback',{@update_values,data.handles},'Position',[0.13 0.95 0.1 0.05],'BackgroundColor',background);
data.handles.gui.checkboxes.parallel_computing = uicontrol('Style','checkbox','String','parallel computing','Units','normalized','Callback',{@update_values,data.handles},'Position',[0.8 0.95 0.1 0.05],'BackgroundColor',background);

% PLOTS for the main axes
axes(data.handles.axes.main)
data.handles.axes.main.XLimMode = 'manual'; data.handles.axes.main.YLimMode = 'manual';
data.handles.plots.image = imshow(ones(512,512),'Border','tight');
hold on
data.handles.plots.dots = scatter(0,0,'Marker','o','SizeData',40,'LineWidth',1,'MarkerEdgeColor','flat','MarkerFaceAlpha',0.5);
%data.handles.plots.dot_chosen = scatter(0,0,'Marker','x','SizeData',800,'LineWidth',3,'MarkerEdgeColor',[0 0.54 1]);
data.handles.plots.speed_calculated = scatter(0,0,'Marker','x','SizeData',30,'LineWidth',3,'MarkerEdgeColor',[0 0.8 0]);
data.handles.plots.tracking_pos = scatter(0,0,'Marker','.','SizeData',200,'MarkerFaceColor','flat');
hold off
set(get(data.handles.axes.main,'Children'),'ButtonDownFcn',{@select_point,data.handles});

% PLOTS for the tracking axes
axes(data.handles.axes.secondary)
data.handles.plots.tracking = plot(1:3,1:3);
hold on
data.handles.plots.tracking_text = text(1,1,'');
data.handles.plots.bleaching = plot(0,0,'LineWidth',0.5);
data.handles.plots.speed_calculation = scatter(0,0,'Marker','o','SizeData',40,'MarkerEdgeColor',[0.8 0 0.8]);
data.handles.plots.frame_pos = plot(0,0,'LineWidth',3);
hold off

data.handles.plots.surface = surface(ones(100),'Parent',data.handles.axes.surface);
data.handles.axes.secondary.Box = 'off';data.handles.axes.histogram.Box = 'off';

data.values = data.values; data.handles = data.handles;
guidata(data.handles.figures.main,data)

end


function button_load(~,~,handles)
    reset_values(0,0,handles);
    data = guidata(handles.figures.main);
    data.values.meta_data.series = '';
    data.values.stack = [];
    data.values.lif_data = [];
    data.values.dot = 1;
    data.values.frame = 1; handles.gui.scroll.frame.Value = 1;
    [filename,pathname] = uigetfile({'*.tif;*.tiff;*.lif;*.sif;*.mat'},'What file should be loaded',data.values.path_load);
    data.values.img_path = [pathname,filename];
    skip_display_reset = 0;
    
    if ~isempty(regexp(filename,'\w*.tif\w*','match'))
        % Read in as TIFF or TIF file
        info = imfinfo(data.values.img_path);
        data.values.num_images = numel(info);
        for fr = 1:data.values.num_images
            data.values.stack(:,:,fr) = double(imread(data.values.img_path,fr));
            if size(data.values.stack(:,:,fr),3) > 1;data.values.stack(:,:,fr) = sum(data.values.stack(:,:,fr),3); end
            %data.values.stack(:,:,fr) = data.values.stack(:,:,fr)/max(max(data.values.stack(:,:,fr)));
        end
        first_pic = sum(imread(data.values.img_path,1),3);
        
        %Import Metadata from csv file saved from Fiji with same name as file
        %itself
        if strcmp(filename(end-1:end),'ff'); trunc = 5;else trunc = 4; end
        location_meta = [pathname filename(1:end-trunc) '.csv'];
        if exist(location_meta,'file')
            meta_data = get_meta_data(location_meta);
        else
            meta_data.CycleTime = 1;
            meta_data.PixelConversion = 0.158;
            meta_data.FileType = 'unknown';
        end
        data.values.meta_data = meta_data;
        
    elseif strcmp('lif',filename(end-2:end))
        % Read in as LIF file Leica
        response = questdlg('Load single series?','Lif file load');
        channel = 1;
        if strcmp(response,'No')
            series = inputdlg('Display Series');series = str2num(series{1});
            data.values.lif_data = bfopen(data.values.img_path);
            meta_hash_table = data.values.lif_data{series,2};
            data.values.num_images = size(data.values.lif_data{series,1},1);
            for fr = 1:data.values.num_images
                data.values.stack(:,:,fr) = double(data.values.lif_data{series,1}{fr});
            end
            first_pic = data.values.stack(:,:,1);
        else
            if data.values.multicolor_mode == 0
                series = inputdlg('Choose Series Number');series = str2num(series{1});
            elseif data.values.multicolor_mode == 1
                prompt = {'Enter Series','Enter Channel'};
                dlg_title = 'Series and Channel Choice';
                defaultans = {'1','1'};
                answer = inputdlg(prompt,dlg_title,1,defaultans);
                series = str2num(answer{1});
                channel = str2num(answer{2});
            end
            disp(['loading series ' num2str(series)])
            disp(['loading channel ' num2str(channel)])
            data.values.meta_data.series = num2str(series);
            reader = bfGetReader(data.values.img_path);
            reader.setSeries(series - 1);
            data.values.num_images = reader.getImageCount();
            meta_hash_table = reader.getSeriesMetadata();
            data.values.num_images = data.values.num_images/(data.values.multicolor_mode + 1);
            for fr = 1:data.values.num_images
                frame_to_read = fr*(data.values.multicolor_mode+1) - abs(channel-data.values.multicolor_mode-1);
                data.values.stack(:,:,fr) = bfGetPlane(reader,frame_to_read);
            end
            first_pic = data.values.stack(:,:,1);
        end
        % Get Metadata directly from lif file
        length = str2double(meta_hash_table.get('Image|DimensionDescription|Length'));
        if isnan(length); length = str2double(meta_hash_table.get('DimensionDescription|Length')); end
        N_images = str2double(meta_hash_table.get('Image|DimensionDescription|NumberOfElements'));
        if isnan(N_images); N_images = str2double(meta_hash_table.get('DimensionDescription|NumberOfElements')); end
        data.values.meta_data.CycleTime = length/N_images;
        data.values.meta_data.PixelConversion = 0.1585546;
        data.values.meta_data.FileType = 'lif direct';
        
    elseif strcmp('sif',filename(end-2:end))
        % Read in as SIF file Andor
        data.values.sif_data = bfopen(data.values.img_path);
        meta_hash_table = data.values.sif_data{1,2};
        data.values.num_images = size(data.values.sif_data{1,1},1);
        for fr = 1:data.values.num_images
            data.values.stack(:,:,fr) = double(data.values.sif_data{1,1}{fr});
        end
        first_pic = data.values.stack(:,:,1);
        cycle = meta_hash_table.get('Global Line #03'); cycle = cycle(43:49);
        data.values.meta_data.CycleTime = str2double(cycle);
        data.values.meta_data.PixelConversion = 0.168;
        data.values.meta_data.FileType = 'sif direct';
    elseif strcmp('mat',filename(end-2:end))
        load([pathname filename]);
        data.values = values;
        first_pic = data.values.stack(:,:,1);
        skip_display_reset = 1;
    else
        error('Unknown File name')
    end
        disp(['file ' filename])
    % save the load path
        data.values.path_load = pathname;
    
    % reset the display after loading new series
        set(data.handles.plots.image,'CData',first_pic/max(first_pic(:)))
        cla(data.handles.axes.surface)
        data.handles.plots.surface = surface(first_pic,'Parent',data.handles.axes.surface,'FaceColor','interp');
        colormap(data.handles.axes.surface,jet);
        set(data.handles.plots.dots,'XData',0,'YData',0); %%% change to 0 again!
        %set(data.handles.plots.dot_chosen,'XData',0,'YData',0);
        set(data.handles.plots.tracking_pos,'XData',0,'YData',0);
        set(data.handles.plots.bleaching,'XData',0,'YData',0);
        set(data.handles.plots.tracking,'XData',0,'YData',0);
        data.handles.axes.main.YLim = data.handles.plots.image.YData; data.handles.axes.main.XLim = data.handles.plots.image.XData;
        set(data.handles.gui.scroll.frame,'Max',data.values.num_images);
        data.handles.gui.scroll.frame.SliderStep = [1/data.values.num_images 1/data.values.num_images*10]; %readjust the scrolling behaviour
        data.handles.axes.secondary.XLim = [1 data.values.num_images]; %Hier Problem mit Georgs Daten
        data.handles.gui.input.info.filetype.String = data.values.meta_data.FileType;
        data.handles.gui.input.info.pixelconversion.String = num2str(data.values.meta_data.PixelConversion);
        data.handles.gui.input.info.cycletime.String = num2str(data.values.meta_data.CycleTime);

        guidata(handles.figures.main,data)
        reset_values(0,0,handles);
        
    guidata(handles.figures.main,data)
    disp('load complete')
    beep;pause(0.2);beep;
end

function button_save(~,~,handles)
    data = guidata(handles.figures.main);
    [filename,pathname] = uiputfile('*.mat');
    values = data.values;
    save([pathname filename],'values')
    data.values.path = pathname;
    guidata(handles.figures.main,data)
end

function button_change_series(~,~,handles)
    data = guidata(handles.figures.main);
    if isfield(data.values,'meta_data') && ~strcmp('lif direct',data.values.meta_data.FileType)
        error('please load lif file directly first')
    elseif ~isfield(data.values,'meta_data')
        error('please load file first')
    end
    series = inputdlg('Choose Series Number');series = str2double(series{1});
    meta_hash_table = data.values.lif_data{series,2};
    data.values.num_images = size(data.values.lif_data{series,1},1);
    for fr = 1:data.values.num_images
        data.values.stack(:,:,fr) = double(data.values.lif_data{series,1}{fr});
    end
    first_pic = data.values.stack(:,:,1);

    % Get Metadata directly from lif file
    data.values.meta_data.CycleTime = str2double(meta_hash_table.get('ATLCameraSettingDefinition|CycleTime'));
    data.values.meta_data.PixelConversion = 0.1585546;
    data.values.meta_data.FileType = 'lif direct';
    guidata(handles.figures.main,data)
    % reset the display after loading new series
    data.values.frame = 1;
    data.handles.gui.scroll.frame.Value = 1;
    data.handles.gui.scroll.frame.Max = data.values.num_images;
    data.values.dot = 1;
    data.handles.plots.image.CData = data.values.stack(:,:,data.values.frame)/max(max(data.values.stack(:,:,data.values.frame)));drawnow;
    set(data.handles.plots.image,'CData',first_pic/max(first_pic(:)))
    set(data.handles.plots.dots,'XData',0,'YData',0); %%% change to 0 again!
    set(data.handles.plots.dot_chosen,'XData',0,'YData',0);
    set(data.handles.plots.tracking_pos,'XData',0,'YData',0);
    set(data.handles.plots.bleaching,'XData',0,'YData',0);
    set(data.handles.plots.tracking,'XData',0,'YData',0);
    set(data.handles.plots.speed_calculation,'XData',0,'YData',0);
    data.handles.axes.main.YLim = data.handles.plots.image.YData; data.handles.axes.main.XLim = data.handles.plots.image.XData;
 
    data.handles.axes.secondary.XLim = [1 data.values.num_images]; %Hier Problem mit Georgs Daten
    data.handles.gui.input.info.filetype.String = data.values.meta_data.FileType;
    data.handles.gui.input.info.pixelconversion.String = num2str(data.values.meta_data.PixelConversion);
    data.handles.gui.input.info.cycletime.String = num2str(data.values.meta_data.CycleTime);
    guidata(handles.figures.main,data)
    reset_values(0,0,handles)
end

function slider_stack(source,~,handles)
    data = guidata(handles.figures.main);
    data.values.frame = round(source.Value);
    ext = @(x) x(:);
    range_max = @(x) x(end-round(0.0001*length(x)));
    range_min = @(x) x(round(0.0005*length(x))+1);
    data.handles.plots.image.CData = data.values.stack(:,:,data.values.frame);%/max(max(data.values.stack(:,:,data.values.frame)));
    %data.handles.plots.image.CLim = [min(min(data.values.stack(:,:,data.values.frame))) range_max(sort(ext(data.values.stack(:,:,data.values.frame))))]
    data.handles.axes.main.CLim = [range_min(sort(ext(data.values.stack(:,:,data.values.frame)))) range_max(sort(ext(data.values.stack(:,:,data.values.frame))))];
    drawnow;
    
    set(data.handles.plots.frame_pos,'XData',[data.values.frame data.values.frame],'YData',get(data.handles.axes.secondary,'YLim'))
    %%% added for v2 
    if isfield(data.values,'peak_ID_max')
        colormap = lines(data.values.peak_ID_max);
        if data.handles.gui.checkboxes.tracking_all.Value == 0
            set(data.handles.plots.dots,'XData',data.values.peakvalues_all_plot{data.values.frame}(3,:),'YData',data.values.peakvalues_all_plot{data.values.frame}(2,:),'CData',colormap(data.values.peakvalues_all_plot{data.values.frame}(4,:),:))
        else
            plot_runs = cat(2,data.values.runs{:});
            set(data.handles.plots.dots,'XData',plot_runs(3,:),'YData',plot_runs(2,:),'CData',colormap(plot_runs(4,:),:))
        end
    elseif isfield(data.values,'peakvalues_all')
        data.handles.plots.dots.XData = data.values.peakvalues_all{data.values.frame}(3,:);data.handles.plots.dots.YData = data.values.peakvalues_all{data.values.frame}(2,:);data.handles.plots.dots.CData = [0 0.6 0.8];
    else
        data.handles.plots.dots.XData = [];data.handles.plots.dots.YData = [];data.handles.plots.dots.CData = [0 0.6 0.8];
    end
    % also update the surface plot if tab is chosen
    if strcmp(data.handles.tabs.main.SelectedTab.Title,'Surface')
        data.handles.plots.surface.ZData = data.values.stack(:,:,data.values.frame);
        data.handles.plots.surface.CData = data.values.stack(:,:,data.values.frame);
    end
    
    
    guidata(handles.figures.main,data)
end

function slider_noise_function(~,~,handles)
    data = guidata(handles.figures.main);
    data.handles.gui.displays.dot_number.String = '...';
    drawnow
    data.values.noisefactor = data.handles.gui.scroll.noise.Value;
    guidata(handles.figures.main,data)
    data = choose_noise_factor_tracking_v3(0,0,0,data.values.dotsize,0,handles);
    if size(data.values.peakvalues,2) > 0
        set(data.handles.plots.dots,'XData',data.values.peakvalues(3,:),'YData',data.values.peakvalues(2,:))
    end
    set(data.handles.gui.displays.dot_number,'String',num2str(data.values.peaknumber));
    guidata(handles.figures.main,data);
    data.handles.gui.input.noise.String = num2str(data.values.noisefactor);
    update_plot(handles)
end

function slider_noise_max_function(source,~,handles)
    data = guidata(handles.figures.main);
    set(data.handles.gui.displays.dot_number,'String','...')
    drawnow
    data.values.noisefactor_max = get(source,'Value');
    set(data.handles.gui.input.noise_max,'String',num2str(data.values.noisefactor_max));
    guidata(handles.figures.main,data);
    data = choose_noise_factor_tracking_v3(0,0,0,data.values.dotsize,0,handles);
    if size(data.values.peakvalues,2) > 0
        set(data.handles.plots.dots,'XData',data.values.peakvalues(3,:),'YData',data.values.peakvalues(2,:))
    end
    set(data.handles.gui.displays.dot_number,'String',num2str(data.values.peaknumber));
    guidata(handles.figures.main,data);
    data.handles.gui.input.noise_max.String = num2str(data.values.noisefactor_max);
    update_plot(handles)
end

function update_plot(handles)
    data = guidata(handles.figures.main);
    
    %%% PEAKVALUES DOTS
    if isfield(data.values,'peak_ID_max')
        colormap = lines(data.values.peak_ID_max);
        if data.handles.gui.checkboxes.tracking_all.Value == 0
            set(data.handles.plots.dots,'XData',data.values.peakvalues_all_plot{data.values.frame}(3,:),'YData',data.values.peakvalues_all_plot{data.values.frame}(2,:),'CData',colormap(data.values.peakvalues_all_plot{data.values.frame}(4,:),:))
        else
            plot_runs = cat(2,data.values.runs{:});
            set(data.handles.plots.dots,'XData',plot_runs(3,:),'YData',plot_runs(2,:),'CData',colormap(plot_runs(4,:),:))
        end
    elseif isfield(data.values,'peakvalues_all')
        data.handles.plots.dots.XData = data.values.peakvalues_all{data.values.frame}(3,:);data.handles.plots.dots.YData = data.values.peakvalues_all{data.values.frame}(2,:);data.handles.plots.dots.CData = [0 0.6 0.8];
    elseif isfield(data.values,'peakvalues') && isfield(data.values,'peaknumbers_all')
        if data.values.peaknumbers_all(data.values.frame) > 0
            data.handles.plots.dots.XData = data.values.peakvalues(3,:);data.handles.plots.dots.YData = data.values.peakvalues(2,:);data.handles.plots.dots.CData = [0 0.6 0.8];
        end
    else
        data.handles.plots.dots.XData = [];data.handles.plots.dots.YData = [];data.handles.plots.dots.CData = [0 0.6 0.8];
    end
    if size(data.values.peakvalues,2) < data.values.dot; data.values.dot = 1; end
%    set(data.handles.plots.dot_chosen,'XData',data.values.peakvalues(3,data.values.dot),'YData',data.values.peakvalues(2,data.values.dot))
    %set(data.handles.plots.,'XData',[data.values.frame data.values.frame],'YData',get(data.handles.axes.secondary,'YLim'))
    
    
    %%% TRACKING DATA
    if isfield(data.values,'tracking') == 1
        if data.handles.gui.checkboxes.tracking_all.Value == 0
            set(data.handles.plots.tracking_pos,'XData',data.values.tracking(2,data.values.dot,data.values.frame),'YData',data.values.tracking(1,data.values.dot,data.values.frame),'CData',data.values.cmap(data.values.frame,:)) 
        else
            X_tracking_data = squeeze(data.values.tracking(2,:,1:data.values.frame)); Y_tracking_data = squeeze(data.values.tracking(1,:,1:data.values.frame));
            C_tracking_data = repmat(jet(data.values.peaknumber),data.values.frame,1);
            set(data.handles.plots.tracking_pos,'XData',X_tracking_data(:),'YData',Y_tracking_data(:),'CData',C_tracking_data)%,'MarkerEdgeColor',data.values.cmap(data.values.frame,:))
        end
        set(data.handles.plots.tracking,'XData',1:size(data.values.tracking(3,data.values.dot,:),1),'YData',data.values.tracking(3,data.values.dot,:));
        if max(max(squeeze(data.values.tracking(3,data.values.dot,:)))) > 0
            set(data.handles.axes.secondary,'YLim',[0 max(max(squeeze(data.values.tracking(3,data.values.dot,:))))]);
        else
            set(data.handles.axes.secondary,'YLim',[0 20]);
        end
    end
    
end

function select_point(~,~,handles)
    data = guidata(handles.figures.main);
    if isfield(data.values,'runs') && isfield(data.values,'peakvalues_all')
        distances = zeros(2,data.values.num_images);
        cP = get(gca,'Currentpoint');
        cP = cP(1,1:2);
        for i = 1:data.values.num_images
            prox_matrix(1,1:size(data.values.peakvalues_all{i},2)) = ones(1,size(data.values.peakvalues_all{i},2))*cP(2);
            prox_matrix(2,1:size(data.values.peakvalues_all{i},2)) = ones(1,size(data.values.peakvalues_all{i},2))*cP(1);
            proximity = data.values.peakvalues_all{i}(2:3,:) - prox_matrix;
            proximity = sum(abs(proximity),1);
            distances(1,i) = find(abs(proximity) == min(abs(proximity)));
            distances(2,i) = min(abs(proximity));
            clear prox_matrix
        end
        frame = find(distances(2,:) == (min(distances(2,:))));
        peak = distances(1,frame);
        peak_ID = data.values.peakvalues_all{frame}(4,peak);
        for k = 1:length(data.values.runs)
            if data.values.runs{k}(4,1) == peak_ID
                data.values.run_plot = k;
                break
            else
                data.values.run_plot = 1;
            end
        end
        guidata(handles.figures.main,data)
        button_step(0,0,0,handles)
        update_plot(handles)
    end
end

function button_evaluate(~,~,handles)
    data = guidata(handles.figures.main);
    set(data.handles.gui.displays.evaluate,'String','...')
    drawnow

    data.values.frame = 1;
    [analysis,data.values.pic] = imageanalysis_tracking(handles);
    data.values.bleaching_data = analysis.bleaching_data; data.values.peakvalues = analysis.peakvalues_original; data.values.num_images = analysis.num_images;data.values.tracking = analysis.tracking;
    set(data.handles.gui.displays.dot_number,'String','distance calculations')
    drawnow
    guidata(data.handles.figures.main,data)
    data = distance_calc(data.handles);
    data.values.cmap= winter(data.values.num_images);
    guidata(handles.figures.main,data);
    choose_noise_factor_tracking_v3(data.values.img_path,data.values.noisefactor,data.values.noisefactor_max,data.values.dotsize,handles);
    data = guidata(handles.figures.main);
    guidata(handles.figures.main,data)
    set(data.handles.gui.displays.evaluate,'String','')
    set(data.handles.gui.displays.dot_number,'String',num2str(data.values.peaknumber))
    
    update_plot(handles)
end

function button_cancel(~,~,handles)
    data = guidata(handles.figures.main);
    set(data.handles.gui.buttons.cancel,'Enable','off')
end

function button_run_length(~,~,handles)
    data = guidata(handles.figures.main);
    max_run_length = 50;
    num_runs = size(data.values.runs,1);
    for i = 1:num_runs
        if max(data.values.runs{i}(6,:)) < max_run_length %&& data.values.runs{i}(8,1) == 1 % this can be activated to only take runs into account that have really been measured
            run_length(i) = max(data.values.runs{i}(6,:));
        end
    end
    runs = run_length*data.values.meta_data.PixelConversion;
    axes(data.handles.axes.run_length_hist)
    histogram(runs,'FaceColor','w')
    guidata(handles.figures.main,data);
end

function button_run_length_hist(~,~,handles)
    data = guidata(handles.figures.main);
    data = run_length_calc(data.handles);
    guidata(handles.figures.main,data)
end

function button_run_length_export(~,~,handles)
    data = guidata(handles.figures.main);
    if isfield(data.values.meta_data,'series')
        [filename,pathname] = uiputfile('*.txt','Save run length data as',[data.values.path_save 'length_' data.values.meta_data.series]);
    else
        [filename,pathname] = uiputfile('*.txt','Save run length data as',[data.values.path_save 'length_']);
    end
    dlmwrite([pathname filename],data.values.run_lengths); 
    data.values.path_save = pathname;
    guidata(handles.figures.main,data)
end

function button_reconnect_runs(~,~,handles)
    data = guidata(handles.figures.main);
    data = reconnect_runs(data.handles);
    guidata(handles.figures.main,data)
end

function button_speed(~,~,handles)
    data = guidata(handles.figures.main);
    data = speed_calc_v2(data.handles);
    guidata(handles.figures.main,data);
    beep;pause(0.2);beep;
end

function button_pic_by_pic(~,~,handles)
    data = guidata(handles.figures.main);
    data = pic_by_pic(data.handles);
    guidata(handles.figures.main,data);
    data = distance_calc_v2(data.handles);
    %data.values.runs
    guidata(handles.figures.main,data);
    beep;pause(0.2);beep;
end

function button_dots_v2(~,~,handles)
    data = guidata(handles.figures.main);
    if data.values.parallel_computing_mode == 1
        mode = 2;
    else
        mode = 1;
    end
    data = choose_noise_factor_tracking_v3(0,0,0,data.values.dotsize,mode,handles);
    guidata(handles.figures.main,data);
    update_plot(handles)
    beep;pause(0.2);beep;
end

function button_step(~,~,set,handles)
        data = guidata(handles.figures.main);
        if 0 < (data.values.run_plot+set) && (data.values.run_plot+set) <= size(data.values.runs,1)
            data.values.run_plot = data.values.run_plot + set;
        end
        if data.values.subpix_gauss == 1
           data.values.speed.speed_hist(data.values.run_plot) = 0;
        end
        
        if set == 0
            var_condition = true;
        else
            var_condition = (data.values.runs{data.values.run_plot}(8,1) == 1);
        end
        
    if  data.values.run_plot == size(data.values.runs,1) || data.values.run_plot == 1 || var_condition
        data.handles.plots.tracking.XData = data.values.runs{data.values.run_plot}(7,:);data.handles.plots.tracking.YData = data.values.runs{data.values.run_plot}(6,:);
        data.handles.axes.secondary.YLim = [-0.1 max(data.values.runs{data.values.run_plot}(6,:))]; data.handles.axes.secondary.XLim = [data.values.runs{data.values.run_plot}(7,1) data.values.runs{data.values.run_plot}(7,end)];
        data.handles.plots.speed_calculated.XData = data.values.runs{data.values.run_plot}(3,:); data.handles.plots.speed_calculated.YData = data.values.runs{data.values.run_plot}(2,:);
        data.handles.gui.displays.dot_number.String = num2str(data.values.run_plot);
        data.handles.plots.speed_calculation.XData = data.values.speed.xfit{data.values.run_plot};data.handles.plots.speed_calculation.YData = data.values.speed.yfit{data.values.run_plot};
        data.handles.plots.tracking_text.String = num2str(round(data.values.speed.speed_hist(data.values.run_plot)));
        data.handles.plots.tracking_text.Position = [0.1*(max(data.values.runs{data.values.run_plot}(7,:))-min(data.values.runs{data.values.run_plot}(7,:)))+min(data.values.runs{data.values.run_plot}(7,:)) 0.9*(max(data.values.runs{data.values.run_plot}(6,:))-min(data.values.runs{data.values.run_plot}(6,:)))+min(data.values.runs{data.values.run_plot}(6,:))];
        guidata(handles.figures.main,data)        
    else
       guidata(handles.figures.main,data)
       button_step(0,0,set,handles)        
    end
    drawnow
end

function button_speed_hist(~,~,handles)
    data = guidata(handles.figures.main);
    speed_hist_fit(data.handles);
    guidata(handles.figures.main,data);
end

function button_speed_export(~,~,handles)
    data = guidata(handles.figures.main);
    if isfield(data.values.meta_data,'series')    
        [filename,pathname] = uiputfile('*.txt','Save speed data as',[data.values.path_save 'speed_' data.values.meta_data.series]);
    else
        [filename,pathname] = uiputfile('*.txt','Save speed data as',[data.values.path_save 'speed_']);
    end
    hist_data = data.values.speed.speed_hist(data.values.speed.speed_hist > 0)';
    dlmwrite([pathname filename],hist_data); 
    data.values.path_save = pathname;
    guidata(handles.figures.main,data)
end

function button_all_export(~,~,handles)
    data = guidata(handles.figures.main);
    if isfield(data.values.meta_data,'series')    
        [filename,pathname] = uiputfile('*.txt','Save speed data as',[data.values.path_save 'data_' data.values.meta_data.series]);
    else
        [filename,pathname] = uiputfile('*.txt','Save speed data as',[data.values.path_save 'data_']);
    end
    % get physical values for the runs
    runs_export = data.values.runs_analyzed;
    runs_export(:,3) = data.values.runs_analyzed(:,3)*data.values.meta_data.PixelConversion;
    runs_export(:,4) = data.values.runs_analyzed(:,4)*data.values.meta_data.PixelConversion*1000/data.values.meta_data.CycleTime;
    hist_data = data.values.speed.speed_hist(data.values.speed.speed_hist > 0)';
    dlmwrite([pathname 'speed_' filename(6:end)],hist_data);
    dlmwrite([pathname 'length_' filename(6:end)],data.values.run_lengths);
    dlmwrite([pathname filename],runs_export);
    runs = data.values.runs;
    save([pathname 'full_runs_' filename(1:end-4) '.mat'],'runs');
    data.values.path_save = pathname;
    guidata(handles.figures.main,data)
    disp('save complete')
end

function input_info(~,~,handles)
    data = guidata(handles.figures.main);
    data.values.meta_data.FileType = data.handles.gui.input.info.filetype.String;
    data.values.meta_data.PixelConversion = str2num(data.handles.gui.input.info.pixelconversion.String);
    data.values.meta_data.CycleTime = str2num(data.handles.gui.input.info.cycletime.String);
    guidata(handles.figures.main,data);
end

function update_values(~,~,handles)
    data = guidata(handles.figures.main);
    % get values
    data.values.noisefactor = str2double(data.handles.gui.input.noise.String);
    data.values.noisefactor_max = str2double(data.handles.gui.input.noise_max.String);
    data.values.dotsize = str2double(data.handles.gui.input.dotsize.String);
    data.values.meta_data.CycleTime = data.handles.gui.input.info.cycletime.Value;
    data.values.FIONA_mode = data.handles.gui.checkboxes.FIONA_mode.Value;
    data.values.Diffusion_mode = data.handles.gui.checkboxes.Diffusion_mode.Value;
    data.values.multicolor_mode = data.handles.gui.checkboxes.multicolor.Value;
    data.values.subpix_gauss = data.handles.gui.checkboxes.FIONA_mode;
    data.values.parallel_computing_mode = data.handles.gui.checkboxes.parallel_computing.Value;
    
    % adjust sliders if values are to high
    if data.handles.gui.scroll.noise.Max < data.values.noisefactor 
        data.handles.gui.scroll.noise.Max = data.values.noisefactor;
    end    
    if data.handles.gui.scroll.noise_max.Max < data.values.noisefactor_max 
        data.handles.gui.scroll.noise_max.Max = data.values.noisefactor_max;
    end      
    
    
    % set sliders and save data
    data.handles.gui.scroll.noise.Value = data.values.noisefactor;
    data.handles.gui.scroll.noise_max.Value = data.values.noisefactor_max;
    guidata(handles.figures.main,data)
    % calculate new peaks for frame
    if isfield(data.values,'stack')
        data = choose_noise_factor_tracking_v3(0,0,0,data.values.dotsize,0,handles);
        set(data.handles.gui.displays.dot_number,'String',num2str(data.values.peaknumber));
    end
    guidata(handles.figures.main,data);
    update_plot(handles)
end

function reset_values(~,~,handles)
    data = guidata(handles.figures.main);
    if isfield(data.values,'peak_ID_max')
        data.values = rmfield(data.values,'peak_ID_max');
    end
    data.values.frame = 1;
    data.values.peakvalues = zeros(5,1);
    data.values.cmap= winter(data.values.num_images);
    if isfield(data.values,'peakvalues_all')
        data.values = rmfield(data.values,'peakvalues_all');
    end
    if isfield(data.values,'peakvalues_all_plot')
        data.values = rmfield(data.values,'peakvalues_all_plot');
    end    
    data.values.gauss_fit = cell(1,1);
    data.values.runs = cell(1,1);
    if isfield(data.values,'tracking')
        data.values = rmfield(data.values,'tracking');
    end
    guidata(handles.figures.main,data);
    update_plot(handles)
end

