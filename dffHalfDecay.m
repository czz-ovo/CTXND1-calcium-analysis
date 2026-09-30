function [seconds,crossFrame,level,stopFrame] = dffHalfDecay(y,peakFrame,stopFrame,Fs)
% Observed half-decay from the event peak toward normalized dFF zero.
% First downward crossing; linear interpolation, no exponential fitting.
% Caller bounds the search before the next detected event. Never cross NaN.
y=y(:); seconds=NaN; crossFrame=NaN; level=y(peakFrame)/2;
stopFrame=min(stopFrame,numel(y));
if ~isfinite(level) || level<=0 || stopFrame<=peakFrame, return; end
v=y(peakFrame:stopFrame); bad=find(~isfinite(v),1);
if ~isempty(bad), stopFrame=peakFrame+bad-2; v=v(1:bad-1); end
k=find(v<=level,1);
if isempty(k) || k==1, return; end
fraction=(v(k-1)-level)/(v(k-1)-v(k));
crossFrame=peakFrame+k-2+fraction;
seconds=(crossFrame-peakFrame)/Fs;
end
