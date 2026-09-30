function result=dffaCombinedTables(C,L)
% One cell-recording is a unique CellUID; no cross-session registration.
groups=unique(C.Group); mice=unique(C(:,{'Group','Mouse'}),'rows');
C.GroupID=zeros(height(C),1); C.MouseID=C.GroupID;
C.GroupCellIndex=C.GroupID; C.MouseCellIndex=C.GroupID;
C.NumCellsInGroup=C.GroupID; C.NumCellsInMouse=C.GroupID;
C.NumMiceInGroup=C.GroupID;
MS=table(); GS=table();
for g=1:numel(groups)
    ix=strcmp(C.Group,groups{g}); n=sum(ix);
    C.GroupID(ix)=g; C.GroupCellIndex(ix)=(1:n)'; C.NumCellsInGroup(ix)=n;
    C.NumMiceInGroup(ix)=numel(unique(C.Mouse(ix)));
end
for m=1:height(mice)
    ix=strcmp(C.Group,mice.Group{m}) & strcmp(C.Mouse,mice.Mouse{m});
    n=sum(ix); C.MouseID(ix)=m; C.MouseCellIndex(ix)=(1:n)'; C.NumCellsInMouse(ix)=n;
end
[ok,loc]=ismember(L.CellUID,C.CellUID);
assert(all(ok) && numel(unique(C.CellUID))==height(C),'CellUID must uniquely identify each cell-recording.');
names={'GroupID','MouseID','GroupCellIndex','MouseCellIndex','NumCellsInGroup','NumCellsInMouse','NumMiceInGroup'};
L=[L,C(loc,names)];
for m=1:height(mice)
    one=makeSummary(C(C.MouseID==m,:),L(L.MouseID==m,:),false);
    if width(MS)==0, MS=one; else, MS=[MS;one]; end %#ok<AGROW>
end
for g=1:numel(groups)
    one=makeSummary(C(C.GroupID==g,:),L(L.GroupID==g,:),true);
    if width(GS)==0, GS=one; else, GS=[GS;one]; end %#ok<AGROW>
end
result=struct('AmplitudeHalfDecay',C,'Duration',L,'MouseSummary',MS,'GroupSummary',GS);
end
function S=makeSummary(C,L,isGroup)
thresholds=unique(L.ThresholdSeconds,'stable'); S=table();
for t=thresholds(:)'
    D=L(L.ThresholdSeconds==t,:); valid=C.ValidSeconds>0;
    A=struct(); A.Group=C.Group(1); A.GroupID=C.GroupID(1);
    A.Mouse={strjoin(unique(C.Mouse),'; ')};
    A.MouseID=C.MouseID(1); if isGroup, A.MouseID=NaN; end
    A.NumMice=numel(unique(C.Mouse)); A.NumSessions=numel(unique(C.ExcelRow));
    A.NumCells=height(C); A.NumValidCells=sum(valid);
    A.NumCellsWithAmplitude=sum(isfinite(C.MeanAmplitude));
    A.NumCellsWithAmplitudeExclEndCut=sum(isfinite(C.MeanAmplitudeExclEndCut));
    A.NumCellsWithAmplitudeComplete=sum(isfinite(C.MeanAmplitudeComplete));
    A.NumCellsWithHalfDecay=sum(isfinite(C.MeanHalfDecaySeconds));
    A.NumCellsWithHalfDecayExclEndCut=sum(isfinite(C.MeanHalfDecaySecondsExclEndCut));
    A.NumCellsWithHalfDecayComplete=sum(isfinite(C.MeanHalfDecaySecondsComplete));
    A.TotalAmplitudeEvents=sum(C.NumAmplitudeEvents,'omitnan');
    A.TotalEndCutAmplitudeEvents=sum(C.NumEndCutAmplitudeEvents,'omitnan');
    A.TotalCompleteAmplitudeEvents=sum(C.NumCompleteAmplitudeEvents,'omitnan');
    A.TotalHalfDecayObserved=sum(C.NumHalfDecayObserved,'omitnan');
    A.TotalHalfDecayMissing=sum(C.NumHalfDecayMissing,'omitnan');
    A.TotalHalfDecayObservedExclEndCut=sum(C.NumHalfDecayObservedExclEndCut,'omitnan');
    A.TotalHalfDecayMissingExclEndCut=sum(C.NumHalfDecayMissingExclEndCut,'omitnan');
    A.TotalHalfDecayObservedComplete=sum(C.NumHalfDecayObservedComplete,'omitnan');
    A.TotalHalfDecayMissingComplete=sum(C.NumHalfDecayMissingComplete,'omitnan');
    A.MeanCellAmplitude=mean(C.MeanAmplitude,'omitnan');
    A.MeanCellAmplitudePercent=100*A.MeanCellAmplitude;
    A.MeanCellAmplitudeExclEndCut=mean(C.MeanAmplitudeExclEndCut,'omitnan');
    A.MeanCellAmplitudeExclEndCutPercent=100*A.MeanCellAmplitudeExclEndCut;
    A.MeanCellAmplitudeComplete=mean(C.MeanAmplitudeComplete,'omitnan');
    A.MeanCellAmplitudeCompletePercent=100*A.MeanCellAmplitudeComplete;
    A.MeanCellHalfDecaySeconds=mean(C.MeanHalfDecaySeconds,'omitnan');
    A.MeanCellHalfDecaySecondsExclEndCut=mean(C.MeanHalfDecaySecondsExclEndCut,'omitnan');
    A.MeanCellHalfDecaySecondsComplete=mean(C.MeanHalfDecaySecondsComplete,'omitnan');
    A.ThresholdSeconds=t;
    A.CellsWithLong=sum(D.NumLongObserved>0);
    A.CellsWithLongExclEndCut=sum(D.NumLongExclEndCut>0);
    A.CellsWithLongComplete=sum(D.NumLongComplete>0);
    A.PercentCellsWithLong=ratio(100*A.CellsWithLong,A.NumValidCells);
    A.TotalLongObserved=sum(D.NumLongObserved,'omitnan');
    A.TotalLongExclEndCut=sum(D.NumLongExclEndCut,'omitnan');
    A.TotalLongComplete=sum(D.NumLongComplete,'omitnan');
    A.MeanCellLongPercent=mean(D.LongPercent,'omitnan');
    A.MeanCellLongPercentExclEndCut=mean(D.LongPercentExclEndCut,'omitnan');
    A.MeanCellCompleteLongPercent=100*mean(D.CompleteLongFraction,'omitnan');
    A.PooledCellTimeLongPercent=ratio(100*sum(D.LongSeconds,'omitnan'),sum(D.ValidSeconds));
    if A.NumValidCells==0
        fields=fieldnames(A);
        for k=1:numel(fields)
            if startsWith(fields{k},'Total') || strcmp(fields{k},'CellsWithLong'), A.(fields{k})=NaN; end
        end
    end
    one=struct2table(A);
    if width(S)==0, S=one; else, S=[S;one]; end %#ok<AGROW>
end
end
function v=ratio(a,b)
if b>0, v=a/b; else, v=NaN; end
end
