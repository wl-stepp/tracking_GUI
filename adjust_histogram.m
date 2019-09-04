function adjust_output = adjust_histogram(varargin)

if nargin == 1
    data.hist_data = varargin{1};
    data.Trunc = 0;
elseif nargin == 2
    data.hist_data = varargin{1};
    data.Trunc = varargin{2};
end

sliderwidth = 15;
data.offset = 0;
data.muHat = 0; data.err = 0;
f = fittype('a*x');
fit = cfit(f,0);


handles.fig = figure; handles.fig.Color = 'white';
handles.hist = histogram(data.hist_data);
hold on
handles.cum = stairs(0,0,'LineWidth',5,'Color',[0, 92, 230]/255);
handles.fit = plot(fit);handles.fit.Visible = 'off';handles.fit.LineWidth = 2;
hold off
handles.axes = gca(); handles.axes.Box = 'off'; handles.axes.XLim = [handles.axes.XLim(1)-0.1*diff(handles.axes.XLim) handles.axes.XLim(2)+0.1*diff(handles.axes.XLim)];
data.orig_BinEdges = handles.hist.BinEdges;
data.BinEdges = handles.hist.BinEdges;
data.orig_BinWidth = min(diff(data.orig_BinEdges));
data.cumulative_mode = 0;


guidata(handles.fig,data)

%Button that is used for waiting for the user input and closing the figure
handles.use = uicontrol('Style','pushbutton','String','use','Callback',@button_use,'Units','normalized','Position',[0 0 0.1 0.05]);

% Text for showing fit properties
handles.text = text(handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.05),handles.axes.YLim(2)*0.95,'','FontSize',12);

% CHECKBOX for cumulative histogram
handles.cumulative = uicontrol('Style','checkbox','String','cumulative','Units','normalized','Position',[0.4 0.95 0.2 0.05],'Callback', {@update_parameters,handles,2},'BackGround','white'); 
handles.cumulative.Visible = 'off';

% Create pop-up menu
handles.setfit = uicontrol('Style','popupmenu','String', {'none','gaussian','exp','exp2','kin2','gauss2'},'Units','normalized','Position',[0 0.05 0.15 0.05],'Callback', {@setfit,handles}); 
% put this handle into the data structure so it can be used by the checkbox
% Callback function.
data.handles.setfit = handles.setfit;

% SCROLLER OFFSET
handles.offset = uicontrol('Style','slider','Min',0,'Max',data.orig_BinWidth,'Value',0,'Units','normalized','Position',[handles.axes.Position(1:3) sliderwidth],'Sliderstep',[0.01 0.1]);%'Callback',{@slider_stack,handles}
handles.offset.Units = 'points'; pos2 = handles.offset.Position; handles.offset.Position = [pos2(1) 0 pos2(3) sliderwidth]; handles.offset.Units = 'normalized';
%make this slider continous
handles.offset_java = addlistener(handles.offset,'Value','PostSet',@(s,e) slider_offset(handles,0));

% SCROLLER NUMBins
handles.numbins = uicontrol('Style','slider','Min',1,'Max',handles.hist.NumBins*10,'Value',handles.hist.NumBins,'Units','normalized','Position',[handles.axes.Position(1:2) sliderwidth handles.axes.Position(4)],'Sliderstep',[1/handles.hist.NumBins/10 1/handles.hist.NumBins/5]);%'Callback',{@slider_stack,handles}
handles.numbins.Units = 'points'; pos = handles.numbins.Position; handles.numbins.Position = [10 pos(2) sliderwidth pos(4)]; handles.numbins.Units = 'normalized';
%make this slider continous
handles.numbins_java = addlistener(handles.numbins,'Value','PostSet',@(s,e) slider_numbins(handles,0));


guidata(handles.fig,data)

drawnow
handles.use.Value = 0;
waitfor(handles.use,'String')
data = guidata(handles.fig);
adjust_output.hist_BinEdges = data.BinEdges;
adjust_output.fittype = handles.setfit.Value;
adjust_output.cumulative_mode = data.cumulative_mode;
if adjust_output.cumulative_mode == 1
    adjust_output.err = data.err;
    adjust_output.mu = data.muHat;
