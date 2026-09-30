function [d,source] = dffaLoad(path,c)
path=char(path);
if isfolder(path), path=fullfile(path,'ms_DFF_20Hz.mat'); end
if ~isfile(path), error('dffAnalysis:MissingFile','Missing updated dFF file: %s',path); end
s=load(path,'ms');
if ~isfield(s,'ms'), error('dffAnalysis:MS','Missing ms variable: %s',path); end
m=s.ms;
for f={'dFF','F0','dFFInfo'}
    if ~isfield(m,f{1}), error('dffAnalysis:Field','Missing ms.%s. Run the dFF conversion first.',f{1}); end
end
if ~isfield(m.dFFInfo,'Options') || ~isfield(m.dFFInfo.Options,'Fs') || m.dFFInfo.Options.Fs~=c.Fs
    error('dffAnalysis:Fs','Saved dFF sampling rate does not match 20 Hz. Do not use ms.FPS.');
end
if ~isfield(m.dFFInfo,'Method') || ~strcmp(m.dFFInfo.Method,'CNMFE_background_normalized')
    error('dffAnalysis:Method','This package expects the previously generated CNMFE_background_normalized dFF.');
end
if ~isnumeric(m.dFF) || ~isreal(m.dFF) || ~ismatrix(m.dFF) || isempty(m.dFF) || ...
        ~isnumeric(m.F0) || ~isreal(m.F0) || ~isequal(size(m.dFF),size(m.F0))
    error('dffAnalysis:Shape','dFF and F0 must have matching frames-by-cells dimensions.');
end
N=min(size(m.dFF,1),floor(c.AnalysisSeconds*c.Fs));
d.Y=double(m.dFF(1:N,:)); d.F0=double(m.F0(1:N,:));
valid=isfinite(d.Y) & isfinite(d.F0) & d.F0>0;
if isfield(m,'dFFValid')
    if ~isequal(size(m.dFFValid),size(m.dFF)), error('dffAnalysis:Mask','dFFValid dimensions disagree.'); end
    valid=valid & isfinite(double(m.dFFValid(1:N,:))) & m.dFFValid(1:N,:)~=0;
end
d.Y(~valid)=NaN; d.F0(~valid)=NaN;
d.Valid=valid; d.T=N; d.K=size(d.Y,2); d.FullFrames=size(m.dFF,1);
d.DFFInfo=m.dFFInfo; d.Time=(0:N-1)'/c.Fs;
source=path;
end
