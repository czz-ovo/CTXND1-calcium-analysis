function [segments,stats,yd] = dffDetectEvents(y,c)
% segments: [start,end,leftCensored,rightCensored], inclusive MATLAB indices.
% NaN/Inf split the trace. Never interpolate or merge across missing samples.
y=double(y(:)); valid=isfinite(y); yd=y;
edges=diff([false;valid;false]); bs=find(edges==1); be=find(edges==-1)-1;
for b=1:numel(bs)
    if c.SmoothFrames>1
        yd(bs(b):be(b))=movmean(y(bs(b):be(b)),c.SmoothFrames,'Endpoints','shrink');
    end
end
v=yd(valid);
stats=struct('Mu',NaN,'Sigma',NaN,'High',NaN,'Low',NaN, ...
    'ValidSeconds',numel(v)/c.Fs,'ValidFrames',numel(v));
segments=zeros(0,4);
if isempty(v), return; end
stats.Mu=mean(v); stats.Sigma=std(v,0);
stats.High=stats.Mu+c.HighSigma*stats.Sigma;
stats.Low=stats.Mu+c.LowSigma*stats.Sigma;
% A flat signal, including a positive constant, contains no detected event.
if numel(v)<2 || stats.Sigma<=64*eps(max(abs(v))), return; end
belowFrames=max(1,round(c.MinBelowSeconds*c.Fs));
gapFrames=max(0,round(c.MergeGapSeconds*c.Fs));
for b=1:numel(bs)
    active=false; below=0; start=0; local=zeros(0,4);
    for t=bs(b):be(b)
        if ~active
            if yd(t)>=stats.High, active=true; start=t; below=0; end
        elseif yd(t)<stats.Low
            below=below+1;
            if below>=belowFrames
                local(end+1,:)=[start,t-below,start==bs(b),0]; %#ok<AGROW>
                active=false; below=0;
            end
        else
            below=0;
        end
    end
    if active, local(end+1,:)=[start,be(b),start==bs(b),1]; end %#ok<AGROW>
    % Merge only within this finite block, retaining censoring at outer ends.
    merged=zeros(0,4);
    for j=1:size(local,1)
        if ~isempty(merged) && gapFrames>0 && local(j,1)-merged(end,2)-1<=gapFrames
            merged(end,2)=local(j,2); merged(end,4)=local(j,4);
        else
            merged(end+1,:)=local(j,:); %#ok<AGROW>
        end
    end
    segments=[segments;merged]; %#ok<AGROW>
end
end
