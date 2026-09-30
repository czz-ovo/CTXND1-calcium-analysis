function c = dffAnalysisConfig(user)
% Shared settings for plots, long-event counts and amplitudes.
c = struct('Fs',20,'SmoothFrames',1,'HighSigma',2,'LowSigma',0, ...
    'MinBelowSeconds',0.40,'MergeGapSeconds',0.30, ...
    'DurationSeconds',[5 10 15 20 30],'HighlightSeconds',10, ...
    'AnalysisSeconds',Inf,'PlotSeconds',600,'MinAmplitude',0, ...
    'NormalizePlotToOwnPeak',false,'AmplitudeBar',0.10,'ShowTraceLabels',false, ...
    'TimeBarSeconds',60,'FigureWidthInches',4,'WriteXlsx',true);
if nargin>0 && ~isempty(user)
    names = fieldnames(user);
    for i=1:numel(names)
        if ~isfield(c,names{i}), error('dffAnalysis:Option','Unknown option: %s',names{i}); end
        c.(names{i}) = user.(names{i});
    end
end
validateattributes(c.Fs,{'numeric'},{'scalar','real','finite','positive'});
if c.Fs~=20, error('dffAnalysis:Fs','This package expects the confirmed acquisition rate of 20 Hz.'); end
validateattributes(c.SmoothFrames,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(c.HighSigma,{'numeric'},{'scalar','real','finite'});
validateattributes(c.LowSigma,{'numeric'},{'scalar','real','finite'});
if c.HighSigma<=c.LowSigma, error('dffAnalysis:Threshold','HighSigma must exceed LowSigma.'); end
for name={'MinBelowSeconds','HighlightSeconds','PlotSeconds','AmplitudeBar','TimeBarSeconds','FigureWidthInches'}
    validateattributes(c.(name{1}),{'numeric'},{'scalar','real','finite','positive'});
end
validateattributes(c.DurationSeconds,{'numeric'},{'vector','real','finite','positive','nonempty'});
c.DurationSeconds=unique(c.DurationSeconds(:).','stable');
validateattributes(c.MergeGapSeconds,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(c.MinAmplitude,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(c.AnalysisSeconds,{'numeric'},{'scalar','real','positive','nonnan'});
if c.AnalysisSeconds*c.Fs<1, error('dffAnalysis:Window','Analysis window must contain at least one frame.'); end
validateattributes(c.NormalizePlotToOwnPeak,{'logical','numeric'},{'scalar','binary'});
validateattributes(c.ShowTraceLabels,{'logical','numeric'},{'scalar','binary'});
validateattributes(c.WriteXlsx,{'logical','numeric'},{'scalar','binary'});
end
