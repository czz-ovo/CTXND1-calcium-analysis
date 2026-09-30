function runDir = plot_calcium_dFF(excelFile,cellInfo,saveRoot,userCfg)
% cellInfo columns: Group, Mouse, CellID, optional ExcelRow to disambiguate.
% Detect on the analysis window first; only then crop the displayed trace.
if nargin<4, userCfg=struct(); end
c=dffAnalysisConfig(userCfg); rows=dffaSessions(excelFile);
if istable(cellInfo), cellInfo=table2cell(cellInfo); end
if ~iscell(cellInfo) || size(cellInfo,2)<3, error('dffAnalysis:Selection','cellInfo requires Group, Mouse, CellID.'); end
if ~isfolder(saveRoot), mkdir(saveRoot); end
[~,tag]=fileparts(tempname(saveRoot));
runDir=fullfile(saveRoot,['plot_' datestr(now,'yyyymmdd_HHMMSS') '_' tag]); mkdir(runDir);
selected=struct('Group',{},'Mouse',{},'CellID',{},'ExcelRow',{},'Y',{},'F0',{},'Events',{},'Stats',{},'Source',{});
cachedIndex=0; failures=struct('SelectionRow',{},'Message',{});
for i=1:size(cellInfo,1)
    try
        group=char(string(cellInfo{i,1})); mouse=char(string(cellInfo{i,2}));
        n=str2double(string(cellInfo{i,3}));
        validateattributes(n,{'numeric'},{'scalar','finite','positive','integer'});
        ix=find(strcmp({rows.Group},group) & strcmp({rows.Mouse},mouse));
        if size(cellInfo,2)>=4 && ~isempty(cellInfo{i,4})
            excelRow=str2double(string(cellInfo{i,4}));
            ix=ix([rows(ix).ExcelRow]==excelRow);
        end
        if numel(ix)~=1
            error('dffAnalysis:Ambiguous','Group=%s, Mouse=%s has %d matching sessions. Specify ExcelRow in column 4.',group,mouse,numel(ix));
        end
        if ix~=cachedIndex, [d,source]=dffaLoad(rows(ix).Path,c); cachedIndex=ix; end
        if n>d.K, error('dffAnalysis:Cell','Cell %d exceeds %d cells in %s.',n,d.K,source); end
        [E,s]=dffaCell(d.Y(:,n),d.F0(:,n),c);
        if s.ValidFrames==0, error('dffAnalysis:Invalid','Selected cell has no valid samples.'); end
        selected(end+1)=struct('Group',group,'Mouse',mouse,'CellID',n, ...
            'ExcelRow',rows(ix).ExcelRow,'Y',d.Y(:,n),'F0',d.F0(:,n), ...
            'Events',E,'Stats',s,'Source',source); %#ok<AGROW>
    catch ME
        failures(end+1)=struct('SelectionRow',i,'Message',ME.message); %#ok<AGROW>
        warning('dffAnalysis:PlotSelection','Selection row %d: %s',i,ME.message);
    end
end
save(fullfile(runDir,'plot_data.mat'),'selected','failures','c','cellInfo','excelFile','-v7.3');
if ~isempty(failures), writetable(struct2table(failures),fullfile(runDir,'selection_errors.csv')); end
if isempty(selected), error('dffAnalysis:NoPlots','No valid selected cells. See %s',runDir); end
groups=unique({selected.Group},'stable');
% One shared layout for EVERY group and both export variants. A common bar
% value alone is insufficient if axes limits or physical heights differ.
layout=sharedLayout(selected,groups,c);
save(fullfile(runDir,'plot_scale.mat'),'layout','c');
if ~c.NormalizePlotToOwnPeak
    fprintf('Shared scale: 100%% dFF (1.0) = %.6g mm in every unresized export.\n',layout.MillimetresPerUnit);
end
for g=1:numel(groups)
    cells=selected(strcmp({selected.Group},groups{g}));
    stem=sprintf('%02d_%s',g,regexprep(groups{g},'[\\/:*?"<>| ]','_'));
    draw(cells,c,fullfile(runDir,[stem '_withScale']),true,layout);
    draw(cells,c,fullfile(runDir,[stem '_noScale']),false,layout);
end
fprintf('Plots: %s\n',runDir);
end
function layout=sharedLayout(selected,groups,c)
lowest=0; highest=0; maxRows=0;
for i=1:numel(selected)
    y=displayTrace(selected(i).Y,c); v=y(isfinite(y));
    if ~isempty(v)
        lowest=min(lowest,min(v)); highest=max(highest,max(v));
    end
