% Run this script; choose the session Excel list and output directory.
addpath(fileparts(mfilename('fullpath')));
cfg=dffAnalysisConfig();
cfg.DurationSeconds=[5 10 15 20 30];
cfg.AnalysisSeconds=Inf; % Entire recording. Use 600 to analyse only 10 min.
[file,folder]=uigetfile({'*.xlsx;*.xls','Session Excel list'});
if isequal(file,0), return; end
saveRoot=uigetdir(folder,'Choose output directory');
if isequal(saveRoot,0), return; end
[summary,runDir]=dffBatchAnalysis(fullfile(folder,file),saveRoot,'long',cfg);
disp(summary);
