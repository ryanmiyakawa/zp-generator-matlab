function writeLog(logPath, elements, isHeader, fopenTag)
nl = java.lang.System.getProperty('line.separator').char;

if nargin < 3
    isHeader = false;
end
if nargin < 4
    fopenTag = 'a';
end

fid = fopen(logPath, fopenTag);

if isHeader
    str = 'Time stamp';
else
    str = datestr(now, 31);
end

if iscell(elements)
    if length(elements) == 1
        str = sprintf('%s,%s', str, elements{1});
    else
        for k = 1:length(elements)
            str = sprintf('%s, %s', str, elements{k});
            
            if k == length(elements)
                str = sprintf('%s', str);
            end
        end
    end
else
    str = sprintf('%s,%s', str, elements);
end


fwrite(fid, str);
fprintf(fid, nl);
fclose(fid);

