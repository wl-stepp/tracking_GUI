function data = distance_calc(handles)
data = guidata(handles.figures.main);


data.values.tracking(3,:,1) = zeros(size(data.values.tracking,2),1);
% Calculate the distance from the starting point for each tracking point
for frame = 2:data.values.num_images
    data.handles.gui.displays.dot_number.String = sprintf('frame %d of %d',frame,data.values.num_images);
    for dot = 1:data.values.peaknumber
        data.values.tracking(3,dot,frame) = sqrt((data.values.tracking(1,dot,frame)-data.values.tracking(1,dot,1))^2+(data.values.tracking(2,dot,frame)-data.values.tracking(2,dot,1))^2);
    end
end

guidata(handles.figures.main,data)
end