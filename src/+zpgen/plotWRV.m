function plotWRV(skip, method)

if nargin < 1
    skip = 1;
end

if nargin < 2
    method = 'patch';
end



[d, p] = uigetfile('*.wrv*');
fid = fopen([p, d], 'r');

idx = 0;
trapCt = 0;

xPlotCoords = [];
yPlotCoords = [];

xPlotCoordsI = [];
yPlotCoordsI = [];

fieldOffsetX = 0;
fieldOffsetY = 0;

while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    
    % check for field
    if (length(tline) > 5 && strcmp(tline(1:5), 'field'))
       cols = regexp(tline,'\s','split');
       fieldOffsetX = str2double(cols{2}) * 800000;
       fieldOffsetY = str2double(cols{3}) * 800000;
    end
    
    % Count traps:
    if (length(tline) > 5 && strcmp(tline(1:4), 'Trap'))
       trapCt = trapCt + 1;
    else
        continue
    end
    

    idx = idx + 1;
    if (skip > 1 && mod(idx, skip) ~= 0)
        continue
    end
    
    switch method
        case 'text'
            if (mod(idx, 3) == 0)
                zpgen.patchTrapLineText(tline);
            else
                zpgen.patchTrapLine(tline);
            end
        case 'patch'
            zpgen.patchTrapLine(tline);   
        case 'plot'
            [x, y, invalid] = zpgen.getTrapCM(tline);
            
            if invalid
                xPlotCoordsI(end+1) = x + fieldOffsetX; %#ok<*AGROW>
                yPlotCoordsI(end+1) = y + fieldOffsetY;
            else
                xPlotCoords(end+1) = x + fieldOffsetX; %#ok<*AGROW>
                yPlotCoords(end+1) = y + fieldOffsetY;
            end
            
    end
%     
%     if xPlotCoords(end) == 0 || yPlotCoords(end) == 0
%         fprintf('Zero idx: %s\n', tline)
%     end
    
end
fclose(fid);


if strcmp(method, 'plot')
   plot(xPlotCoords, yPlotCoords, 'bo');
   plot(xPlotCoordsI, yPlotCoordsI, 'ro');
end

fprintf('Plotted WRV %s with %d shapes\n', [p, d], trapCt);


