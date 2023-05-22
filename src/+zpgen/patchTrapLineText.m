function patchTrapLineText(tline, color)

cols = regexp(tline,'\s','split');
if length(cols{1}) >= 4 && (strcmp(cols{1}(1:4), 'Trap'))
    clock = str2double(cols{1}(6:end));
    x1 = str2double(cols{2});
    y1 = str2double(cols{3});
    x3 = str2double(cols{4});
    y3 = str2double(cols{5});
    x2 = str2double(cols{6});
    x4 = str2double(cols{7});
    
    % Compute r2, r1 
%     r1ave = 0.5 * (sqrt(x1^2 + y1^2) + sqrt(x2^2 + y2^2));
%     r2ave = 0.5 * (sqrt(x3^2 + y3^2) + sqrt(x4^2 + y3^2));
% 
%     fprintf('DeltaR: %0.3f, clockspeed: %d\n', r2ave - r1ave, clock);
%     
    patch([x1, x2, x3, x4, x1],[y1, y1, y3, y3, y1], color);
    text(x1, y1, sprintf('%d', clock))

end
