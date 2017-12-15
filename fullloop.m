%----------------------------------------%
% main script for 1D DVE loop            %
% rlbarnett c3149416 061117              %
%----------------------------------------%

%--
% constants
mu0 = 4.0*pi*1.0e-7;
eps0 = 8.85e-12;
c0 = 1.0/sqrt(eps0*mu0);

%--
% driver freq
freq = 42.0e6;
om = 2.0*pi*freq;
k0 = om/c0;
wavel0 = (2*pi)/k0;
source_width = 0.01;
source_loc = 1.5;
dampFac = 10.0

%--
% define wavenumbers ky and kz (/m); use values given in van eester section IV?? No
% others mentioned
ky = 10.0;
kz = 0.0;

%--
% "common local derivatives for N0, v||^2, static potential and
% ponderomotive potential" 
lamby = 0.0;
lambz = 0.0;

%--
% spatial domain
npts = 256;
xmin = 1.15;
xmax = 1.7;
dx = (xmax - xmin)/(npts - 1);
% npts = ((xmax - xmin)/dx);
xax = linspace(xmin, xmax, npts);
% xax = xmin:dx:xmax;
% dx = (xmax - xmin)/(npts - 1);

%--
% magnetic field (tesla)
R0 = 1.32;
B0 = 2.4*R0./xax;

%--
% background density -- set to zero for vacuum case
Nmax = 50.0e19;
N0 = Nmax*ones(1,npts);

%--
% initialise perturbed density as zero
N1 = zeros(1,npts);
N1e = N1;
N1i = N1;

%--
% initialise perturbed velocity as zero
v1 = zeros(1,npts);
v1e = v1;
v1i = v1;

%--
% electron constants
e = -1.6022e-19;
me = 9.11e-31*ones(1,npts);

%pd1 = makedist('HalfNormal','sigma',0.15);
%ax = linspace(0,dx*np_bound,np_bound);
%pdf1 = pdf(pd1,ax);
%pdf1 = pdf1/max(pdf1);

% DLG - since I don't have the license for "makedist"
% I fixed your cos ramping function :)

np_bound = floor(0.2*npts);
ax = linspace(0,pi,np_bound);
damp0 = (cos(ax)+1)/2;
damp = ones(1,npts);
damp(1:np_bound) = damp(1:np_bound) + dampFac*i*damp0;
damp(end-(np_bound-1):end) = damp(end-(np_bound-1):end) + dampFac*i*fliplr(damp0);

me = me .* damp;

%--
% temperature
T_ev = 15.0;

%--
% thermal velocity
vt = sqrt((T_ev*abs(e)) ./ me);

%--
% ion constants (95% D, 5% H)
qd = abs(e);
mp = 1.67e-27;
md = 2.0*mp*ones(1,npts);
md = md .* damp;

qh = abs(e);
mh = mp*ones(1,npts);
mh = mh .* damp;

%-- 
% cyclotron frequencies
om_ce = e*B0./me;
om_cd = qd*B0./md;
om_ch = qh*B0./mh;

%--
% rotation matrix
alpha = 0.;
beta = 0.;

r11 = cos(beta)*cos(alpha);
r12 = cos(beta)*sin(alpha);
r13 = -sin(beta);
r21 = -sin(alpha);
r22 = cos(alpha);
r23 = 0.0;
r31 = sin(beta)*cos(alpha);
r32 = sin(beta)*sin(alpha);
r33 = cos(beta);

rot = [[r11, r12, r13]
     [r21, r22, r23]
     [r31, r32, r33]];
 
e_para = rot(3,:);
Bvec = B0.*transpose(repmat(e_para,npts,1));

%--
% electron calcs; density, plasma frequency 
N0e = 1.0*N0;
om_pe = sqrt(N0e*e^2./(me*eps0));

%--
% ion calcs (95% D, 5% H); density, plasma frequency
N0d = 0.95*N0;
om_pd = sqrt(N0d*qd^2./(md*eps0));
N0h = 0.05*N0;
om_ph = sqrt(N0h*qh^2./(mh*eps0));
N0i = N0h + N0d;

nmax = 10;

%%

% for iter=1:nmax
    
%     tic

%--
% plot electron densities
figure(1);
set(gcf,'Position',[0   536   824   419])
% suptitle(['Iteration ' num2str(iter)])

subplot(2,3,1)
plot(xax,N0e,'k')
ylabel('N$_{0,e}$','Fontsize',16)
ytickformat('%.2f')

subplot(2,3,2)
plot(xax,N1e,'k')
ylabel('N$_{1,e}$','Fontsize',16)
ytickformat('%.2f')

hold on

%--
% poisson solve for static potential -- solution (output) "static_pot"

