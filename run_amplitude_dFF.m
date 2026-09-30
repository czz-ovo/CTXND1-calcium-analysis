% Amplitude=event peak ms.dFF relative to normalized zero; units are ratios.
% PeakAboveMean is also exported for comparison with the original script.
addpath(fileparts(mfilename('fullpath')));
cfg=dffAnalysisConfig();
cfg.MinAmplitude=0;
cfg.AnalysisSeconds=Inf;
[file,folder]=uigetfile({'*.xlsx;*.xls','Session Excel list'});
if isequal(file,0), return; end
saveRoot=uigetdir(folder,'Choose output directory');
if isequal(saveRoot,0), return; end
[summary,runDir]=dffBatchAnalysis(fullfile(folder,file),saveRoot,'amplitude',cfg);
disp(summary);
