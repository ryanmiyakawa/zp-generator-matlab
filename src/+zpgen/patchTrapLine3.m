function patchTrapLine(tline)

cols = regexp(tline,'\s','split');
if length(cols{1}) >= 4 && (strcmp(cols{1}(1:4), 'Trap'))
    clock = str2double(cols{});
    x1 = str2double(cols{2});
    y1 = str2double(cols{3});
    x3 = str2double(cols{4});
    y3 = str2double(cols{5});
    x2 = str2double(cols{6});
    x4 = str2double(cols{7});
    
    patch([x1, x2, x3, x4, x1],[y1, y1, y3, y3, y1], 'g');
    text(x1, y1, sprintf('%d', clock)) 

end
