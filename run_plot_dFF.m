% Edit the selected cells below, then run and choose Excel/output directory.
addpath(fileparts(mfilename('fullpath')));
cfg=dffAnalysisConfig();
cfg.PlotSeconds=600;
cfg.AnalysisSeconds=Inf; % Same detection window as the two analysis scripts.
cfg.HighlightSeconds=10; % >= 10 s, matching the active original code.
cfg.NormalizePlotToOwnPeak=false; % true restores the original display scaling.
cfg.AmplitudeBar=0.10; % 0.10 dFF = 10%; used when normalization is false.
cfg.ShowTraceLabels=false; % Add mouse/cell labels manually after exporting.
% All groups share figure/axes dimensions and y limits: equal dFF = equal length.
% To DISPLAY a 100% scale bar, use cfg.AmplitudeBar=1.0.
% Group, Mouse, CellID. Optional column 4 specifies the Excel row if ambiguous.
cell_info={
    'WT','WT2',1; 'WT','WT2',59; 'WT','WT2',121;
    'WT','WT',18; 'WT','WT',215;
    'AD','NC1',32; 'AD','NC1',22; 'AD','NC1',35; 'AD','NC1',83; 'AD','NC2',94;
    'OE','OE1',99; 'OE','OE1',5; 'OE','OE1',203; 'OE','OE1',266; 'OE','OE1',361;
};
[file,folder]=uigetfile({'*.xlsx;*.xls','Session Excel list'});
if isequal(file,0), return; end
saveRoot=uigetdir(folder,'Choose output directory');
if isequal(saveRoot,0), return; end
runDir=plot_calcium_dFF(fullfile(folder,file),cell_info,saveRoot,cfg);
