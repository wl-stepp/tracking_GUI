function data = distance_calc_v2(handles)
% function for calculating the distance traces for the pic2pic approach
% This function should maybe adjusted at some point to account for bent
% curves

data = guidata(handles.figures.main);
min_run_distance = 1; %�m only for none_FIONA mode
runs = data.values.runs;
data.values.runs_analyzed = zeros(length(runs),5);

for run = 1:size(runs,1)
    for frame = 2:size(runs{run},2)
        runs{run}(6,frame) = sqrt((runs{run}(2,frame)-runs{run}(2,1))^2+(runs{run}(3,frame)-runs{run}(3,1))^2);
    end
    data.values.runs_analyzed(run,1:3) = [runs{run}(7,1) runs{run}(7,end) max(runs{run}(6,:))];
    data.values.runs_analyzed(run,6:9) = [round(runs{run}(2,1)) round(runs{run}(3,1)) round(runs{run}(2,end)) round(runs{run}(3,end))];
    % check if run is long enough for speed calculation, but only if FIONA
    % mode is not activated
    if max(runs{run}(6,:)) < min_run_distance/data.values.meta_data.PixelConversion && data.values.FIONA_mode == 0 && data.values.Diffusion_mode == 0
        runs{run} = [];
    else
        %do not delete short runs
    end
end
data.values.runs_analyzed(all(cellfun(@isempty,runs),2), : ) = [];
runs(all(cellfun(@isempty,runs),2), : ) = [];


data.values.run_plot = 1;
data.values.runs = runs;
guidata(handles.figures.main,data)
set(data.handles.gui.displays.dot_number,'String','done')
end