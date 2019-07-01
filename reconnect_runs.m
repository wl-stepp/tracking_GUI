function data = reconnect_runs(handles)
data = guidata(handles.figures.main);
runs = data.values.runs;
max_time_leap = 2;
max_distance = 10;
connected_ID = 0;
runs_connected = cell(size(runs,1),1);
run_IDs = [];
connected_store = [];


run_connected_status = 0;

has_been_connected = 0;
%loop for every run to be checked
for run_number = 1:size(runs,1)
    set(data.handles.gui.displays.dot_number,'String',sprintf('run %d of %d',run_number,size(runs,1)))
    drawnow
    
    run_connected_status = 0;
    end_pos = runs{run_number}(2:3,end);
    end_frame = runs{run_number}(7,end);

    for k = 1:size(runs,1)
        start_pos = runs{k}(2:3,1);
        start_frame = runs{k}(7,1);
        
        distance = sqrt(sum((end_pos - start_pos).^2));
        time_leap = start_frame - end_frame;
        
        if distance < max_distance && time_leap <= max_time_leap && time_leap > 1 && run_number ~= k
            % interrupted run identified check if run has already been
            % connected to another run
            
            %differenciate if this run has been connected 
            if has_been_connected == 0
                % run has not been connected
                if run_connected_status == 1 && distance < run_IDs(7,end)
                    % replace run with closer run
                    corrected_run = corr_run(runs,k,run_number,time_leap);
                    runs_connected{connected_ID} = [runs{run_number} corrected_run];
                    run_IDs = [run_IDs(:,1:end-1) [connected_ID; runs{run_number}(4,1);runs{k}(4,1);run_number;k;time_leap;distance]];
                    % Second store for keeping track of longer runs
                    connected_store = [connected_store(:,1:end-1) [connected_ID; run_number; k;zeros(size(connected_store,1)-3,1)]];
                elseif run_connected_status == 1 && distance >= run_IDs(7,end)
                    % do nothing just skip here
                elseif run_connected_status == 0
                    connected_ID = connected_ID + 1;
                    % calculate run to be connected in comparison to first part
                    corrected_run = corr_run(runs,k,run_number,time_leap);
                    %combine runs in new cell structure
                    runs_connected{connected_ID} = [runs{run_number} corrected_run];
                    % store information to runs that have been connected
                    run_IDs = [run_IDs [connected_ID; runs{run_number}(4,1);runs{k}(4,1);run_number;k;time_leap;distance]];
                    % Second store for keeping track of longer runs
                    connected_store = [connected_store [connected_ID; run_number; k; zeros(size(connected_store,1)-3,1)]];
                    run_connected_status = 1;
                end
            else
               % run has been connected add runs after the connected run
               % find connected_ID for this run
                
               [~,conn_ID] = find(connected_store(2:end,:) == run_number,1,'last');
               
                   
                if run_connected_status == 1 && distance < run_IDs(7,end)
                    % replace run with closer run
                    corrected_run = corr_run(runs,k,run_number,time_leap);
                    runs_connected{conn_ID} = [runs_connected{conn_ID} corrected_run];
                    run_IDs = [run_IDs(:,1:end-1) [conn_ID; runs{run_number}(4,1);runs{k}(4,1);run_number;k;time_leap;distance]];
                    connected_store(end,conn_ID) = k;
                elseif run_connected_status == 1 && distance >= run_IDs(7,end)
                    % do nothing just skip here
                elseif run_connected_status == 0
                    % calculate run to be connected in comparison to first part
                    corrected_run = corr_run(runs,k,run_number,time_leap);
                    %combine runs in new cell structure
                    runs_connected{connected_ID} = [runs_connected{conn_ID} corrected_run];
                    % store information to runs that have been connected
                    run_IDs = [run_IDs [connected_ID; runs{run_number}(4,1);runs{k}(4,1);run_number;k;time_leap;distance]];
                    connected_store(end+1,conn_ID) = k;
                    run_connected_status = 1;
                end
            end
             
        end
    end
    
        %check if next run is already in connected runs
    has_been_connected = 1;
    if isempty(run_IDs)
        has_been_connected = 0;
    else
        if isempty(find(run_IDs(5,:) == run_number+1,1))
            has_been_connected = 0;
        end
    end
    
end

%reorder all the runs in a new cell structure
cell_count = 1;
runs_new = cell(1,1);
for run_number = 1:size(runs,1)
    %Check if run is in one of the connected runs
    if isempty(find(run_IDs(3:4,:) == run_number,1))
        runs_new{cell_count} = runs{run_number};
        cell_count = cell_count + 1;
    else
        %skip here and do nothing
    end
end

%connect the filtered runs with the connected runs
runs_new = [runs_new'; runs_connected];
runs_new(all(cellfun(@isempty,runs_new),2),:) = [];

data.values.runs = runs_new;
guidata(handles.figures.main,data);
set(data.handles.gui.displays.dot_number,'String',num2str(size(runs_new,1)))
drawnow
pause(0.5)
set(data.handles.gui.displays.dot_number,'String','done')

end


% figure
% hold on
% for i = 1:size(runs_new,1); scatter(runs_connected{i}(3,:),runs_connected{i}(2,:));set(gca,'YDir','reverse');end


function corrected_run = corr_run(runs,k,run_number,time_leap)

    corrected_run = runs{k}; corrected_run(6,:) = sqrt(sum(bsxfun(@minus,corrected_run(2:3,:),runs{run_number}(2:3,1))).^2); %out = bsxfun(@minus,WIN,best);
    % interpolate to avoid jumps in data
    corrected_run = [zeros(size(corrected_run,1),time_leap-1) corrected_run];
    % distance data interpolation
    corrected_run(6,1:time_leap-1) = interp1([0 time_leap],[runs{run_number}(6,end) corrected_run(6,time_leap)],1:time_leap-1);
    corrected_run(2,1:time_leap-1) = interp1([0 time_leap],[runs{run_number}(2,end) corrected_run(2,time_leap)],1:time_leap-1);
    corrected_run(3,1:time_leap-1) = interp1([0 time_leap],[runs{run_number}(3,end) corrected_run(3,time_leap)],1:time_leap-1);
    corrected_run(4,1:time_leap-1) = ones(1,time_leap-1)*corrected_run(4,end);
    % frame data interpolation
    corrected_run(7,:) = runs{run_number}(7,end)+1:runs{run_number}(7,end)+length(corrected_run(7,:));
end


