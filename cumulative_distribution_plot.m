function cumulative_distribution_plot(data,Trunc)

if nargin == 0
    data = exprnd(2.5,200,1);
    data = data(data > 1);
    Trunc = 1
end

n = length(data);

figure
histogram(data,'Normalization','pdf')
hold on

x = sort(data)-Trunc;
p = ((1:n)-0.5)' ./ n;

stairs(x,p)

y = -log(1 - p);
[muHat,muHat_int] = regress(x,y);
err = abs(diff(muHat_int))/2;
goodness.rsquare = 1 - sum((y - x/muHat).^2)/sum((y-mean(y)).^2); 

hold off
plot(x,y,'+', y*muHat,y,'r--')

figure('Color','white')
ax = axes;
plot(x+Trunc,p,'Color','black','LineWidth',3)
hold on
plot(x+Trunc,expcdf(x,muHat),'LineWidth',3,'LineStyle',':','Color',[0.2100    0.4900    0.7200])
ax.Box = 'off';
ax.YLabel.String = 'CDF';
ax.XLabel.String = ['Run length [' char(181) 'm]'];
ax.FontSize = 18;
ax.XLim(1) = 0;

txt = text(0,0,{['N = ' num2str(length(data))], ['l = ' num2disp(muHat,err) ' ' char(181) 'm'], ['r^2 = ' num2str(round(100*goodness.rsquare)) ' %']});
txt.Position(1:2) = [ax.XLim(1)+(diff(ax.XLim)*0.4), ax.YLim(2)*0.5];
txt.FontSize = 18;

hold off
end