function test_calcium_analysis()
% Pure numeric regression tests; no CNMF-E or parallel pool required.
c=dffAnalysisConfig();
y=zeros(3000,1); y(101:300)=.2; % exactly 200 frames = 10 s
[E,s]=dffaCell(y,100*ones(size(y)),c);
assert(height(E)==1 && E.StartFrame==101 && E.EndFrame==300);
assert(E.DurationSeconds==10 && E.Complete==1 && E.Amplitude==.2);
assert(E.AmplitudePercent==20 && E.F0AtPeak==100 && E.DeltaFAtPeak==20);
assert(abs(E.PeakAboveMean-(.2-mean(y)))<1e-14 && s.ValidSeconds==150);
d=struct('Y',[y,zeros(size(y)),nan(size(y))],'F0',100*ones(3000,3), ...
    'T',3000,'K',3,'FullFrames',3000,'DFFInfo',struct());
r=dffaAnalyze(d,c); L=r.LongCells;
row=L.Neuron==1 & L.ThresholdSeconds==10;
assert(L.NumLongObserved(row)==1 && abs(L.LongFraction(row)-10/150)<1e-14);
assert(all(L.NumLongObserved(L.Neuron==2)==0));
assert(all(isnan(L.NumLongObserved(L.Neuron==3))));
assert(r.Cells.NumEventsDetected(2)==0 && isnan(r.Cells.MeanAmplitude(2)));
% 199 frames fails >= 10 s; exactly 200 passes.
y(300)=0; E=dffaCell(y,ones(size(y)),c); assert(E.DurationSeconds<10);
% Seven subthreshold frames are bridged; eight terminate an event.
y=zeros(3000,1); y(101:400)=.2; y(201:207)=0;
E=dffaCell(y,ones(size(y)),c); assert(height(E)==1 && E.DurationSeconds==15);
y(208)=0; E=dffaCell(y,ones(size(y)),c);
assert(height(E)==2 && E.EndFrame(1)==200 && E.StartFrame(2)==209);
% Missing samples force a split even when the merge setting is increased.
y=zeros(1000,1); y(101:121)=.2; y(111)=NaN; c.MergeGapSeconds=1;
E=dffaCell(y,ones(size(y)),c);
assert(height(E)==2 && E.RightCensored(1)==1 && E.LeftCensored(2)==1);
assert(all(E.Complete==0));
c=dffAnalysisConfig();
y=zeros(1000,1); y(1:20)=.2; y(951:end)=.2;
E=dffaCell(y,ones(size(y)),c);
assert(E.LeftCensored(1)==1 && E.RightCensored(2)==1);
[seg,~]=dffDetectEvents(ones(100,1),c); assert(isempty(seg));
% Event intervals are computed from full data, independent of plot cropping.
y=zeros(3000,1); y(190:410)=.2; c.PlotSeconds=10;
E=dffaCell(y,ones(size(y)),c); assert(E.DurationSeconds==221/20);
fprintf('All numeric calcium-analysis tests passed.\n');
end
