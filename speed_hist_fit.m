function data = speed_hist_fit(varargin)

show_adjust = 0;
if length(varargin) == 1
    handles = varargin{1};
    data = guidata(handles.figures.main);
    speeds = data.values.speed.speed_hist;
elseif length(varargin) == 2
   speeds = varargin{2}; 
elseif length(varargin) == 3
   speeds = varargin{2};
   show_adjust = varargin{3};
elseif nargin == 4
   speeds = varargin{2};
   show_adjust = varargin{3};
   fittype = varargin{4};
else
   speeds = varargin{2};
   show_adjust = varargin{3};
end



speeds = speeds(speeds > 0);

if isempty(speeds); error('No speeds registered'); end

handle_figure1 = figure;
h_N = histogram(speeds);
if show_adjust == 0
    % Choose number of bins to fit nicely to the gaussian distribution
    N_max = 15;
    N_min = 5;
    dist = zeros(1,N_max-1);

    %h_fig2 = figure('Color','white');
    for N = N_min:N_max
       h_N.BinEdges = linspace(min(speeds(:)),max(speeds(:)),N);
       d = min(diff(h_N.BinEdges)/2);
       BinCenters = h_N.BinEdges(1:end-1) + d;
       Values = h_N.Values/length(speeds)/max(d)/2;
       [f,goodness] = fit(BinCenters',Values','gauss1');
       dist(N-3) = goodness.rsquare;

    %    bar(BinCenters,Values,'hist')
    %    hold on
    %    plot(f)
    %    hold off
    %    pause(0.3)
    end
    N = find(dist == max(dist(:)),1,'first') + N_min + 2;
    h_N.BinEdges = linspace(min(speeds(:)),max(speeds(:)),N);
    fittype = 1;
elseif show_adjust == 1
    adjust_output = adjust_histogram(speeds);
    bin_Edges = adjust_output.hist_BinEdges;
    fittype = adjust_output.fittype;
    h_N.BinEdges = bin_Edges;
else
    h_N.BinEdges = show_adjust;
end

x_pos = 0:max(speeds)/100:max(speeds)*1.2;



d = min(diff(h_N.BinEdges)/2);
BinCenters = h_N.BinEdges(1:end-1) + d;
Values = h_N.Values;
if fittype == 6
    [f,goodness] = fit(BinCenters',Values','gauss2');
    [~,v1,v_err1] = num2disp(f.b1,f.c1,'');
    [~,v2,v_err2] = num2disp(f.b2,f.c2,'');
    str = ['\textsf{\tabcolsep=0.02cm\begin{tabular}{lll} N & = &' num2str(length(speeds)) '\\ v1 & = &' v1 ' $\pm$ ' v_err1  ' $\frac{\textrm{nm}}{\textrm{s}}$ \\ v2 & = &' v2 ' $\pm$ ' v_err2  ' $\frac{\textrm{nm}}{\textrm{s}}$ \\$\textrm{r}^{2}$ & = & ' num2str(round(goodness.rsquare*100)) ' \% \end{tabular}}'];
else
    [f,goodness] = fit(BinCenters',Values','gauss1');
    x0 = f.b1;
    sigma = f.c1;
    [~,v,v_err] = num2disp(x0,sigma,'');
    str = ['\textsf{\tabcolsep=0.02cm\begin{tabular}{lll} N & = &' num2str(length(speeds)) '\\ v & = &' v ' $\pm$ ' v_err  ' $\frac{\textrm{nm}}{\textrm{s}}$ \\ $\textrm{r}^{2}$ & = & ' num2str(round(goodness.rsquare*100)) ' \% \end{tabular}}'];
    y = normpdf(x_pos,x0,sigma);
end



figure_handle2 = figure('Color','white','FileName','speed');
h_hist = histogram(speeds,'FaceColor','w');
h_hist.BinEdges = h_N.BinEdges;
h_ax = gca;
h_ax.Box = 'off';
h_ax.XLim = [0.7*h_hist.BinEdges(1) 1.3*h_hist.BinEdges(end)];
hold on
h_dist = plot(f,'r');
h_dist.LineWidth = 2;


annotation('textbox',[0.62 0.9 0.01 0.01],'interpreter','latex','String',str,'FitBoxToText','on','EdgeColor','none','FontSize',16,'FontName','cmr12')
xlabel('Speed [nm/s]')
ylabel('Number of Events')
legend(h_ax,'off')
h_ax.FontSize = 15; h_ax.TickDir = 'out';
hold off

% for Master thesis
h_dist.Color = [0.21 0.49 0.72];


delete(handle_figure1)
end