function [x,y, invalid] = getTrapCM(tline)
x = 0;
y = 0;
invalid = 0;
cols = regexp(tline,'\s','split');
if length(cols{1}) >= 4 && (strcmp(cols{1}(1:4), 'Trap'))
    x1 = str2double(cols{2});
    y1 = str2double(cols{3});
    x3 = str2double(cols{4});
    y3 = str2double(cols{5});
    x2 = str2double(cols{6});
    x4 = str2double(cols{7});
    
    if any([x1, x2, x3, x4, y1, y3] < 0)
        fprintf('Warning: Trap %s has negative values\n', tline);
        invalid = 1;
    end
    if any([x1, x2, x3, x4, y1, y3] > 1e6)
        fprintf('Warning: Trap %s has out of bounds values\n', tline);
        invalid = 1;
    end
    
    x = mean([x1, x2, x3, x4]);
    y = mean([y1, y3]);
end
