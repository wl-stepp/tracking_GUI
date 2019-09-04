function [cc, rsquared] = gaussian_fit_2D(peak_data,varargin)

if length(varargin) == 1
    do_plot = varargin{1};
else
    do_plot = 0;
end

[y_max,x_max] = find(peak_data == max(peak_data(:)),1,'first');
start = double([min(peak_data(:)) max(peak_data(:))-min(peak_data(:)) x_max 1.5 y_max 1.5]);
start(4) = 1.5; start(6) = 1.5; %the array on top gets rounded, as it's not double in the beginning I think

ZData = double(peak_data(:));
[n,m] = size(peak_data);
[X,Y] =meshgrid(1:m,1:n); %exchanged m and n
x(:,1) = X(:); x(:,2) = Y(:);

fun = @(start,x) start(1)+start(2)*exp(-((x(:,1)-start(3))/start(4)).^2-((x(:,2)-start(5))/start(6)).^2);
options=optimset('TolX',1e-6,'Display','off','FunValCheck','on'); % was 1e-8
lower_bounds = [0 0 -Inf 0.3 -Inf 0.3];
[cc,resnorm,residual,exitflag,output,lambda,J] = lsqcurvefit(fun,start,x,ZData,lower_bounds,[],options);
% calculate r_squared value
fitted = fun(cc,x);
C = corrcoef(ZData,fitted);
rsquared = C(1,2)^2;
%%% calculate the confidence interval (95%)
%ci = nlparci(cc,residual,'jacobian',J);
%%% this calculates the confidence interval
%((ci(3,2)-ci(3,1))/2+(ci(5,2)-ci(5,1))/2)/2*91


if do_plot == 1
    Ifit=reshape(fitted,[n m]);%gaussian reshaped as matrix
    Z = reshape(ZData,[n m]);
    surf(X,Y,Z,'FaceColor','interp','EdgeColor','none')
    hold on
    surf(X,Y,Ifit,'FaceColor','none')
    drawnow
    hold off
    alpha(0.7)
    colormap cool
end
end