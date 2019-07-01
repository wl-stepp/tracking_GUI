function [analysis,pic_orig] = imageanalysis_tracking(handles)
%analysis procedure for the image of single dots on images

% settings for the procedure
% dotsize must be odd

data = guidata(handles.figures.main);
pixel_offset = (data.values.dotsize-1)/2;
frame = 1;

% read in data from files
pic = imread(data.values.img_path,frame);
pic_orig = pic;

if size(pic,3) > 1
    pic = sum(pic,3);
end

% routine for detecting the maxima in the data


%draw evaluated points
%hold on
%scatter(peakvalues(3,:),peakvalues(2,:))
%Label the points
%for m = 1:size(peakvalues,2)
%    text(peakvalues(3,m),peakvalues(2,m),num2str(m),'Color','white')
%end
%hold off


%                 tif.close
% ___ new for the evaluation of bleaching videos ___ %
 % data for the straight line test
fitting_window = 5;
window_offset = round(fitting_window/2)-1;

 % other data to be set
first_pic = imread(data.values.img_path,1);
peakvalues = data.values.peakvalues;
old_peak = zeros(size(peakvalues));
old_max = zeros(1,size(peakvalues,2));
peakvalues_original = peakvalues;
info = imfinfo(data.values.img_path);
num_images = numel(info);
data.values.bleaching_data = zeros(data.values.num_images,size(data.values.peakvalues,2));
tracking = zeros(2,size(data.values.peakvalues,2),data.values.num_images);
noise_first_pic = mean(first_pic(:));
peak_area = ones(data.values.dotsize,data.values.dotsize);
pixel_offset = (data.values.dotsize-1)/2;
dotsize = data.values.dotsize;

for k = 2:num_images
    %check for break condition
    if strcmp(get(data.handles.gui.buttons.cancel,'Enable'),'off') == 1
        set(data.handles.gui.buttons.cancel,'Enable','on')
        break
    end
    set(data.handles.gui.displays.dot_number,'String',sprintf('frame %d of %d',k,num_images))
    drawnow
    pic = imread(data.values.img_path,k);
    if size(pic,3) > 1
        pic = sum(pic,3);
    end
    noise = mean(pic(:));
    for l = 1:data.values.peaknumber
        if size(pic,2) - pixel_offset - 2 > peakvalues(2,l) && peakvalues(2,l) > pixel_offset+2 && size(pic,1) - pixel_offset -2 > peakvalues(3,l) && peakvalues(3,l) > 2+ pixel_offset
            % choose subpic to do positioning on
            subpic = pic(peakvalues(2,l)-pixel_offset:peakvalues(2,l)+pixel_offset,peakvalues(3,l)-pixel_offset:peakvalues(3,l)+pixel_offset);
            new_max = max(max(subpic));
            % do pixelwise repositioning of new maximum and store old data
            old_peak(2,l) = peakvalues(2,l); old_peak(3,l) = peakvalues(3,l);
            [new_max_x,new_max_y] = find(subpic == new_max,1,'first');
            peakvalues_new(2,l) = round(peakvalues(2,l) + (new_max_x - (data.values.dotsize+1)/2));
            peakvalues_new(3,l) = round(peakvalues(3,l) + (new_max_y - (data.values.dotsize+1)/2));
            % choose new subpic test if not at boarder else restore old
            % positions
            if size(pic,2) - pixel_offset - 2 > peakvalues_new(2,l) && peakvalues_new(2,l) > pixel_offset+2 && size(pic,1) - pixel_offset -2 > peakvalues_new(3,l) && peakvalues_new(3,l) > 2+ pixel_offset
                subpic = pic(peakvalues_new(2,l)-pixel_offset:peakvalues_new(2,l)+pixel_offset,peakvalues_new(3,l)-pixel_offset:peakvalues_new(3,l)+pixel_offset);
            else
                peakvalues_new(2,l) = old_peak(2,l); peakvalues_new(3,l) = old_peak(3,l);
            end
            
            % do subpixel positioning
            
             regionstruct = regionprops(peak_area,subpic,'WeightedCentroid');
             new_max_y = regionstruct.WeightedCentroid(1);
             new_max_x = regionstruct.WeightedCentroid(2);
            % adjust the subpic so the maximum is not influenced by the
            % pick of the pixelwise ROI
            
            % do the shift calculation
             center_x = new_max_x - pixel_offset; center_y = new_max_y - pixel_offset;
             ROI_contribution = zeros(3,3);
                for x = 1:3
                    for y = 1:3
                        if abs(center_y - y) < 1 && abs(center_x - x) < 1
                            ROI_contribution(x,y) = (1 - abs(center_x - x)) * (1 - abs(center_y - y));

                        end
                    end
                end
            ROI_calc = double(pic(peakvalues_new(2,l)-pixel_offset-1:peakvalues_new(2,l)+pixel_offset+1,peakvalues_new(3,l)-pixel_offset-1:peakvalues_new(3,l)+pixel_offset+1));
            % construct new ROI
            for x_w = 2:data.values.dotsize+1
                for y_w = 2:data.values.dotsize+1
                    ROI_contribution2 = zeros(data.values.dotsize+2,data.values.dotsize+2);
                    ROI_contribution2(x_w-1:x_w+1,y_w-1:y_w+1) = ROI_contribution;
                    subpic(x_w-1,y_w-1) = sum(sum(ROI_contribution2.*ROI_calc));
                end
            end
             regionstruct = regionprops(peak_area,subpic,'WeightedCentroid');
             new_max_y = new_max_y + regionstruct.WeightedCentroid(1) - pixel_offset - 1;
             new_max_x = new_max_x + regionstruct.WeightedCentroid(2) - pixel_offset - 1;
             
             %find new maximum value
             new_max = max(max(subpic));
             % correct for starting at frame 2
             if k == 2
                 old_max(l) = new_max;
                 tracking(3,l,1) = 1;
                 tracking(1,l,1) = peakvalues(2,l); tracking(2,l,1) = peakvalues(3,l);
                 data.values.bleaching_data(1,l) = sum(sum(subpic));                
             end
            %store positions for pixelwise
            %tracking(1,l,k) = peakvalues(2,l); tracking(2,l,k) =  peakvalues(3,l);
            
            % store bleaching value
            max_integrated = sum(sum(subpic));
            data.values.bleaching_data(k,l) = max_integrated;
            
            
            %check for maximum being high enough to calculate new positions
            if new_max > old_max(l)/data.values.tracking_factor && size(pic,2) - pixel_offset > new_max_x && size(pic,1) - pixel_offset > new_max_y && tracking(3,l,k-1) == 1
                        old_max(l) = new_max;
                        %assign new maximum positions and store the tracking data
                        tracking(2,l,k) = peakvalues_new(3,l) + (new_max_y - (data.values.dotsize+1)/2); tracking(1,l,k) = peakvalues_new(2,l) + (new_max_x - (data.values.dotsize+1)/2);
                        tracking(3,l,k) = 1;
                        peakvalues(2,l) = round(peakvalues_new(2,l) + (new_max_x - (data.values.dotsize+1)/2));
                        peakvalues(3,l) = round(peakvalues_new(3,l) + (new_max_y - (data.values.dotsize+1)/2));                   
            else
                        tracking(2,l,k) = peakvalues(3,l) + (new_max_y - (data.values.dotsize+1)/2); tracking(1,l,k) = peakvalues(2,l) + (new_max_x - (data.values.dotsize+1)/2); tracking(3,l,k) = 0;
            end
            sprintf('frame %d',k);
        else
            if k > 1
                data.values.bleaching_data(k,l) = data.values.bleaching_data(k-1,l);
            else
                data.values.bleaching_data(k,l) = 1;
            end
        end
    end

        
