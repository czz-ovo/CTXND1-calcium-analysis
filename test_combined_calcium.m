function test_combined_calcium(runExcelIntegration)
% Run test_combined_calcium(true) for MAT/Excel/grouping round-trip tests.
if nargin<1, runExcelIntegration=false; end
test_calcium_analysis();
c=dffAnalysisConfig();
% Analytic exponential t_half = tau*log(2); interpolation error < 0.2 ms.
tau=2; y=exp(-(0:200)'/c.Fs/tau);
[h,f]=dffHalfDecay(y,1,numel(y),c.Fs);
assert(abs(h-tau*log(2))<2e-4 && abs(h-(f-1)/20)<1e-12);
assert(isnan(dffHalfDecay([1;.8;NaN;.3],1,4,20)));
assert(isnan(dffHalfDecay([1;.8;.3],1,2,20))); % next event boundary
assert(abs(dffHalfDecay([1;.8;.4],1,3,20)-.0875)<1e-12);
% Complete event drops below half only AFTER the detected last active frame.
y=zeros(3000,1); y(101:300)=.2;
E=dffaCell(y,ones(size(y)),c);
assert(E.EndFrame==300 && abs(E.HalfDecayCrossFrame-300.5)<1e-12);
% End-cut event can have observed half-decay OR an unobserved half-decay.
Y=zeros(1000,5); Y(951:end,1)=linspace(1,.25,50)'; Y(951:end,2)=.8;
Y(101:120,3)=.5; Y(:,5)=NaN;
d=struct('Y',Y,'F0',ones(size(Y)),'T',1000,'K',5,'FullFrames',1000,'DFFInfo',struct());
r=dffaAnalyze(d,c); C=r.Cells;
assert(C.NumHalfDecayObserved(1)==1 && isfinite(C.MeanHalfDecaySeconds(1)));
assert(C.NumHalfDecayObserved(2)==0 && C.NumHalfDecayMissing(2)==1);
assert(all(isnan(C.MeanHalfDecaySecondsExclEndCut(1:2))));
assert(all(C.NumEndCutAmplitudeEvents(1:2)==1));
assert(C.NumHalfDecayObservedComplete(3)==1);
assert(C.NumAmplitudeEvents(4)==0 && isnan(C.MeanHalfDecaySeconds(4)));
assert(isnan(C.NumHalfDecayObserved(5)));
assert(sum(r.Events.EndedByRecordingEnd)==2 && ~any(r.Events.EndedByAnalysisEnd));
d.FullFrames=1200; r2=dffaAnalyze(d,c);
assert(sum(r2.Events.EndedByAnalysisEnd)==2 && ~any(r2.Events.EndedByRecordingEnd));
fprintf('Half-decay boundary and selection tests passed.\n');
if ~runExcelIntegration, return; end
tmp=tempname; mkdir(tmp);
% Keep fixtures/results for inspection rather than deleting user data.
paths=cell(4,1); groups={'AD';'AD';'AD';'WT'}; mice={'NC1';'NC1';'NC2';'WT1'};
for j=1:4
    folder=fullfile(tmp,sprintf('session_%d',j)); mkdir(folder);
    ms=struct('dFF',Y,'F0',ones(size(Y)),'dFFInfo', ...
        struct('Options',struct('Fs',20),'Method','CNMFE_background_normalized')); %#ok<NASGU>
    save(fullfile(folder,'ms_DFF_20Hz.mat'),'ms','-v7.3'); paths{j}=folder;
end
input=table(paths,groups,mice,'VariableNames',{'Folder','Group','Mouse'});
% Duplicate MAT row and one missing MAT row exercise batch partial results.
input=[input;input(1,:);table({fullfile(tmp,'missing')},{'AD'},{'NC3'}, ...
    'VariableNames',{'Folder','Group','Mouse'})];
list=fullfile(tmp,'input.xlsx'); writetable(input,list);
[R,output]=dffBatchCombined(list,tmp,c);
assert(height(R.AmplitudeHalfDecay)==20 && height(R.Duration)==100);
assert(height(unique(R.AmplitudeHalfDecay(:,{'Group','Mouse'}),'rows'))==3);
assert(all(R.AmplitudeHalfDecay.NumCellsInGroup(strcmp(R.AmplitudeHalfDecay.Group,'AD'))==15));
assert(all(R.AmplitudeHalfDecay.NumCellsInMouse(strcmp(R.AmplitudeHalfDecay.Mouse,'NC1'))==10));
assert(sum(strcmp(R.Report.Status,'skipped_duplicate'))==1 && sum(strcmp(R.Report.Status,'failed'))==1);
for id=unique(R.AmplitudeHalfDecay.MouseID)'
    assert(isfile(fullfile(output,'by_mouse',sprintf('mouse_%03d.xlsx',id))));
end
A=readtable(fullfile(output,'ALL_cells.xlsx'),'Sheet','Amplitude_HalfDecay');
L=readtable(fullfile(output,'ALL_cells.xlsx'),'Sheet','Duration');
assert(height(A)==20 && height(L)==100);
assert(ismember('MeanHalfDecaySecondsExclEndCut',A.Properties.VariableNames));
assert(ismember('Mouse',L.Properties.VariableNames));
assert(sum(isnan(A.MeanHalfDecaySeconds))==sum(isnan(R.AmplitudeHalfDecay.MeanHalfDecaySeconds)));
fprintf('MAT/Excel round-trip and group tests passed. Fixtures retained: %s\n',tmp);
end
