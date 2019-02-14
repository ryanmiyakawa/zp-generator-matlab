% Add zpgen src to path
addpath(genpath('src'));

% Add MIC to path
cMICDir = fullfile('vendor', 'github', 'matlab-instrument-control', 'src');
addpath(genpath(cMICDir));


zpg = zpgen.uizpgen();
zpg.build();