end
delete(handles.fig)
end

function slider_offset(handles,~)
data = guidata(handles.fig);
data.offset = handles.offset.Value;
handles.hist.BinEdges = data.orig_BinEdges + handles.offset.Value;
bin_width = min(diff(handles.hist.BinEdges));
handles.hist.BinEdges = [handles.hist.BinEdges(1)-bin_width handles.hist.BinEdges];
data.BinEdges = handles.hist.BinEdges;
data = deactivate_offset(handles,data);
guidata(handles.fig,data)
do_fit(handles.setfit,handles)
end

function slider_numbins(handles,~)

data = guidata(handles.fig);
handles.hist.NumBins = round(handles.numbins.Value);
data.orig_BinEdges = handles.hist.BinEdges;
if handles.offset.Value > min(diff(data.orig_BinEdges))
    handles.offset.Value = 0;
end
data.orig_BinWidth = min(diff(data.orig_BinEdges));
handles.offset.Max = data.orig_BinWidth;
data.BinEdges = handles.hist.BinEdges;
data = deactivate_offset(handles,data);

guidata(handles.fig,data)
do_fit(handles.setfit,handles)
end

function button_use(handle,~)
handle.String = 'used';
end


function do_fit(hObject,handles)
data = guidata(handles.fig);
handles.cumulative.Visible = 'off';
% turn cumulative off if not in exponential mode
if hObject.Value ~= 3
     data = update_parameters(handles.cumulative,0,handles,0);
end

