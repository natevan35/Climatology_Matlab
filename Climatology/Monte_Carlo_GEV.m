%% Code to perform a Monte Carlo simulation on GEV parameters for assessment of RI
% First load in the data
clearvars

%first load in the data
dir_nm = '../../COOPS_tides/';
%dir_nm = '../../hourly_data/gap_hourly/Station_Choice/';
station_name = 'Seattle';
station_nm = 'seattle';

load_file = strcat(dir_nm,station_nm,'/',station_nm,'_hrV');
load(load_file)
clear dir_nm file_nm load_file

%% Grab Maxima 

% Years available
yr = year(tides.time(1)):year(tides.time(end));

% Find mean of last 10 years 
tinds = find(year(tides.time) == yr(end) - 10);
inds = tinds(1):length(tides.WL_VALUE);
ten_mean = mean(tides.WL_VALUE(inds));

% Detrend tides
tides.WL_VALUE = detrend(tides.WL_VALUE);

% rth values to collect (can use less later)
r_num = 10;

% Min distance between events (half hour incr) 24 if half our, 12 if hour
min_sep = 12;

% Preallocate
maxima = zeros(length(yr),r_num);

% Loop
for yy=1:length(yr)
    inds = year(tides.time) == yr(yy);
    temp = tides.WL_VALUE(inds);
    for r=1:r_num
        [maxima(yy,r), I] = max(temp);
        pop_inds = max([1 I-min_sep]):min([length(temp) I+min_sep]);
        temp(pop_inds) = [];
    end
end

% Create variable with water level back to datum
data_datum = maxima + ten_mean;

% Numer of data points
n = length(maxima);

%% Calculate estimated GEV parameters 

% Grab GEV estimates
[parmhat parmCI] = gevfit(maxima(:,1));

% Grab specific params
khat = parmhat(1);
sighat = parmhat(2);
muhat = parmhat(3);

% Calculate Standard Error for each parameter 
kSE = (parmCI(1,1)-khat)/2;
sigSE = (parmCI(1,2)-sighat)/2;
muSE = (parmCI(1,3)-muhat)/2;

%% Run Monte Carlo for Parameters 
tic
% preallocate
its = 100;
monteK = zeros(1,its);
monteSig = monteK;
monteMu = monteK;

% run simulation
for jj = 1:its
    monteK(1,jj) = khat + (kSE * randn(1,1));
    monteSig(1,jj) = sighat + (sigSE * randn(1,1));
    monteMu(1,jj) = muhat + (muSE * randn(1,1));
end
toc
%% visualize results 
figure(1)
subplot(3,1,1)
hist(monteK)
xlabel('K-hat')
ylabel('# of hits')

subplot(3,1,2)
hist(monteSig)
xlabel('Sig-hat')
ylabel('# of hits')

subplot(3,1,3)
hist(monteMu)
xlabel('Mu-hat')
ylabel('# of hits')

%% Now calculate RI using results from Monte Carlo simulation 

% First calculate cdf 
x_axis = linspace((min(maxima(:))+ten_mean),(max(maxima(:))+ten_mean),100);
count = 1;
cdf = zeros(length(x_axis),length(monteK)^3);
for ii = 1:length(monteK)
    for jj = 1:length(monteSig)
        for kk = 1:length(monteMu)
            cdf(:,count) = 1 - gevcdf(x_axis,monteK(ii),monteSig(jj),monteMu(kk)+ten_mean);
            count = count+1;
        end
    end
end

%% Calculate RI and plot
clf
RI = 1./cdf;

line(x_axis, RI)
xlim([3 4])
ylim([0 100])

% Get all the points where RI is the 100 year level