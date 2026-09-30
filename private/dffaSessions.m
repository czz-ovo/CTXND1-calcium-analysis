function rows = dffaSessions(excelFile)
% Excel: column A=folder or updated MAT path, B=group, C=mouse (optional).
raw=readcell(excelFile,'UseExcel',false);
rows=struct('ExcelRow',{},'Path',{},'Group',{},'Mouse',{});
headers={'folder','path','session_path','sessionpath','路径','文件夹','session_path, group_name, mouse_key'};
for i=1:size(raw,1)
    p=asText(raw{i,1});
    if isempty(p), continue; end
    if i==1 && any(strcmpi(p,headers)), continue; end
    if numel(p)>=2 && p(1)=='"' && p(end)=='"', p=p(2:end-1); end
    if isempty(regexp(p,'^([A-Za-z]:[\\/]|\\\\|/)','once'))
        error('dffAnalysis:Path','Excel row %d: column A must contain an absolute path.',i);
    end
    group=''; mouse='';
    if size(raw,2)>=2, group=asText(raw{i,2}); end
    if size(raw,2)>=3, mouse=asText(raw{i,3}); end
    rows(end+1)=struct('ExcelRow',i,'Path',p,'Group',group,'Mouse',mouse); %#ok<AGROW>
end
if isempty(rows), error('dffAnalysis:List','No recording paths in column A.'); end
end
function s=asText(x)
if ischar(x), s=strtrim(x);
elseif isstring(x) && isscalar(x) && ~ismissing(x), s=strtrim(char(x));
elseif isnumeric(x) && isscalar(x) && isfinite(x), s=num2str(x);
else, s='';
end
end