poisson_sol;%(Ne, Nh, Nd, lamby, lambz, e, eps0, dx, npts);

%--
% plot static potential
subplot(2,3,3)
plot(xax,static_pot,'r')
ylabel('$\phi$ (V)','Fontsize',16)
ytickformat('%.2f')

%--
% static electric field calculation -- solution (output) "static_e(x,y,z)"

static_e;

%--
% plot static electric field solutions
subplot(2,3,4)
plot(xax,static_ex,'k')
ylabel('E$_{0,ex}$','Fontsize',16)
ytickformat('%.2f')

subplot(2,3,5)
plot(xax,static_ey,'k')
ylabel('E$_{0,ey}$','Fontsize',16)
ytickformat('%.2f')

subplot(2,3,6)
plot(xax,static_ez,'k')
ylabel('E$_{0,ez}$','Fontsize',16)
ytickformat('%.2f')

hold off
drawnow

%--
% wave solver to find rf electric field -- solution (output) "rf_e(x,y,z)"

wave_sol;

profile on
%--
% call dispersion relation script
%dispersion;

%%

%--
% plot rf wave solutions
figure(2);
set(gcf,'Position',[859   536   824   419])
% suptitle(['Iteration ' num2str(iter)])

subplot(3,3,1)
plot(xax,real(rf_ex),'k')
hold on
plot(xax,imag(rf_ex),'--b')
legend('Re[Ex]', 'Im[Ex]', 'Location', 'northwest') 
ylabel('E$_{1,ex}$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,2)
plot(xax,real(rf_ey),'k')
hold on
plot(xax,imag(rf_ey),'--b')
ylabel('E$_{1,ey}$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,3)
plot(xax,real(rf_ez),'k')
hold on
plot(xax,imag(rf_ez),'--b')
ylabel('E$_{1,ez}$','Fontsize',16)
ytickformat('%.2f')

hold on

%--
% ponderomotive acceleration calculation -- solution (output)
% "a_pond(x,y,z)"

a_pond;

%--
% plot ponderomotive potential and accelerations
subplot(3,3,4)
plot(xax,pond_pote,'r')
ylabel('$\Theta$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,7)
plot(xax,a_pondex,'k')
ylabel('$(-\nabla\Theta)_x$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,8)
plot(xax,a_pondey,'k')
ylabel('$(-\nabla\Theta)_y$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,9)
plot(xax,a_pondez,'k')
ylabel('$(-\nabla\Theta)_z$','Fontsize',16)
ytickformat('%.2f')

hold off
drawnow

%--
% pressure term -- solution (output) "press(x,y,z)"

pressure;

%--
% plot pressures
figure(3);
set(gcf,'Position',[6    60   824   419])
% suptitle(['Iteration ' num2str(iter)])

subplot(3,3,1)
plot(xax,pressex,'k')
ylabel('$(\nabla N_0/N_0)_x$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,2)
plot(xax,pressey,'k')
ylabel('$(\nabla N_0/N_0)_y$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,3)
plot(xax,pressez,'k')
ylabel('$(\nabla N_0/N_0)_z$','Fontsize',16)
ytickformat('%.2f')

hold on

%--
% calculate perpendicular drift velocities analytically -- solution
% (output) "v_perp(1,2)"

v_drift;


%--
% calculate perturbed velocity

fastv_update;

%--
% plot perpendicular drift velocities
subplot(3,3,4)
plot(xax,vd_perp1e,'k')
ylabel('v$_{e\perp,1}$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,5)
plot(xax,vd_perp2e,'k')
ylabel('v$_{e\perp,2e}$','Fontsize',16)
ytickformat('%.2f')

%--
% solve equation 23 (DVE 2015): slow time scale continuity equation yielding v
% parallel -- solution (output)

cont_slow;

%--
% plot parallel drift velocity and perturbed velocity
subplot(3,3,6)
plot(xax,v_parae,'k')
ylabel('v$_{e\parallel}$','Fontsize',16)
ytickformat('%.2f')

subplot(3,3,7)
plot(xax,v1e(1,:),'r')
hold on
plot(xax,v1e(2,:))
plot(xax,v1e(3,:))
ylabel('v$_{1,e}$','Fontsize',16)
legend('$v1_{e,x}$','$v1_{e,y}$','$v1_{e,z}$')
ytickformat('%.2f')
hold off

hold off
drawnow

%--
% solve equation 24 (DVE 2015): slow time scale parallel equation of motion yielding log(N0) 
% -- solution (output)

% eqofmot_slow;


%--
% solve equation 25 (DVE 2015): fast time scale continuity equation
% yielding the perturbed density 

% cont_fast;

%     toc
    
%     end



