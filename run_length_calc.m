function data = run_length_calc(varargin)
handles = varargin{1};
show_adjust = 0;
xTrunc = 1; %?m is readjusted if there are 4 inputs into the function
do_plot = 1;

if length(varargin) == 1 % adjust for different uses of this function
    % this is for when it is called from the tracking GUI
    data = guidata(handles.figures.main);
    run_length = zeros(1,1);
    only_speeded = 1; % 0 for all runs 1 for speeded runs only

    num_runs = size(data.values.runs,1);
    %num_runs = size(runs_new);
    for i = 1:num_runs
        if only_speeded == 1
            if  data.values.runs{i}(8,1) == 1 %&& only_speeded == 0 % this can be activated to only take runs into account that have really been measured
                run_length(i) = max(data.values.runs{i}(6,:));
            end
        elseif only_speeded == 0
%            if  data.values.runs{i}(8,1) == 1
                run_length(i) = max(data.values.runs{i}(6,:));
%            end
        end
    end
    runs = run_length'*data.values.meta_data.PixelConversion; %6.9 for FIONA
    data.values.run_lengths = runs;
    guidata(handles.figures.main,data);
elseif length(varargin) == 2
    runs = varargin{2};
elseif length(varargin) == 3
    runs = varargin{2};
    show_adjust = varargin{3};
elseif length(varargin) == 4
    runs = varargin{2};
    show_adjust = varargin{3};
    xTrunc = varargin{4}; %?m 
elseif length(varargin) == 5
    runs = varargin{2};
    show_adjust = varargin{3};
    xTrunc = varargin{4}; %?m
    do_plot = varargin{5};
end

overview_fig = figure;
old_runs = runs(runs>0.1);
histogram(old_runs)
runs = runs(runs > xTrunc);
data.values.run_lengths = runs;
% sort out really long runs

start = mean(runs);

y_func = @(x,mu) exppdf(x,mu)./(1-expcdf(xTrunc,mu));

[mu, conf] = mle(runs,'pdf',y_func,'start',start);
stderr = (conf(1)-conf(2))/2;
untrunc = mle(runs,'distribution','exp','start',start);

max_runs = 25;
x_pos = xTrunc:0.2:max_runs;

hold on
h = histogram(runs);

if show_adjust == 0
    bin_heights = h.Values; bins = h.BinEdges;
    %bin_heights = (bin_heights/sum(bin_heights)*y_func(xTrunc,mu));
    bins = linspace(bins(1)+(bins(2)-bins(1))/2,bins(end) - (bins(end)-bins(end-1))/2,length(bins)-1);

    acov = mlecov(mu, runs, 'pdf',y_func);
    stderr = sqrt(diag(acov));


    % Choose number of bins to fit nicely to the exponential distribution
    N_max = 100;
    N_min = 20;
    dist = zeros(1,N_max-N_min);
    h_N = histogram(runs);
    hold off

    plot_it = 0;
    if plot_it == 1
        figure
    end
    for N = N_min:N_max
       h_N.BinEdges = linspace(xTrunc,max(runs(:)),N);
       d = min(diff(h_N.BinEdges)/2);
       BinCenters = h_N.BinEdges(1:end-1) + d;
       y = y_func(BinCenters,mu);
       Values = h_N.Values/length(runs)/max(d)/2;
       dist(N-N_min+1) = mean((y-Values).^2);
       if plot_it == 1
           bar(BinCenters,Values,'hist');
           hold on
           plot(BinCenters,y,'r');
           hold off
           pause(0.2)
       end
    end

    N = find(dist == min(dist(:)),1,'first')+N_min;
    x_threshold = xTrunc; threshold = 10;
    while threshold > 0.001
        x_threshold = x_threshold + 0.2;
        threshold = y_func(x_threshold,mu);
    end    
    x_pos = xTrunc+d(1):0.2:x_threshold;
    y = y_func(x_pos,mu);
    
    
    bin_Edges = linspace(min(runs(:)),max(runs(:)),N);
    adjust_output.cumulative_mode = 0;
