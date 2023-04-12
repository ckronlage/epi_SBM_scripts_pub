
set(0,'DefaultFigureWindowStyle','docked');
warning('off','all')

addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

hrT1_asegstats = readtable('0hrT1MP2diff/asegstats_hrT1.csv');
MP2_asegstats = readtable('0hrT1MP2diff/asegstats_MP2.csv');

segs = {'CortexVol','CerebralWhiteMatterVol',...
'BrainSegVol','EstimatedTotalIntraCranialVol'};

T = tiledlayout(2,2);

T.TileSpacing = 'compact';
T.Padding = 'compact';

for seg = segs
    t = tiledlayout(T,1,3);
    t.Layout.Tile = find(matches(segs,seg));
    t.TileSpacing = 'compact';
    t.Padding = 'tight';

    title(t,seg{1},'Fontsize',10,'VerticalAlignment','bottom');

    nexttile(t,[1 2])
    hrT1_data = hrT1_asegstats{:,seg{1}};
    MP2_data = MP2_asegstats{:,seg{1}};

    hrT1_data = 0.001 * hrT1_data;
    MP2_data = 0.001 * MP2_data;

    [p, h] = signrank(hrT1_data,MP2_data);
    disp(p);

    boxplot([hrT1_data, MP2_data],'Labels',{'hrT1','MP2'});

    nexttile(t);
    diff = MP2_data-hrT1_data;
    maxdiff = max(abs(diff));
    edges = linspace(-maxdiff,maxdiff,40);
    histogram(diff,edges,'Orientation','horizontal');
    set(gca,'YLim',[-maxdiff maxdiff])
    %set(gca,'YLim',[-50 50])
    set(gca,'XTickLabel',[])    
    xlabel('diff');

    % figure
   % scatter(hrT1_data,MP2_data);
   % hold on
   % maxval = max([hrT1_data,MP2_data])
   % plot([0:maxval/100:maxval],[0:maxval/100:maxval])
   % hold off
end
