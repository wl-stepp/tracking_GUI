function [display_string,varargout] = num2disp(value,error,varargin)

    if isempty(varargin)
        unit = '';
        mode = 0;
    elseif nargin == 3
        unit = varargin{1};
        mode = 0;
    elseif nargin == 4
        unit = varargin{1};
        mode = varargin{2};
    end
    
    if mode == 0
        pm = char(177);
        bracket_1 = '('; bracket_2 = ')';
    elseif mode == 1;
        pm = '$$\pm$$';
        bracket_1 = ''; bracket_2 = '';
    end
        
    if 1/error < 1
        new_value = round(value);
        new_error = round(error);
        format_value = '%i';
        format_error = '%i';
    else
        new_value = round(value*ceil(log10(1/error))*1000)/ceil(log10(1/error))/1000;
        new_error = round(error*ceil(log10(1/error))*1/error)/ceil(log10(1/error))*error;
        digits_value = ceil(log10(1/error));
        digits_error = ceil(log10(1/error));
        format_value = sprintf('%s%i%s','%1.',digits_value,'f');
        format_error = sprintf('%s%i%s','%1.',digits_error,'f');
    end
    display_string = [bracket_1 num2str(new_value,format_value) ' ' pm ' ' num2str(new_error,format_error) bracket_2 ' ' unit];
    varargout{1} = num2str(new_value,format_value);
    varargout{2} = num2str(new_error,format_error);

end