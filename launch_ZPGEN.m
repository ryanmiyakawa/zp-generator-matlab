% Add zpgen src to path

mpm clearpath
mpm addpath

addpath(genpath('src'));




zpg = zpgen.uizpgen();
zpg.build();