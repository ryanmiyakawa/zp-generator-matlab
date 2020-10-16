function plotWRV


[d, p] = uigetfile('*.wrv');
fid = fopen([p, d], 'r');


while 1
    tline = fgetl(fid);
    
    if ~ischar(tline), break, end
    zpgen.patchTrapLine(tline);
    
    
    
%     disp(tline)
end
fclose(fid);


