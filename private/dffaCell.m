function [E,s] = dffaCell(y,F0,c)
[seg,s]=dffDetectEvents(y,c);
names={'EventID','StartFrame','EndFrame','StartSeconds','EndExclusiveSeconds', ...
    'DurationSeconds','PeakFrame','PeakDFF','Amplitude','AmplitudePercent', ...
    'PeakAboveMean','F0AtPeak','DeltaFAtPeak','LeftCensored','RightCensored','Complete','PassAmplitude', ...
    'HalfDecaySeconds','HalfDecayObserved','HalfDecayCrossFrame','HalfDecayLevel', ...
    'HalfDecaySearchEndFrame','HalfDecayBaseline','EndedByTraceEnd','EndedByMissingData'};
data=zeros(size(seg,1),numel(names));
for j=1:size(seg,1)
    st=seg(j,1); en=seg(j,2);
    [peak,k]=max(y(st:en)); k=k+st-1;
    amp=peak; % Zero is the reference of the ALREADY normalized delta signal.
    stop=numel(y);
    if j<size(seg,1), stop=seg(j+1,1)-1; end
    [half,halfFrame,halfLevel,stop]=dffHalfDecay(y,k,stop,c.Fs);
    endCut=seg(j,4)==1 && en==numel(y);
    missingCut=seg(j,4)==1 && en<numel(y);
    data(j,:)=[j,st,en,(st-1)/c.Fs,en/c.Fs,(en-st+1)/c.Fs,k,peak,amp,100*amp, ...
        peak-s.Mu,F0(k),peak*F0(k),seg(j,3),seg(j,4),~any(seg(j,3:4)),amp>c.MinAmplitude, ...
        half,isfinite(half),halfFrame,halfLevel,stop,0,endCut,missingCut];
end
E=array2table(data,'VariableNames',names);
end