elseif show_adjust == 1
    adjust_output = adjust_histogram(runs,xTrunc);
    if adjust_output.cumulative_mode == 0
        bin_Edges = adjust_output.hist_BinEdges;
        h.BinEdges = bin_Edges;
        d = min(diff(h.BinEdges)/2);
        Values = h.Values;
        BinCenters = h.BinEdges(1:end-1) + d;
        exp_fit = fittype(@(A,b,x) A*exp(-x/b));
        start_point = [length(runs) mean(runs)];
        [f,goodness] = fit(BinCenters(:),Values(:),exp_fit,'StartPoint',start_point);
        y = y_func(x_pos,mu);
    elseif adjust_output.cumulative_mode == 1
        mu = adjust_output.mu; data.stderr = adjust_output.err;
        if do_plot == 1
            cumulative_distribution_plot(h.Data,xTrunc)
        end
    end
end







%add data to the figure for later changes
data.mu = mu; data.stderr = stderr;

if adjust_output.cumulative_mode == 1
    return
end

data.bin_edges = bin_Edges; data.y = y; data.x = x_pos;

h_fig = figure('Color','white','FileName','length');
if do_plot == 1
    h_hist = histogram(runs,'FaceColor','w');
    h_hist.BinEdges = bin_Edges;
    if show_adjust == 0
        d = min(diff(h_hist.BinEdges)/2);
        Values = h_hist.Values/length(runs)/max(d)/2;
        BinCenters = h_hist.BinEdges(1:end-1) + d;
        h_bar = bar(BinCenters,Values,'hist');
        h_bar.FaceColor = 'white';
        h_ax = gca;
        h_ax.Box = 'off';
        hold on
        h_dist = plot(x_pos,y,'r');
        h_dist.LineWidth = 2; h_dist.Color = [0.21 0.49 0.72];
        axes_handle = gca;
        str = {['N = ' num2str(length(runs))];['l = ' num2disp(mu,stderr,'?m')]};
        text(axes_handle.XLim(2)*0.6,axes_handle.YLim(2)*0.8,str,'FontSize',16)
    elseif show_adjust == 1
        bincenters = h.BinEdges(1:end-1) + diff(h.BinEdges(1:2))/2;

        if adjust_output.fittype == 4
            y_func =  @(x,mu) x.*exppdf(x,mu)./(1-expcdf(xTrunc,mu));
            ft = fittype('a*mu^2*x.*exp(-x/mu)','problem','mu');
        else
            ft = fittype('a*exp(-x/mu)','problem','mu');
        end

        [mu_fit, conf] = mle(runs,'pdf',y_func,'start',start);     
        curve = fit(bincenters',h.Values',ft,'problem',mu_fit,'start',length(h.Values));
        x_pos = x_pos(x_pos > 0.5*xTrunc);
        hold on;

        if adjust_output.fittype == 4
            fit_plot = plot(x_pos,curve.a*mu^2*x_pos.*exp(-x_pos/mu_fit));
        else
            fit_plot = plot(x_pos,curve.a*exp(-x_pos/mu_fit));
        end
        fit_plot.Color = [0.21 0.49 0.72];
        hold off
        l_err = (conf(2)-conf(1))/2;
        [~,l,l_err] = num2disp(mu_fit,l_err);
        fit_plot.LineWidth = 2;
        axes_handle = gca;
        str = ['\textsf{\tabcolsep=0.02cm\begin{tabular}{lll} N & = &' num2str(length(runs)) '\\ l & = &' l ' $\pm$ ' l_err  ' $\mathrm{\mu}$m \\ $\textrm{r}^{2}$ & = & ' num2str(round(goodness.rsquare*100)) ' \% \end{tabular}}'];
        annotation('textbox',[0.5 0.7 0.01 0.01],'interpreter','latex','String',str,'FitBoxToText','on','EdgeColor','none','FontSize',16)%,'FontName','cmr12')
        legend(axes_handle,'off')
        axes_handle.FontSize = 15; axes_handle.Box = 'off'; axes_handle.TickDir = 'out';
    end
    xlabel('Run length [\mum]')
    ylabel('Number of Events')
    axes_handle.XLim = [0 axes_handle.XLim(2)];
    hold off
    
elseif do_plot == 0
    fig = gcf;
    close(fig)
    close(overview_fig)
end


end