function [result,runDir] = dffBatchCombined(excelFile,saveRoot,userCfg)
% Unified 20 Hz analysis. Group and Mouse labels are required for every row.
if nargin<3, userCfg=struct(); end
c=dffAnalysisConfig(userCfg); rows=dffaSessions(excelFile);
for i=1:numel(rows)
    if isempty(rows(i).Group) || isempty(rows(i).Mouse)
        error('dffAnalysis:Labels','Excel row %d: fill column B (Group) and column C (Mouse).',rows(i).ExcelRow);
    end
end
if ~isfolder(saveRoot), mkdir(saveRoot); end
[~,tag]=fileparts(tempname(saveRoot));
runDir=fullfile(saveRoot,['combined_' datestr(now,'yyyymmdd_HHMMSS') '_' tag]);
mkdir(runDir);
C=table(); L=table(); report=struct('ExcelRow',{},'Group',{},'Mouse',{},'Path',{},'Status',{},'Message',{});
seen={}; successfulRows=[];
for i=1:numel(rows)
    row=rows(i); status='failed'; message='';
    try
        [d,source]=dffaLoad(row.Path,c);
        [ok,attr]=fileattrib(source); if ~ok, error('Cannot resolve %s',source); end
        key=attr.Name; if ispc, key=lower(key); end
        if any(strcmp(seen,key))
            status='skipped_duplicate'; message='Same MAT already analysed; its first successful labels are used.';
        else
            fprintf('[%d/%d] %s / %s: %s\n',i,numel(rows),row.Group,row.Mouse,source);
            r=dffaAnalyze(d,c); r.Source=source; r.Session=row;
            r.Cells=addMeta(r.Cells,row,source); r.LongCells=addMeta(r.LongCells,row,source);
            r.Events=addMeta(r.Events,row,source);
            folder=fullfile(runDir,sprintf('row_%04d',row.ExcelRow)); mkdir(folder);
            save(fullfile(folder,'analysis_results.mat'),'r','-v7.3');
            % Event-level audit includes amplitude, half-decay and duration.
            writetable(r.Events,fullfile(folder,'events.csv'));
            if width(C)==0, C=r.Cells; L=r.LongCells;
            else, C=[C;r.Cells]; L=[L;r.LongCells]; end %#ok<AGROW>
            seen{end+1}=key; successfulRows(end+1)=row.ExcelRow; %#ok<AGROW>
            status='complete'; message=sprintf('%d cell-recordings, %d frames.',d.K,d.T);
        end
    catch ME
        message=getReport(ME,'extended','hyperlinks','off');
        fprintf(2,'Row %d failed: %s\n',row.ExcelRow,message);
    end
    report(end+1)=struct('ExcelRow',row.ExcelRow,'Group',row.Group,'Mouse',row.Mouse, ...
        'Path',row.Path,'Status',status,'Message',message); %#ok<AGROW>
    writetable(struct2table(report),fullfile(runDir,'processing_report.csv'));
end
report=struct2table(report);
if width(C)==0
    error('dffAnalysis:NoSuccess','No recording succeeded. Read %s',fullfile(runDir,'processing_report.csv'));
end
result=dffaCombinedTables(C,L);
result.Report=report; result.Config=c; result.ExcelFile=excelFile;
result.SuccessfulExcelRows=successfulRows;
save(fullfile(runDir,'combined_results.mat'),'result','-v7.3');
dffaCombinedExport(result,runDir,c);
if any(~strcmp(report.Status,'complete'))
    warning('dffAnalysis:Partial','Some rows failed or were skipped. Combined tables include successful rows only; inspect processing_report.csv.');
end
fprintf('Saved combined analysis: %s\n',runDir);
end
function T=addMeta(T,row,source)
n=height(T);
uid=arrayfun(@(k)sprintf('R%04d_C%05d',row.ExcelRow,k),T.Neuron,'UniformOutput',false);
meta=table(repmat({row.Group},n,1),repmat({row.Mouse},n,1), ...
    repmat(row.ExcelRow,n,1),uid,repmat({source},n,1), ...
    'VariableNames',{'Group','Mouse','ExcelRow','CellUID','Source'});
T=[meta,T];
end
