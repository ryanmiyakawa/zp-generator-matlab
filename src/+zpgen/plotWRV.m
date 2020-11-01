function plotWRV(skip)

if nargin == 0
    skip = 1;
end


[d, p] = uigetfile('*.wrv');
fid = fopen([p, d], 'r');

idx = 0;
while 1
    idx = idx + 1;
    if (skip > 1 && mod(idx, skip) ~= 0)
        continue
    end
    
    tline = fgetl(fid);
    
    if ~ischar(tline), break, end
    zpgen.patchTrapLine(tline);    
end
fclose(fid);


