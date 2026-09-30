function [summary,runDir] = dffBatchAnalysis(excelFile,saveRoot,mode,userCfg)
% mode='long' or 'amplitude'. Input folders contain ms_DFF_20Hz.mat.
if nargin<4, userCfg=struct(); end
c=dffAnalysisConfig(userCfg);
if ~any(strcmp(mode,{'long','amplitude'})), error('dffAnalysis:Mode','Use long or amplitude.'); end
rows=dffaSessions(excelFile);
if ~isfolder(saveRoot), mkdir(saveRoot); end
[~,tag]=fileparts(tempname(saveRoot));
runDir=fullfile(saveRoot,[mode '_' datestr(now,'yyyymmdd_HHMMSS') '_' tag]); mkdir(runDir);
summary=table(); report=struct('ExcelRow',{},'Path',{},'Status',{},'Message',{}); seen={};
for i=1:numel(rows)
    row=rows(i); status='failed'; message='';
    try
        [d,source]=dffaLoad(row.Path,c);
        [ok,attr]=fileattrib(source); if ~ok, error('Cannot resolve %s',source); end
        key=attr.Name; if ispc, key=lower(key); end
        if any(strcmp(seen,key))
            status='skipped_duplicate'; message='Same MAT file already analysed.';
        else
            fprintf('[%d/%d] row %d: %s\n',i,numel(rows),row.ExcelRow,source);
            r=dffaAnalyze(d,c); r.Source=source; r.Session=row;
            folder=fullfile(runDir,sprintf('row_%04d',row.ExcelRow)); mkdir(folder);
            save(fullfile(folder,'analysis_results.mat'),'r','-v7.3');
            dffaWrite(r.Events,fullfile(folder,'events'),c);
            if strcmp(mode,'long'), cells=r.LongCells; else, cells=r.Cells; end
            dffaWrite(cells,fullfile(folder,'per_cell'),c);
            one=summarize(r,row,mode); dffaWrite(one,fullfile(folder,'session_summary'),c);
            if width(summary)==0, summary=one; else, summary=[summary;one]; end %#ok<AGROW>
            dffaWrite(summary,fullfile(runDir,'ALL_session_summary'),c);
            seen{end+1}=key; %#ok<AGROW>
            status='complete';
            message=sprintf('%d cells, %d analysed frames; invalid samples not interpolated.',d.K,d.T);
        end
    catch ME
        message=getReport(ME,'extended','hyperlinks','off');
        fprintf(2,'Row %d failed: %s\n',row.ExcelRow,message);
    end
    report(end+1)=struct('ExcelRow',row.ExcelRow,'Path',row.Path,'Status',status,'Message',message); %#ok<AGROW>
    writetable(struct2table(report),fullfile(runDir,'processing_report.csv'));
end
save(fullfile(runDir,'batch_summary.mat'),'summary','report','c','excelFile');
fprintf('Results: %s\n',runDir);
end
function S=summarize(r,row,mode)
meta=table(row.ExcelRow,{row.Group},{row.Mouse},{row.Path}, ...
    'VariableNames',{'ExcelRow','Group','Mouse','Source'});
valid=r.Cells.ValidSeconds>0; K=height(r.Cells); Nv=sum(valid);
if strcmp(mode,'long')
    data=zeros(numel(r.Config.DurationSeconds),10);
    for j=1:numel(r.Config.DurationSeconds)
        th=r.Config.DurationSeconds(j); L=r.LongCells(r.LongCells.ThresholdSeconds==th,:);
        exposure=sum(L.ValidSeconds); count=sum(L.NumLongObserved,'omitnan');
        data(j,:)=[th,K,Nv,count,sum(L.NumLongComplete,'omitnan'), ...
            sum(L.NumLongObserved>0),ratio(100*sum(L.NumLongObserved>0),Nv), ...
            mean(L.LongFraction,'omitnan'),ratio(sum(L.LongSeconds,'omitnan'),exposure), ...
            ratio(60*count,exposure)];
        if Nv==0, data(j,4:end)=NaN; end
    end
    S=[repmat(meta,size(data,1),1),array2table(data,'VariableNames', ...
        {'ThresholdSeconds','NumCells','NumValidCells','TotalLongObserved','TotalLongComplete', ...
        'CellsWithLong','PercentCellsWithLong','MeanCellLongFraction','PooledCellTimeFraction','EventsPerCellMinute'})];
else
    C=r.Cells; E=r.Events; keep=E.PassAmplitude==1;
    data=[K,Nv,sum(C.NumAmplitudeEvents>0),sum(C.NumAmplitudeEvents,'omitnan'), ...
        sum(C.NumCompleteAmplitudeEvents,'omitnan'),mean(C.MeanAmplitude,'omitnan'), ...
        median(C.MeanAmplitude,'omitnan'),mean(E.Amplitude(keep),'omitnan'), ...
        mean(C.MeanAmplitudeComplete,'omitnan'),mean(C.MeanPeakAboveMean,'omitnan')];
    if Nv==0, data(3:end)=NaN; end
    S=[meta,array2table(data,'VariableNames',{'NumCells','NumValidCells','CellsWithEvents', ...
        'TotalAmplitudeEvents','TotalCompleteAmplitudeEvents','MeanOfCellMeanAmplitude', ...
        'MedianOfCellMeanAmplitude','PooledEventMeanAmplitude','MeanOfCellMeanAmplitudeComplete', ...
        'MeanOfCellMeanPeakAboveMean'})];
end
end
function v=ratio(a,b)
if b>0, v=a/b; else, v=NaN; end
end
