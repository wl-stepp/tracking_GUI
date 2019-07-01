function meta_data = get_meta_data(location)
MetaData = textread(location, '%s','delimiter', '\n');
MetaData_String = [MetaData{:}];


var = 'Series';
pos = findstr(MetaData_String,'SizeC');
meta_data.FileType = MetaData_String(pos-3:pos-1);

if strcmp(meta_data.FileType,'sif')
    var = 'Line #03';
    pos = findstr(MetaData_String,var);
    meta_data.CycleTime = str2double(MetaData_String(pos+47:pos+53)); %s
    
    meta_data.PixelConversion = 0.133; %µm / px
else
    meta_data.FileType = 'lif'
    
    var = 'CycleTime';
    pos = findstr(MetaData_String,var);
    meta_data.CycleTime = str2num(MetaData_String(pos+length(var):pos+length(var)+10)); %s
    
    meta_data.PixelConversion = 0.1585546; %µm / px
end







end