switch hObject.Value
    case 1
        handles.fit.Visible = 'off'; 
        handles.text.String = '';
    case 2 
        handles.fit.Visible = 'on';
        d = diff(data.BinEdges)/2;
        BinCenters = data.BinEdges(1:end-1) + d;
        Values = handles.hist.Values;
        [f,goodness] = fit(BinCenters(:),Values(:),'gauss1');
        handles.fit.YData = feval(f,handles.fit.XData);
        handles.text.String = {[num2str(f.b1),'  ',num2str(f.c1)],[num2str(goodness.rsquare),'  ',num2str(sum(Values))]}; handles.text.Position(1:2) = [handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.05), handles.axes.YLim(2)*0.95];
    case 3 % EXP fit also with the cumulative_mode
        handles.cumulative.Visible = 'on';
        if data.cumulative_mode == 0
            handles.fit.Visible = 'on'; handles.offset.Value = 0; data.offset = 0;
            data.BinEdges = linspace(min(data.hist_data),max(data.hist_data),handles.hist.NumBins);
            handles.hist.BinEdges = data.BinEdges;
            d = diff(data.BinEdges)/2;
            BinCenters = data.BinEdges(1:end-1) + d; BinCenters = BinCenters(:);
            Values = handles.hist.Values(:);
            [f,goodness] = fit(BinCenters,Values,'exp1');
            handles.fit.YData = feval(f,handles.fit.XData);
            handles.text.String = {[num2str(-1/f.b)],[num2str(goodness.rsquare)]}; handles.text.Position(1:2) = [handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.7), handles.axes.YLim(2)*0.8];
        elseif data.cumulative_mode == 1 
            n = length(data.hist_data);
            x = sort(data.hist_data)-data.Trunc;
            p = ((1:n)-0.5)' ./ n;
            y = -log(1 - p);
            [muHat,muHat_int] = regress(x,y);
            err = abs(diff(muHat_int))/2;
            goodness.rsquare = 1 - sum((y - x/muHat).^2)/sum((y-mean(y)).^2);          
            handles.cum.XData = x+data.Trunc; handles.cum.YData = p;
            handles.fit.XData = x+data.Trunc; handles.fit.YData = expcdf(x,muHat);
            handles.text.String = {[num2disp(muHat,err)],[num2str(goodness.rsquare)]}; handles.text.Position(1:2) = [handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.7), handles.axes.YLim(2)*0.8];
            data.muHat = muHat; data.err = err;
        end            
    case 4
        handles.fit.Visible = 'on';% handles.offset.Value = 0; data.offset = 0;
        data.BinEdges = linspace(data.offset,max(data.hist_data),handles.hist.NumBins); % min(data.hist_data) instead of data.offset
        %data.BinEdges = [0.4359    2.5277    4.6194    6.7112    8.8029   10.8947   12.9865   15.0782   17.1700];
        handles.hist.BinEdges = data.BinEdges;
        d = diff(data.BinEdges)/2;
        BinCenters = data.BinEdges(1:end-1) + d; BinCenters = BinCenters(:);
        Values = handles.hist.Values(:);
        exp2_fit = fittype(@(A,b,x) A*b^2*x.*exp(-b*x));
        start = [sum(Values) 1];
        [f,goodness] = fit(BinCenters,Values,exp2_fit,'Start',start);
        handles.fit.YData = feval(f,handles.fit.XData);
        handles.text.String = {[num2str(f.b)],[num2str(goodness.rsquare)]}; handles.text.Position(1:2) = [handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.7), handles.axes.YLim(2)*0.8];
        handles.axes.YLim = [0 max(Values)*1.2];
    case 5
        handles.fit.Visible = 'on';
        handles.hist.BinEdges = data.BinEdges;
        d = diff(data.BinEdges)/2;
        BinCenters = data.BinEdges(1:end-1) + d; BinCenters = BinCenters(:);
        kin2_fit = fittype(@(A,x) A*(81.4*exp(-((x-16.4)/9).^2)+14.4*exp(-((x-10.5)/9).^2)+2.9*exp(-((x-16.29)/9).^2)+1.1*exp(-((x-18.09)/9).^2)));
        Values = handles.hist.Values(:);
        cc = sum(Values);%, 3.3];% 16.4, 10.5, 16.29, 18.09,
        figure 
        [f,goodness] = fit(BinCenters,Values,kin2_fit,'Start',cc);
        handles.fit.YData = feval(f,handles.fit.XData);
        handles.text.String = {num2str(f.A),num2str(goodness.rsquare)}; handles.text.Position(1:2) = [handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.7), handles.axes.YLim(2)*0.8];
        handles.axes.YLim = [0 max(Values)*1.2];
    case 6
        handles.fit.Visible = 'on';
        d = diff(data.BinEdges)/2;
        BinCenters = data.BinEdges(1:end-1) + d;
        Values = handles.hist.Values;
        [f,goodness] = fit(BinCenters(:),Values(:),'gauss2');
        handles.fit.YData = feval(f,handles.fit.XData);
        handles.text.String = {[num2str(f.b1),'  ',num2str(f.c1)],[num2str(f.b2),'  ',num2str(f.c2)],[num2str(goodness.rsquare),'  ',num2str(sum(Values))]}; handles.text.Position(1:2) = [handles.axes.XLim(1)+(diff(handles.axes.XLim)*0.05), handles.axes.YLim(2)*0.95];
    otherwise
        disp('error in the popup menu') 
end
drawnow
guidata(handles.fig,data)
end

function setfit(hObject,~,handles)
    do_fit(hObject,handles)
end

function data = deactivate_offset(handles,data)
switch handles.setfit
    case {1,2,3}
        
    case {4}
        data.offset = 0;
end
end

function data = update_parameters(hObject,~,handles,mode)
data = guidata(hObject.Parent);
if mode > 1
    data.cumulative_mode = hObject.Value;
else
    data.cumulative_mode = mode;
    hObject.Value = mode;
end



if data.cumulative_mode == 1
    handles.hist.Visible = 'off';
    handles.cum.Visible = 'on';
    handles.axes.YLim = [0 1.1];
elseif data.cumulative_mode == 0
    handles.hist.Visible = 'on';
    handles.cum.Visible = 'off';
    handles.axes.YLimMode = 'auto';
end

guidata(hObject.Parent,data)
if mode == 2
    do_fit(data.handles.setfit,handles)
end
end