end
for g=1:numel(groups), maxRows=max(maxRows,sum(strcmp({selected.Group},groups{g}))); end
bar=c.AmplitudeBar; if c.NormalizePlotToOwnPeak, bar=1; end
% Reserve the global zero-referenced amplitude envelope in EVERY row. Using
% each trace's own range could hide elevated baselines and cause overlap.
step=max([1.3*(highest-lowest),1.6*bar,0.02]);
figH=max(2.5,0.52*maxRows+0.7); figW=c.FigureWidthInches;
layout=struct('Step',step,'Highest',highest,'MaxRows',maxRows, ...
    'FigureSizeInches',[figW figH], ...
    'AxesPositionInches',[0.08*figW 0.08*figH 0.89*figW 0.88*figH], ...
    'YLim',[-(maxRows-1)*step+lowest-step, highest+0.45*step], ...
    'PeakNormalized',logical(c.NormalizePlotToOwnPeak));
layout.MillimetresPerUnit=25.4*layout.AxesPositionInches(4)/diff(layout.YLim);
layout.RowSpacingMillimetres=step*layout.MillimetresPerUnit;
end
function y=displayTrace(y,c)
n=min(numel(y),floor(c.PlotSeconds*c.Fs)); y=y(1:n);
v=y(isfinite(y));
if c.NormalizePlotToOwnPeak && ~isempty(v)
    y=y-median(v); peak=max(y(isfinite(y)));
    if peak>0, y=y/peak; end
end
end
function draw(cells,c,base,withScale,layout)
N=numel(cells); step=layout.Step; highest=layout.Highest;
offsets=-(0:N-1)*step;
if c.NormalizePlotToOwnPeak, bar=1; label='normalized'; else, bar=c.AmplitudeBar; label=sprintf('%.2g dFF (%.2g%%)',bar,100*bar); end
fig=figure('Visible','off','Color','w','Units','inches', ...
    'Position',[1 1 layout.FigureSizeInches]);
cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
ax=axes('Parent',fig,'Units','inches','Position',layout.AxesPositionInches, ...
    'ActivePositionProperty','position'); hold(ax,'on');
for i=1:N
    y=displayTrace(cells(i).Y,c); t=(0:numel(y)-1)'/c.Fs;
    plot(ax,[0 c.PlotSeconds],[offsets(i) offsets(i)],':','Color',[.75 .75 .75],'LineWidth',.5);
    plot(ax,t,y+offsets(i),'k-','LineWidth',1.2);
    E=cells(i).Events; long=E.DurationSeconds>=round(c.HighlightSeconds*c.Fs)/c.Fs;
    for j=find(long).'
        st=E.StartFrame(j); en=min(E.EndFrame(j),numel(y));
        if st<=en
            plot(ax,t(st:en),y(st:en)+offsets(i),'-','Color',[.95 .55 .15],'LineWidth',1.8);
        end
    end
    if c.ShowTraceLabels
        text(ax,0,offsets(i)+highest+0.08*step,sprintf('%s | cell %d',cells(i).Mouse,cells(i).CellID), ...
            'Interpreter','none','FontSize',7,'VerticalAlignment','bottom');
    end
end
bottom=layout.YLim(1);
xlim(ax,[0 c.PlotSeconds]); ylim(ax,layout.YLim); axis(ax,'off');
if withScale
    timebar=min(c.TimeBarSeconds,0.8*c.PlotSeconds);
    x0=c.PlotSeconds-timebar-0.03*c.PlotSeconds; y0=bottom+0.3*step;
    plot(ax,[x0 x0+timebar],[y0 y0],'k-','LineWidth',1.3);
    plot(ax,[x0 x0],[y0 y0+bar],'k-','LineWidth',1.3);
    text(ax,x0+timebar/2,y0-0.10*step,sprintf('%g s',timebar),'FontSize',8,'HorizontalAlignment','center','VerticalAlignment','top');
    text(ax,x0-0.02*c.PlotSeconds,y0+bar/2,label,'FontSize',7,'HorizontalAlignment','right','Interpreter','none');
end
set(fig,'PaperUnits','inches','PaperSize',layout.FigureSizeInches, ...
    'PaperPosition',[0 0 layout.FigureSizeInches],'PaperPositionMode','manual');
print(fig,[base '.png'],'-dpng','-r300');
print(fig,[base '.tif'],'-dtiff','-r300');
savefig(fig,[base '.fig']);
end
