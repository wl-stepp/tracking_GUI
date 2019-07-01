function data = pic_by_pic(handles)
% function for tracking dots on a image series by an pic to pic approach
% TEST Message for git
% Test Message #2 for git

tic
if ~nargin
    handles.figures.main = gcf();
end

data = guidata(handles.figures.main);
peakvalues_all = data.values.peakvalues_all;

peaknumbers_all = data.values.peaknumbers_all;
distance_max = 2*data.values.dotsize; %160206 was 2*
min_run_length = 5; %frames

if data.values.parallel_computing_mode == 1
    n_workers = Inf;
    if isempty(gcp)
        parpool
    end
    parallel_computing = 1;
else
    n_workers = 0;
    parallel_computing = 0;
end



% number the peaks of the first pic
peakvalues_all{1}(4,:) = 1:size(peakvalues_all{1},2);
% set peak_ID to start after first frame numbers
peak_ID = size(peakvalues_all{1},2)+1;

% calculate the distances for all points from picture to picture
for frame = 1:data.values.num_images-1
    set(data.handles.gui.displays.dot_number,'String',sprintf('1/3: %d/%d',frame,data.values.num_images)); drawnow;
    distances = zeros(1,peaknumbers_all(frame));
    proximity = zeros(2,peaknumbers_all(frame+1));


    for i = 1:peaknumbers_all(frame+1) % changed this to adjust the size

            if frame == 1
                peakvalues_all{1}(6,i) = 0; %added 160714
                peakvalues_all{1}(7,i) = 1; %added 160714    
            end
            peakvalues_all{frame+1}(6,i) = 0; %added 160714
            peakvalues_all{frame+1}(7,i) = frame+1; % added 160714 added +1 160804

            for k = 1:peaknumbers_all(frame)
                distances(k) = sqrt((peakvalues_all{frame+1}(2,i)-peakvalues_all{frame}(2,k))^2+(peakvalues_all{frame+1}(3,i)-peakvalues_all{frame}(3,k))^2);
            end

            proximity(1,i) = min(distances);
            proximity(2,i) = find(distances == min(distances),1,'first');

            % check for dot being close enough and if a closer dot already
            % exists

            pos = find(peakvalues_all{frame+1}(4,:) == peakvalues_all{frame}(4,proximity(2,i)),1,'first');
            if proximity(1,i) <= distance_max && isempty(find(peakvalues_all{frame+1}(4,:) == peakvalues_all{frame}(4,proximity(2,i)),1))
                peakvalues_all{frame+1}(4,i) = peakvalues_all{frame}(4,proximity(2,i));
                peakvalues_all{frame+1}(5,i) = proximity(1,i);
            elseif ~isempty(find(peakvalues_all{frame+1}(4,:) == peakvalues_all{frame}(4,proximity(2,i)),1)) && proximity(1,i) < peakvalues_all{frame+1}(5,pos)
                peak_ID = peak_ID + 1;
                peakvalues_all{frame+1}(4,i) = peakvalues_all{frame}(4,proximity(2,i));
                peakvalues_all{frame+1}(4,pos) = peak_ID; % changed pos and 4           
            else
                peak_ID = peak_ID + 1;
                peakvalues_all{frame+1}(4,i) = peak_ID;

            end
    end
end
data.values.peak_ID_max = peak_ID;

%added 160809
data.values.peakvalues_all = peakvalues_all;
% adjust the cells to fit for cell2mat
max_peaknumber = max(peaknumbers_all);
peakvalues_mat = peakvalues_all;


% this loop is very fast (0.003s on my Mac)
for frame = 1:data.values.num_images
    peakvalues_mat{frame} = [peakvalues_mat{frame} zeros(9,max_peaknumber - size(peakvalues_mat{frame},2))];
end


%preparation for parallel loop
dotnumber_handle = data.handles.gui.displays.dot_number;
peak_ID_max = data.values.peak_ID_max;
num_images = data.values.num_images;
runs = cell(data.values.peak_ID_max,1);
peakvalues_for_loop = peakvalues_all;

% Trying to find peakvalues that do not appear often enough to filter early
% for performance

% Try to get all this huge data into one matrix
peakvalues_mat = cell2mat(peakvalues_mat);

%parfor_progress(peak_ID_max)
%construct a cell structure containing all the dots sorted by peak_ID
if parallel_computing == 1
    ppm = ParforProgMon('pbp progress ', peak_ID_max);
    set(dotnumber_handle,'String','...'); drawnow;
else
    ppm = [];
end
parfor (peak_ID = 1:peak_ID_max,n_workers)
    % this line takes about 10% of the time
    if mod(peak_ID,100) == 0 && parallel_computing ~= 1
        set(dotnumber_handle,'String',sprintf('2/3: %d/%d',peak_ID,peak_ID_max)); drawnow;
    end
    %parfor_progress;
    
    % Getting the values from the matrix calculated before
    indexes = find(peakvalues_mat(4:9:end,:) == peak_ID);
    indexes = indexes*9;
    [frame,peak] = ind2sub(size(peakvalues_mat),indexes);
    [frame_sort,sortIndex] = sort(frame); peak_sort = peak(sortIndex);
    frame_positions = [frame_sort-8,frame_sort-7,frame_sort-6,frame_sort-5,frame_sort-4,frame_sort-3,frame_sort-2,frame_sort-1,frame_sort]';
    peak_sort = [peak_sort,peak_sort,peak_sort,peak_sort,peak_sort,peak_sort,peak_sort,peak_sort,peak_sort]';
    indexes = sub2ind(size(peakvalues_mat),frame_positions,peak_sort);
    runs{peak_ID} = reshape(peakvalues_mat(indexes),size(frame_positions));
    
    
    
    %indexed search approach commented 160729
%     indexes = cellfun(@(x) find(x(4,:) == peak_ID),peakvalues_all,'UniformOutput',false);
%     for frame = 1:num_images
%         runs{peak_ID} = [runs{peak_ID} peakvalues_for_loop{frame}(1:7,indexes{frame})];
%     end
    
    
    
    %commented 160714
%     for frame = 1:num_images        
%         for peak = 1:peaknumbers_all(frame)
%             if peakvalues_for_loop{frame}(4,peak) == peak_ID
%                 runs{peak_ID} = [runs{peak_ID} [peakvalues_for_loop{frame}(1:5,peak);0;frame]];
%             end
%         end
%     end

if parallel_computing == 1
    ppm.increment
end


end
%parfor_progress(0)
%runs_new{10} == runs{10}   %check if new approach matches the old one

set(data.handles.gui.displays.dot_number,'String','3/3'); drawnow;
% loop for sorting out runs that are too short
for peak_ID = 1:data.values.peak_ID_max    
    if size(runs{peak_ID},2) < min_run_length
        runs{peak_ID} = [];
    end
end

runs(all(cellfun(@isempty,runs),2), : ) = [];
set(data.handles.gui.displays.dot_number,'String',num2str(data.values.peaknumber)); drawnow;        
% plot_runs = cat(2,runs{:});
% axes(data.handles.axes.main)
% colormap = lines(data.values.peak_ID_max);
% hold on
% scatter(plot_runs(3,:),plot_runs(2,:),'CData',colormap(plot_runs(4,:),:))
% hold off

data.values.runs = runs;
data.values.peakvalues_all_plot = peakvalues_all; %commented 160729
guidata(handles.figures.main,data)
if parallel_computing == 1 
    ppm.delete
end
disp('pic_by_pic')
toc
end

% plot([peakvalues1(3,i) peakvalues2(3,k)],[peakvalues1(2,i) peakvalues2(2,k)],'r','LineWidth',3)