function data = speed_calc_v2(handles)
% FUNCTION that calculates the speeds for the different distance traces
% obtained from the distance.calc function
data = guidata(handles.figures.main);
data.values.meta_data.CycleTime = str2num(data.handles.gui.input.info.cycletime.String);
data.handles.tabs.main.SelectedTab = data.handles.tabs.info;

fitting_window = 6; %former 10 030116 %former 5 251215, 5 010616
min_frames_run = 6; % former 3 190116, 8 010616
speed_min = 0.1; %�m/s %former 0.1 131016  0.05 251215
speed_min = speed_min/data.values.meta_data.PixelConversion*data.values.meta_data.CycleTime; %pixel/frame
overall_speed_min = speed_min/2; %µm/s
overall_speed_min = overall_speed_min/data.values.meta_data.PixelConversion*data.values.meta_data.CycleTime; %pixel/frame
speed_max = 10;
speed_max = speed_max/data.values.meta_data.PixelConversion*data.values.meta_data.CycleTime;
min_fit_quality = 0.95; %former 0.97 160210 %former 0.95 030116
window_offset = round(fitting_window/2)-1;
run_number = size(data.values.runs,1);
do_plot = 0;

if do_plot == 1
    figure
end

    xfit_all = [];yfit_all = [];
% Loop for the fitting of each point
for run = 1:run_number

    
    % prealocation
    data.values.runs{run}(8,1) = 0; % for marking if speed was measured
    distance = data.values.runs{run}(6,:);
    frame = data.values.runs{run}(7,:);
    measure_y = zeros(length(frame),1);
    measure_x = zeros(length(frame),1);
    
    overall_speed = data.values.runs{run}(6,end)/length(data.values.runs{run}(6,:));
    
    
    
    
    % plotting performance
    set(data.handles.gui.displays.dot_number,'String',sprintf('run %d of %d',run,run_number))
    drawnow

    i = round(fitting_window/2);
    marker = 0;
    while i <= size(distance,2)-window_offset
        x = frame(i-window_offset:i+window_offset);
        y = distance(i-window_offset:i+window_offset);
        % do the fit
        p = polyfit(x,y,1);
        yfit = polyval(p,x);
        %calculate the quality of the fit
        yresid = y - yfit;
        SSresid = sum(yresid.^2); SStotal = (length(y)-1) * var(y);
        rsq = 1 - SSresid/SStotal;
        % mark the points that fulfill the given criteria
        if p(1) > speed_min && rsq > min_fit_quality && p(1) < speed_max && overall_speed > overall_speed_min
            %check if a run was already initiated
            if marker == 0
                measure_y(i-window_offset:i+window_offset) = y;
                measure_x(i-window_offset:i+window_offset) = x;
                % commented on 160804 because this might exclude short runs
                %measure_y(i-1:i+1) = y(window_offset:window_offset+2);
                %measure_x(i-1:i+1) = x(window_offset:window_offset+2);
                i = i + 1;
                marker = 1;
            else
                measure_y(i+window_offset) = y(end);
                measure_x(i+window_offset) = x(end);
                % commented on 160804 might not have been adjustable for
                % different fitting window sizes
                %measure_y(i+1) = y(end);
                %measure_x(i+1) = x(end);
                i = i + 1;
            end
        else
            i = i + 1;
            marker = 0;
        end    

        if do_plot == 1
            plot(frame,distance)
            hold on
            plot(x,yfit,'LineWidth',7)
            scatter(frame,measure_y,'r.','SizeData',100)
            hold off
            %drawnow
        end
    end

    % test for jump in time due to reconnect_runs
%     test_measure = measure_x(measure_x > 0);
%     while max(diff(test_measure)) == 2
%         max_diff = max(diff(test_measure));
%         diff_pos = find(diff(measure_x) == max_diff);
%     % correct for jump in time also in y data
%         measure_y = [measure_y(1:diff_pos-1);...
%             interp1([measure_x(diff_pos) measure_x(diff_pos+1)],[measure_y(diff_pos) measure_y(diff_pos+1)],measure_x(diff_pos):measure_x(diff_pos+1))';...
%             measure_y(diff_pos+2:end)];
%         measure_x = [measure_x(1:diff_pos-1); [measure_x(diff_pos):measure_x(diff_pos+1)]'; measure_x(diff_pos+2:end)];
%         test_measure = measure_x(measure_x > 0);
%     end

% Loop for choosing the points that fitted well and calculate the speed
    x_old = measure_x(1);
    j = 1;
    speeds = []; quality = [];
    yfit = []; xfit = []; fit_parameter = [];
    
    for x = 1:length(measure_x)
        
        if measure_x(x) > 0
            x_end = measure_x(x);
            
            %check if at end of run so elongation is aborted
            if x == length(measure_x)
                abort = 1;
            elseif measure_x(x+1) == 0
                abort = 1;
            else
                abort = 0;
            end
            
            if x_end >= x_old + min_frames_run-1 && abort == 1
                %x_fit = measure_x(x_old:x_end)';%x_old:x_end;
                x_fit = measure_x(find(measure_x == x_old,1,'first'):find(measure_x == x_end,1,'first'))';
                y_fit = measure_y(find(measure_x == x_old,1,'first'):find(measure_x == x_end,1,'first'))';
                
%                 if max(diff(x_fit)) > 1
%                     pause(0.3)
%                 end
                FIT = polyfitn(x_fit,y_fit,1);
                fit_parameter(j,:) = FIT.Coefficients;
                yfit = [yfit polyval(fit_parameter(j,:),x_fit)];
                xfit = [xfit x_fit];
                quality(j) = FIT.R2;
                speeds(j) = fit_parameter(j,1);
                data.values.runs{run}(8,1) = 1; % mark run that speed was measured succesfully
                j = j + 1;
            end
        elseif measure_x(x) == 0 && x == length(measure_x)
            %do nothing
        else
            x_old = measure_x(x+1);
        end
    end
    
    if do_plot == 1
        hold on
        scatter(xfit,yfit)
        hold off
        drawnow
        pause(0.3)
    end
    speed_hist(run) = mean(speeds);
    data.values.runs_analyzed(run,4:5) = [mean(speeds) mean(quality)];
    xfit_all{run} = xfit;
    yfit_all{run} = yfit;
end    

% OLD plotting set(data.handles.plots.tracking_pos,'XData',xfit_all,'YData',yfit_all);

data.values.speed.xfit = xfit_all;
data.values.speed.yfit = yfit_all;
data.values.speed.parameters = fit_parameter;
data.values.speed.speed_hist = speed_hist*data.values.meta_data.PixelConversion/data.values.meta_data.CycleTime*1000;
guidata(handles.figures.main,data);
set(data.handles.plots.speed_calculation,'XData',xfit_all{data.values.run_plot},'YData',yfit_all{data.values.run_plot})
axes(data.handles.axes.histogram)
histogram(data.values.speed.speed_hist,'FaceColor','white')
set(data.handles.gui.displays.dot_number,'String','done')
end

