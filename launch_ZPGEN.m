% Add zpgen src to path
clear all
mpm clearpath
mpm addpath

addpath(genpath('src'));

zpg = zpgen.uizpgen();
zpg.build();