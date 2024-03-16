

% Let's say we have a standard zone plate tha t is on axis.


%% Testing function 1:
lambda_nm = 13.5;
na = 0.33;
T_MIN_nm = lambda_nm/na;
T_MIN_um = T_MIN_nm / 1000;
lambda_um = lambda_nm / 1000;


fx = 1/T_MIN_um * 0.5;
fy = 0;%1/T_MIN_um * 0.5;

% n = normal vector of zone plate:


% ======== 1.1 UNIT TEST nominal zone plate
beta = 0.0;
n = [-sin(beta), 0, cos(beta)];

% Vector
p = 1e3;
u = p*[0, 0, 1];

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, u, lambda_um);


% geometric calculation:
rx = tan(asin(lambda_nm/T_MIN_nm / 2));

fprintf('UNIT TEST 1.1 (nominal zp): Geometric: %0.3f, fn1: %0.3f\n', rx, r(1)/1000)


% ======== 1.2 UNIT TEST tilted zone plate zone plate
beta = 0.1;
n = [-sin(beta), 0, cos(beta)];

% Vector
p = 1e3;
u = p*[0, 0, 1];

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, u, lambda_um);


% geometric calculation:
rx = tan(asin(lambda_nm/T_MIN_nm / 2));

fprintf('UNIT TEST 1.2 (tilt-x zp): Geometric: %0.3f, fn1: %0.3f\n', rx, r(1)/1000)


% ======== 1.3 UNIT TEST y-tilted
n = [0, -sin(beta), cos(beta)];

% Vector
p = 1e3;
u = p*[0, 0, 1];

fy = 1/T_MIN_um * 0.5;
fx = 0;

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, u, lambda_um);


% geometric calculation:
rx = tan(asin(lambda_nm/T_MIN_nm / 2));

fprintf('UNIT TEST 1.3 (tilt-y zp): Geometric: %0.3f, fn1: %0.3f\n', rx, r(2)/1000)


% ======== 1.4 UNIT TEST nominal zone plate
fx = 1/T_MIN_um * 0.5;
fy = 0;%1/T_MIN_um * 0.5;

beta = 0.0;
n = [-sin(beta), 0, cos(beta)];

% Vector
p = 1e3;
u = p*[0, 0, -1];

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, u, lambda_um);


% geometric calculation:
rx = tan(asin(lambda_nm/T_MIN_nm / 2));

fprintf('UNIT TEST 1.4 (nominal zp): Geometric: %0.3f, fn1: %0.3f\n', rx, r(1)/1000)


% ======== 1.5 UNIT TEST tilted zone plate zone plate
beta = 0.1;
n = [-sin(beta), 0, cos(beta)];

% Vector
p = 1e3;
u = p*[0, 0, -1];

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, u, lambda_um);


% geometric calculation:
rx = tan(asin(lambda_nm/T_MIN_nm / 2));

fprintf('UNIT TEST 1.5 (tilt-x zp): Geometric: %0.3f, fn1: %0.3f\n', rx, r(1)/1000)


%% Unit tests 2
r = [tan(asin(lambda_nm/T_MIN_nm / 2)), 0, 1] * 1e3;
f = zpgeom.zpCoord2Freq(r, lambda_um);

fprintf('UNIT TEST 2.1 (coord to freq): Assert geometric: %0.3f =  fn1: %0.3f\n', f(1), 1/T_MIN_um/2)


%% Unit tests 3

% ======== 3.1 UNIT TEST tilted zone plate

% Compute ray on nominal zone plate
fx = 1/T_MIN_um * 0.5;
fy = 0;%1/T_MIN_um * 0.5;

% n = normal vector of zone plate:


beta = 0.1;
n = [-sin(beta), 0, cos(beta)];

% Vector
p = 1e3*[0, 0, 1];

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, p, lambda_um);


% Define basis vectors for zp:
bz = n;
by = [0, 1, 0];
bx = cross(n, by);

U = zpgeom.zpXYZ2UxUy(r, p, [bx', by', bz']); 



fprintf('UNIT TEST 3.1 (nominal zp): Assert bz: %0.3f = 0\n', U(3))

%% Unit test 4


% Compute ray on nominal zone plate
fx = 1/T_MIN_um * 0.5;
fy = 0;%1/T_MIN_um * 0.5;

% n = normal vector of zone plate:


beta = 0.1;
n = [-sin(beta), 0, cos(beta)];

% Vector
p = 1e3*[0, 0, 1];

% object distance:
r = zpgeom.freq2zpCoord([fx, fy], n, p, lambda_um);


% Define basis vectors for zp:
bz = n;
by = [0, 1, 0];
bx = cross(n, by);

U = zpgeom.zpXYZ2UxUy(r, p, [bx', by', bz']); 

r2 = zpgeom.zpUxUy2XYZ(U, p, [bx', by', bz']); 



fprintf('UNIT TEST 4.1 (nominal zp): Assert |r2 - r1| = 0: %0.3f \n', norm(r2 - r, 2))

