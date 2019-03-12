fid1 = fopen('Very_Small_zp_NWA_multi.nwa');

fid2 = fopen('Very_Small_zp_NWA_multi_multifield.nwa');

bytes1 = fread(fid1, 200);
bytes = fread(fid2, 300);
% Header nl = 10



