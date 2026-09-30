% One Excel list: A=Folder, B=Group, C=Mouse. B and C required in this mode.
% Output: amplitude + half-decay together, duration in a separate sheet.
addpath(fileparts(mfilename('fullpath')),'-begin');
cfg=dffAnalysisConfig();
cfg.MinAmplitude=0;
cfg.AnalysisSeconds=Inf;
cfg.DurationSeconds=[5 10 15 20 30];
[file,folder]=uigetfile({'*.xlsx;*.xls','Session Excel list'});
if isequal(file,0), return; end
saveRoot=uigetdir(folder,'Choose output directory');
if isequal(saveRoot,0), return; end
[result,runDir]=dffBatchCombined(fullfile(folder,file),saveRoot,cfg);
disp(result.MouseSummary);
fprintf('Combined results: %s\n',runDir);
