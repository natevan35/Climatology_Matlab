%% GEV Fit for Block Maxima

clearvars

%first load in the data
dir_nm = '../../hourly_data/';
%dir_nm = '../../Downloaded Raw Data/';
station_name = 'Whidbey';
station_nm = 'whidbey_nas';
load_file = strcat(dir_nm,station_nm, '_hourly');
load(load_file)
clear dir_nm file_nm load_file
%wnddir = wnddir';

% for NDBC data get rid of 'hourly' in load_file 
% Also add the following line after wnddir = wndir';
            % wndspd = wndspd_obs;
            

%% Find yearly min
yr_vec = year(time(2)):year(time(end-100)); %make a year vec, -10 because of NaNs
minima = NaN(length(yr_vec),1); %create vector to house all of the block maxima
for i = 1:length(yr_vec)
    yr_ind = find(year(time) == yr_vec(i));
    % If there is more than 50% of the hours missing for that year, I will
    % skip it
    if length(yr_ind) < 8760 * .5
        minima(i) = NaN;
    else
    %max_val = max(wndspd(yr_ind));
        minima(i) = min(slp(yr_ind));
    end
end

nan_ind = isnan(minima); % Find any nans and get rid of them
minima(nan_ind) = [];

% Max pressure values negative because I am concerned with minimum not
% maximum values
minima = -(minima);
clear j yr_ind

% Get GEV statistics about the data
[paramEsts, paramCIs] = gevfit(minima);
%----------------Results from GEV-------------------------------
% % % kMLE = paramEsts(1);        % Shape parameter
% % % sigmaMLE = paramEsts(2);    % Scale parameter
% % % muMLE = paramEsts(3);       % Location parameter
%% Plot the GEV
clf
x = minima; 
xmax = max(x)+10;
lowerBnd = min(x) - 10;
bins = floor(lowerBnd):ceil(xmax);

% plot the hist with GEV line
subplot(2,2,[1 3])
h = bar(bins,histc(x,bins)/length(x),'histc');
h.FaceColor = [.8 .8 .8];
xgrid = linspace(lowerBnd,xmax,100);
line(xgrid,gevpdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)));
xlim([lowerBnd xmax]);
plot_tit = sprintf('GEV - PDF - %s', station_name);
title(plot_tit)

ax = gca;  % Play with the Axes 
ax.XLim = [lowerBnd xmax];

% Add GEV parameters to the plot
tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f \nn: %d',...
    paramEsts(1),paramEsts(2),paramEsts(3), length(minima));
%text(10,0.25, tbox)

% Add box around the text
dim = [.28 .35 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');



xlabel('Minimum Sea Level Pressure [mb]')
ylabel('Probability Density')
%legend('Hourly','Six-Hr Avg.','Location','NorthEast')
box on

% Calculate the CDF - CDF will give me the probability of values 
cdf = gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF


% ----------Notes-----------
% - PDF sums to 1, represents probability density
% - CDF is the cumulative PDF, represents probability
% - CDF is the probability of the random variable being less than X

%% Calculate Recurrence Interval

%-------Note-----------%
%RI = 1/Probability
%Knowing CDF and thus the probability, I can calculate the Recurrence


RI = 1./cdf;
RI = fliplr(RI);
subplot(2,2,[2 4])
plot(xgrid, RI)
ylim([0 100])
plot_tit = sprintf('Recurrence Interval - %s', station_name);
title(plot_tit)
xlabel('Wind Speed [m/s]')
ylabel('Time [years]')


ax = gca;
set(gca,'XMinorTick','on')  %add minor tick marks on x-axis

box on 
grid on


% Generate specific values for recurrence levels

R100MLE = gevinv(1-1./100,paramEsts(1),paramEsts(2),paramEsts(3)) * -1;
R50MLE = gevinv(1-1./50,paramEsts(1),paramEsts(2),paramEsts(3)) * -1;
R25MLE = gevinv(1-1./25,paramEsts(1),paramEsts(2),paramEsts(3)) * -1;
R10MLE = gevinv(1-1./10,paramEsts(1),paramEsts(2),paramEsts(3)) * -1;
R5MLE = gevinv(1-1./5,paramEsts(1),paramEsts(2),paramEsts(3)) * -1;
R2MLE = gevinv(1-1./2,paramEsts(1),paramEsts(2),paramEsts(3)) * -1;

% Add GEV parameters to the plot
tbox = sprintf('100 yr: %4.2f m/s\n50 yr: %4.2f m/s\n25 yr: %4.2f m/s\n10 yr: %4.2f m/s\n5 yr: %4.2f m/s\n2 yr: %4.2f m/s'...
    ,R100MLE, R50MLE, R25MLE, R10MLE, R5MLE, R2MLE);
%text(6,60, tbox)

dim = [.62 .3 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');

%%
% Save the Plot
cd('../../Matlab_Figures/GEV/Updated')

outname = sprintf('GEV_%s',station_nm);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

cd('../../../matlab/Climatology')
