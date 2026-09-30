function dffaCombinedExport(r,runDir,c)
% CSV is always retained. Split large Excel sheets without losing rows.
settings=table({'Fs';'HalfDecayBaseline';'HalfDecayMethod';'EndCut';'Complete'; ...
    'CellCounting';'MissingHalfDecay';'DurationThresholds';'DurationUnit'; ...
    'SummaryWeighting';'InputRows';'SuccessfulRows';'FailedRows';'SkippedRows'}, ...
    {num2str(c.Fs);'0 in current ms.dFF; same reference as Amplitude'; ...
    'Peak to first 50% downward crossing; linear interpolation; stop before next event or missing data'; ...
    'Event remains active at last analysed frame; excludes recording end OR chosen analysis-window end'; ...
    'Neither left-censored nor right-censored'; ...
    'Cell-recordings summed across sessions, NOT registered unique biological cells'; ...
    'NaN (may display blank in Excel), never zero; means use finite observations only'; ...
    mat2str(c.DurationSeconds);'Seconds; >= thresholds are cumulative and overlap'; ...
    'MeanCell columns give equal weight to finite cell means; group summaries do not weight mice equally'; ...
    num2str(height(r.Report));num2str(sum(strcmp(r.Report.Status,'complete'))); ...
    num2str(sum(strcmp(r.Report.Status,'failed')));num2str(sum(strcmp(r.Report.Status,'skipped_duplicate')))}, ...
    'VariableNames',{'Setting','Value'});
fields=fieldnames(c);
for k=1:numel(fields)
    value=c.(fields{k});
    if isnumeric(value) || islogical(value), value=mat2str(value); else, value=char(value); end
    settings=[settings;table({['Config.' fields{k}]},{value},'VariableNames',{'Setting','Value'})]; %#ok<AGROW>
end
bundle(fullfile(runDir,'ALL_cells'),r.AmplitudeHalfDecay,r.Duration, ...
    r.MouseSummary,r.GroupSummary,r.Report,settings,c);
mouseDir=fullfile(runDir,'by_mouse'); groupDir=fullfile(runDir,'by_group');
mkdir(mouseDir); mkdir(groupDir);
for id=unique(r.AmplitudeHalfDecay.MouseID)'
    C=r.AmplitudeHalfDecay(r.AmplitudeHalfDecay.MouseID==id,:);
    L=r.Duration(r.Duration.MouseID==id,:);
    P=r.Report(strcmp(r.Report.Group,C.Group{1}) & strcmp(r.Report.Mouse,C.Mouse{1}),:);
    bundle(fullfile(mouseDir,sprintf('mouse_%03d',id)),C,L, ...
        r.MouseSummary(r.MouseSummary.MouseID==id,:),table(),P,settings,c);
end
for id=unique(r.AmplitudeHalfDecay.GroupID)'
    C=r.AmplitudeHalfDecay(r.AmplitudeHalfDecay.GroupID==id,:);
    L=r.Duration(r.Duration.GroupID==id,:);
    P=r.Report(strcmp(r.Report.Group,C.Group{1}),:);
    bundle(fullfile(groupDir,sprintf('group_%03d',id)),C,L, ...
        r.MouseSummary(r.MouseSummary.GroupID==id,:),r.GroupSummary(r.GroupSummary.GroupID==id,:),P,settings,c);
end
end
function bundle(base,C,L,M,G,P,settings,c)
tables={C,L,M,G,P,settings};
names={'Amplitude_HalfDecay','Duration','MouseSummary','GroupSummary','ProcessingReport','Settings'};
for k=1:numel(tables)
    T=tables{k}; if width(T)==0, continue; end
    writetable(T,[base '_' names{k} '.csv']);
    if c.WriteXlsx
        % Excel maximum: 1,048,576 rows including one header row.
        capacity=1048575; parts=max(1,ceil(height(T)/capacity));
        for j=1:parts
            sheet=names{k}; if parts>1, sheet=sprintf('%s_%d',sheet,j); end
            ix=((j-1)*capacity+1):min(j*capacity,height(T));
            writetable(T(ix,:),[base '.xlsx'],'Sheet',sheet);
        end
    end
end
end
