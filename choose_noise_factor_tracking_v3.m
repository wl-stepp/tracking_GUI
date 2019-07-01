function data  = choose_noise_factor_tracking_v3(~,~,~,dotsize,mode,handles)
% routine to choose dots in an image that match the specified noisefactors
% v3 is trying to add parfor loop to do all images simultaneously

% mode 0 for one image calculation only
% mode 1 for batch analysis of all images
% mode 2 is for parallel computing algorithm

%settings
data = guidata(handles.figures.main);
pixel_offset = (data.values.dotsize-1)/2;
noisefactor = data.values.noisefactor; noisefactor_max = data.values.noisefactor_max;
subpix_pos = 1;
distance_min = data.values.dotsize;
subpix_gauss = data.values.FIONA_mode; 
if subpix_gauss == 1; do_surrounding_test = 0;else; do_surrounding_test = 1;end % distance_min = 0; %0 and 1 for normal usage
data.values.subpix_gauss = subpix_gauss;
dotsize = data.values.dotsize;
num_images = data.values.num_images;


% check wether one frame_n (mode == 0) or whole series mode is active
if mode == 0
    loop_start = data.values.frame;
    loop_end = loop_start;
    subpix_gauss = 0;  
    n_workers = 0;
elseif mode == 1
    loop_start = 1;
    loop_end = data.values.num_images;
    n_workers = 0;
elseif mode == 2
    loop_start = 1;
    loop_end = data.values.num_images;
    n_workers = Inf;
    if isempty(gcp)
        parpool
    end
end

ppm = 0;
peakvalues = cell(data.values.num_images,1);
bad_points = cell(data.values.num_images,1);
peaknumbers_all = zeros(1,data.values.num_images);
%gauss_fit = zeros(1,data.values.num_images);
gauss_fit = cell(1,data.values.num_images);
subpixel_failed = zeros(1,data.values.num_images);
bad_counter = 1;


dot_number_display = data.handles.gui.displays.dot_number;
    
% routine for detecting the maxima in the data
stack = uint16(data.values.stack);


% start stuff for parallel computing
if mode == 2
    % disable java event listeners
    switch_listeners(data.handles,0); % only used for real parfor

    % construct listener for progress bar
    ppm = ParforProgMon('dots progress ', loop_end-loop_start);
    clear data
    set(dot_number_display,'String','...'); drawnow;
end

tic
parfor (frame_n = loop_start:loop_end,n_workers)
    if mode ~= 2
        set(dot_number_display,'String',sprintf('frame %d of %d',frame_n,num_images)); drawnow;
    end
    % reinitialize frame_n data
    peakvalues{frame_n} = zeros(9,1);
%     bad_points{frame_n} = zeros(2,1);
    prox_matrix = [];
%     bad_prox_matrix = [];
    
    pic = stack(:,:,frame_n);
    if size(pic,3) > 1
        pic = sum(pic,3);
    end
    %pic = double(pic);
    mom_max = max(pic(:));
    noise = mean(pic(:));
    
    i = 1;
    bad_counter = 1;
    while mom_max > noise*noisefactor %&& mom_max < noise*data.values.noisefactor_max
    [mom_max_x,mom_max_y] = find(pic == mom_max,1,'first');

        % look for points that are no maxima in their surrounding
        if do_surrounding_test == 1
            if size(pic,1) - pixel_offset - 2 > mom_max_x && mom_max_x > pixel_offset + 2 ...
                    && size(pic,2) - pixel_offset - 2 > mom_max_y && mom_max_y > pixel_offset + 2   
                mom_max_integrated = sum(sum(pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset)));
                mom_max_surrounding = sum(sum(pic(mom_max_x-pixel_offset-2:mom_max_x+pixel_offset+2,mom_max_y-pixel_offset-2:mom_max_y+pixel_offset+2)))-mom_max_integrated;
                factor_surrounding = (mom_max_integrated/dotsize^2)/(mom_max_surrounding/((dotsize+4)^2-dotsize^2));
            else
                factor_surrounding = 100;
            end
        else
            factor_surrounding = 100;
        end

    % precalculations for looking for points too close to each other
        prox_matrix(1,1:size(peakvalues{frame_n},2)) = ones(1,size(peakvalues{frame_n},2))*mom_max_x;
        prox_matrix(2,1:size(peakvalues{frame_n},2)) = ones(1,size(peakvalues{frame_n},2))*mom_max_y;
        proximity = peakvalues{frame_n}(2:3,:) - prox_matrix;
        proximity = sqrt(proximity(1,:).^2+proximity(2,:).^2);
        %proximity = sum(abs(proximity),1); this is no real distance,
        %right? commented 16084
    % look for points that are to close to really bright points
