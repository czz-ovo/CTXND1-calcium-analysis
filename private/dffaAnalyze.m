function r = dffaAnalyze(d,c)
% All three public programs use dffaCell/dffDetectEvents.
cellNames={'Neuron','ValidSeconds','ValidFraction','Mu','Sigma','ThrHi','ThrLo', ...
    'NumEventsDetected','NumAmplitudeEvents','NumCompleteAmplitudeEvents','NumCensoredEvents', ...
    'MeanAmplitude','MedianAmplitude','MaxAmplitude','MeanAmplitudeComplete', ...
    'MedianAmplitudeComplete','MeanPeakAboveMean'};
longNames={'Neuron','ThresholdSeconds','ValidSeconds','NumLongObserved','NumLongComplete', ...
    'LongSeconds','LongFraction','LongPercent','LongEventsPerMinute','LongestSeconds', ...
    'CompleteLongSeconds','CompleteLongFraction'};
cellData=nan(d.K,numel(cellNames)); longData=nan(d.K*numel(c.DurationSeconds),numel(longNames));
events=cell(d.K,1); row=0;
for n=1:d.K
    [E,s]=dffaCell(d.Y(:,n),d.F0(:,n),c);
    E.Neuron=repmat(n,height(E),1); events{n}=E;
    keep=E.PassAmplitude==1; complete=keep & E.Complete==1;
    a=E.Amplitude(keep); ac=E.Amplitude(complete);
    cellData(n,:)=[n,s.ValidSeconds,s.ValidFrames/d.T,s.Mu,s.Sigma,s.High,s.Low, ...
        height(E),sum(keep),sum(complete),sum(E.Complete==0), ...
        avg(a),med(a),maximum(a),avg(ac),med(ac),avg(E.PeakAboveMean(keep))];
    for threshold=c.DurationSeconds
        row=row+1; long=E.DurationSeconds>=round(threshold*c.Fs)/c.Fs;
        comp=long & E.Complete==1;
        seconds=sum(E.DurationSeconds(long)); completeSeconds=sum(E.DurationSeconds(comp));
        longest=0; if any(long), longest=max(E.DurationSeconds(long)); end
        longData(row,:)=[n,threshold,s.ValidSeconds,sum(long),sum(comp),seconds, ...
            divide(seconds,s.ValidSeconds),100*divide(seconds,s.ValidSeconds), ...
            divide(sum(long)*60,s.ValidSeconds),longest,completeSeconds,divide(completeSeconds,s.ValidSeconds)];
        if s.ValidFrames==0, longData(row,4:end)=NaN; end
    end
    if s.ValidFrames==0, cellData(n,8:end)=NaN; end
end
r.Events=vertcat(events{:}); r.Cells=array2table(cellData,'VariableNames',cellNames);
r.LongCells=array2table(longData,'VariableNames',longNames);
r.Events.EndedByRecordingEnd=r.Events.EndedByTraceEnd & d.T==d.FullFrames;
r.Events.EndedByAnalysisEnd=r.Events.EndedByTraceEnd & d.T<d.FullFrames;
% Three separately labelled selections: all, excluding end-cut, complete.
extraNames={'NumEndCutAmplitudeEvents','NumHalfDecayObserved','NumHalfDecayMissing', ...
    'MeanHalfDecaySeconds','MedianHalfDecaySeconds','NumAmplitudeEventsExclEndCut', ...
    'MeanAmplitudeExclEndCut','NumHalfDecayObservedExclEndCut','NumHalfDecayMissingExclEndCut', ...
    'MeanHalfDecaySecondsExclEndCut','MedianHalfDecaySecondsExclEndCut', ...
    'NumHalfDecayObservedComplete','NumHalfDecayMissingComplete', ...
    'MeanHalfDecaySecondsComplete','MedianHalfDecaySecondsComplete', ...
    'MeanEventDurationSeconds','MeanEventDurationSecondsExclEndCut','MeanEventDurationSecondsComplete', ...
    'MeanAmplitudePercent','MeanAmplitudeExclEndCutPercent','MeanAmplitudeCompletePercent'};
extra=nan(d.K,numel(extraNames));
for n=1:d.K
    E=r.Events(r.Events.Neuron==n & r.Events.PassAmplitude==1,:);
    X=E(~E.EndedByTraceEnd,:); Q=E(E.Complete==1,:);
    ha=E.HalfDecaySeconds(isfinite(E.HalfDecaySeconds));
    hx=X.HalfDecaySeconds(isfinite(X.HalfDecaySeconds));
    hq=Q.HalfDecaySeconds(isfinite(Q.HalfDecaySeconds));
    extra(n,:)=[sum(E.EndedByTraceEnd),numel(ha),height(E)-numel(ha),avg(ha),med(ha), ...
        height(X),avg(X.Amplitude),numel(hx),height(X)-numel(hx),avg(hx),med(hx), ...
        numel(hq),height(Q)-numel(hq),avg(hq),med(hq), ...
        avg(E.DurationSeconds),avg(X.DurationSeconds),avg(Q.DurationSeconds), ...
        100*avg(E.Amplitude),100*avg(X.Amplitude),100*avg(Q.Amplitude)];
    if r.Cells.ValidSeconds(n)==0, extra(n,:)=NaN; end
end
r.Cells=[r.Cells,array2table(extra,'VariableNames',extraNames)];
extraLong=nan(height(r.LongCells),5);
for j=1:height(r.LongCells)
    n=r.LongCells.Neuron(j); th=r.LongCells.ThresholdSeconds(j);
    E=r.Events(r.Events.Neuron==n,:);
    X=E(~E.EndedByTraceEnd & E.DurationSeconds>=round(th*c.Fs)/c.Fs,:);
    if r.Cells.ValidSeconds(n)>0
        seconds=sum(X.DurationSeconds); fraction=seconds/r.Cells.ValidSeconds(n);
        extraLong(j,:)=[height(X),seconds,fraction,100*fraction,height(X)*60/r.Cells.ValidSeconds(n)];
    end
end
r.LongCells=[r.LongCells,array2table(extraLong,'VariableNames', ...
    {'NumLongExclEndCut','LongSecondsExclEndCut','LongFractionExclEndCut', ...
    'LongPercentExclEndCut','LongEventsPerMinuteExclEndCut'})];
r.Config=c; r.SourceDFFInfo=d.DFFInfo;
r.AnalysisFrames=d.T; r.FullRecordingFrames=d.FullFrames;
r.Method='CNMF-E apparent dFF; event thresholds from mean/std, amplitude from normalized zero';
end
function v=avg(x)
if isempty(x), v=NaN; else, v=mean(x); end
end
function v=med(x)
if isempty(x), v=NaN; else, v=median(x); end
end
function v=maximum(x)
if isempty(x), v=NaN; else, v=max(x); end
end
function v=divide(a,b)
if b>0, v=a/b; else, v=NaN; end
end