end
  
%%% do POST filtering of the data for various criteria
do_post = 0

if do_post == 1;
% pre populate the filtered tracking to avoid zeros at the beginning
tracking_filter = zeros(size(tracking));
tracking_filter(:,:,1:fitting_window) = tracking(:,:,1:fitting_window);
%%%%%% Maybe this should be changed afterwards????? %%%%%%
tracking_filter(:,:,end-window_offset:end) = tracking(:,:,end-window_offset:end);



for l = 1:data.values.peaknumber  %cycle dots
    set(data.handles.gui.displays.dot_number,'String',sprintf('peak %d of %d',l,data.values.peaknumber))
    drawnow
    for k = fitting_window:num_images %cycle frames
        % check if tracking by first intensity was active
        if tracking(3,l,k) == 1; 
            x = squeeze(tracking(2,l,k-fitting_window+1:k));
            y = squeeze(tracking(1,l,k-fitting_window+1:k));
            % do the fit
            p = polyfit(x,y,1);
            yfit = polyval(p,x);
            %calculate the quality of the fit
            yresid = y - yfit;
            SSresid = sum(yresid.^2); SStotal = (length(y)-1) * var(y);
            rsq = 1 - SSresid/SStotal;
            
            mom_max_x = round(tracking(1,l,k)); mom_max_y = round(tracking(2,l,k));
            if size(pic,2) - pixel_offset - 2 > mom_max_x && mom_max_x > pixel_offset + 2 ...
                && size(pic,1) - pixel_offset - 2 > mom_max_y && mom_max_y > pixel_offset + 2 
                mom_max_integrated = sum(sum(pic(mom_max_x-pixel_offset:mom_max_x+pixel_offset,mom_max_y-pixel_offset:mom_max_y+pixel_offset)));
                mom_max_surrounding = sum(sum(pic(mom_max_x-pixel_offset-2:mom_max_x+pixel_offset+2,mom_max_y-pixel_offset-2:mom_max_y+pixel_offset+2)))-mom_max_integrated;
                factor_surrounding = (mom_max_integrated/dotsize^2)/(mom_max_surrounding/((dotsize+4)^2-dotsize^2));
            else
                factor_surrounding = 100;
            end
            
            if rsq > 0.5 && rsq <= 1 && data.values.bleaching_data(k,l) > data.values.bleaching_data(k-1,l)/data.values.tracking_factor*0.8 ...
                    && factor_surrounding > 1.01
                %assign new maximum positions and store the tracking data
                tracking_filter(2,l,k-fitting_window+1:k) = tracking(2,l,k-fitting_window+1:k); tracking_filter(1,l,k-fitting_window+1:k) = tracking(1,l,k-fitting_window+1:k); 
            else
                tracking_filter(2,l,k) = tracking_filter(2,l,k-1);tracking_filter(1,l,k) = tracking_filter(1,l,k-1);
            end
        else
            tracking_filter(2,l,k) = tracking(2,l,k); tracking_filter(1,l,k) = tracking(1,l,k);
        end
    end
end
end




analysis.bleaching_data = data.values.bleaching_data;
analysis.peakvalues = peakvalues;
analysis.peakvalues_original = peakvalues_original;
analysis.bleaching_data_smooth = data.values.bleaching_data;
if do_post == 1
    analysis.tracking = tracking_filter;
    data.values.tracking = tracking_filter;
else
    analysis.tracking = tracking;
    data.values.tracking = tracking;
end
analysis.num_images = num_images;
guidata(data.handles.figures.main,data)
set(data.handles.gui.displays.dot_number,'String','done')
end