%         if mom_max > noise*noisefactor_max*1.5
%             bad_prox_matrix(1,1:size(bad_points{frame_n},2)) = ones(1,size(bad_points{frame_n},2))*mom_max_x;
%             bad_prox_matrix(2,1:size(bad_points{frame_n},2)) = ones(1,size(bad_points{frame_n},2))*mom_max_y;
%             bad_proximity = bad_points{frame_n}(1:2,:) - bad_prox_matrix;
%             bad_proximity = sqrt(bad_proximity(1,:).^2+bad_proximity(2,:).^2);
%         else
%             bad_proximity = 1000;
%         end
     
    % looking for points too close to the boarder & each other % here was
    % +- 2 for the sourrounding test, testing if this was necessary
    %%% Size(+pic,x) interchanged for testing
    if subpix_gauss == 1 
        pixel_offset_mode = 0;
    else
        pixel_offset_mode = 2;
    end
    
    
    
    % check for all requirements of a valid peak
    if size(pic,1) - pixel_offset - pixel_offset_mode > mom_max_x && mom_max_x > pixel_offset + pixel_offset_mode ...
            && size(pic,2) - pixel_offset - pixel_offset_mode > mom_max_y && mom_max_y > pixel_offset + pixel_offset_mode ...
            && mom_max < noise*noisefactor_max...
            && min(proximity) > distance_min...
            && factor_surrounding > ((noisefactor-1)*0.1+1)
            %&& min(bad_proximity) > 4*distance_min...
            
        
       mom_max_integrated = sum(sum(pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset)));

       %%%%%% DO SUBPIXEL positioning of the peak
       %%%X,Y shifted?
       if subpix_pos == 1
           if subpix_gauss == 1
               subpic = pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset);
               [cc,rsquared] = gaussian_fit_2D(subpic);
               gauss_fit{frame_n}(i) = rsquared;
               new_max_x = cc(5); new_max_y = cc(3);
               if isnan(new_max_x) || isnan(new_max_y)
                         subpixel_failed(frame_n) = 1;
               end
               new_max_y = mom_max_y + (new_max_y - (dotsize+1)/2);
               new_max_x = mom_max_x + (new_max_x - (dotsize+1)/2);
           else
                subpic = pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset);
                [new_max_y, new_max_x] = radialcenter(subpic);
                if isnan(new_max_x) || isnan(new_max_y)
                         subpixel_failed(frame_n) = 1;
                end
                  % I think there might still be some bigger problems here...
                  % It's actually not so easy to find the position of the
                  % maximum in noisy data
                  % used the radialcenter solution from
                  % http://physics-server.uoregon.edu/~raghu/Particle_tracking_files/radialcenter.m
                new_max_y = mom_max_y + (new_max_y - (dotsize+1)/2);
                new_max_x = mom_max_x + (new_max_x - (dotsize+1)/2);
           end

       else
           new_max_x = mom_max_x;
           new_max_y = mom_max_y;
       end
       
       if subpixel_failed(frame_n) == 1
           new_max_x = mom_max_x;
           new_max_y = mom_max_y;
           subpixel_failed(frame_n) = 0;
       end
       
        %%% END SUBPIXEL positioning of the peak
        
        
        
        %delete maximum from picture and store data

        pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset) = zeros(dotsize,dotsize);
        peakvalues{frame_n}(1,i) = mom_max_integrated/noise/dotsize^2;
        peakvalues{frame_n}(2,i) = new_max_x;
        peakvalues{frame_n}(3,i) = new_max_y;
        peakvalues{frame_n}(4,i) = 0; % for later sorting of the peaks
        peakvalues{frame_n}(5,i) = 0; % for later storing of the proximities
     % added 170419 for storage of intensities
        peakvalues{frame_n}(6,i) = 0; % for later storing of the proximities
        peakvalues{frame_n}(7,i) = 0; % for later storing of the proximities
        peakvalues{frame_n}(8,i) = mom_max_integrated; % added to the end
        if subpix_gauss == 1
            peakvalues{frame_n}(9,i) = mean([cc(4),cc(6)]); % width of the distribution
        else
            peakvalues{frame_n}(9,i) = 0;
        end
     %
        i = i + 1;
    elseif size(pic,2) - pixel_offset <= mom_max_x || mom_max_x <= pixel_offset...
            || size(pic,1) - pixel_offset <= mom_max_y || mom_max_y <= pixel_offset
        pic(mom_max_x,mom_max_y) = noise;
    else
        pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset) = ones(dotsize,dotsize)*noise;
    end
    % remember very bad points
%     if mom_max > noise*noisefactor_max*1.4
%         bad_points{frame_n}(1,bad_counter) = mom_max_x;
%         bad_points{frame_n}(2,bad_counter) = mom_max_y;
%         bad_counter = bad_counter + 1;
%     end
    mom_max = max(pic(:));
    end
    peaknumbers_all(frame_n) = size(peakvalues{frame_n},2);
    
    %increment progress bar
    if mode == 2
        ppm.increment();
    end
end
disp('dots')
toc
data = guidata(handles.figures.main);

if mode == 2
    %reenable java listeners
    data.handles.gui.scroll = switch_listeners(data.handles,1);
end

data.values.gauss_fit = gauss_fit;
data.values.peaknumber = size(peakvalues{data.values.frame},2);
if mode == 0
    if isfield(data.values,'peakvalues_all')
        data.values.peakvalues_all{data.values.frame} = peakvalues{data.values.frame};
        data.values.peakvalues = peakvalues{data.values.frame};
        data.values.peaknumbers_all(data.values.frame) = peaknumbers_all(data.values.frame);
    else
        data.values.peakvalues = peakvalues{data.values.frame};
        data.values.peaknumbers_all = peaknumbers_all;
    end
elseif mode == 1 || mode == 2
    data.values.peakvalues_all = peakvalues;
    data.values.peaknumbers_all = peaknumbers_all;
end


if mode == 2
    ppm.delete();
end

if isfield(data.values,'peak_ID_max');  data.values = rmfield(data.values,'peak_ID_max'); end
set(data.handles.gui.displays.dot_number,'String','done')

end


