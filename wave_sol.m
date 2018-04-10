% --------------------------------%
% time independent wave solver   %
% V X V X E = k0^2.K.E           %
% rlbarnett c3149416 210917      %
%--------------------------------%
    
%--
% set up rhs matrix (multiples E field)

% syms ky kz k0 dx
% cpdt = sym('R%d%d',[3,3]);

A = zeros(3*npts, 3*npts);
% A = sym('O%d%d', [3*npts,3*npts]);
ii = 4;
kk = 1;

ex_sol = 

for eq1=4:3:3*(npts-1)
    
    eq2 = eq1+1;
    eq3 = eq2+1;
    
    iiex = ii;
    iiey = ii+1;
    iiez = ii+2;
    iiexm = iiex - 3;
    iieym = iiey - 3;
    iiezm = iiez - 3;
    iiexp = iiex + 3;
    iieyp = iiey + 3;
    iiezp = iiez + 3;        
    
    %--
    % fill matrix
    A(eq1,iiexm) = 0.0;
    A(eq1,iieym) = -1i*ky;
    A(eq1,iiezm) = -1i*kz;
    A(eq1,iiex) = 2.0*dx*(ky^2 + kz^2 - k0^2*cpdt(1,1,kk));
    A(eq1,iiey) = -2.0*dx*k0^2*cpdt(1,2,kk);
    A(eq1,iiez) = -2.0*dx*k0^2*cpdt(1,3,kk);
    A(eq1,iiexp) = 0.0;
    A(eq1,iieyp) = 1i*ky;
    A(eq1,iiezp) = 1i*kz;
    
    A(eq2,iiexm) = -1i*ky*(dx/2.0);
    A(eq2,iieym) = -1.0;
    A(eq2,iiezm) = 0.0;
    A(eq2,iiex) = -dx^2*k0^2*cpdt(2,1,kk);
    A(eq2,iiey) = dx^2*(kz^2 - k0^2*cpdt(2,2,kk)) + 2.0;
    A(eq2,iiez) = -dx^2*(ky*kz + k0^2*cpdt(2,3,kk));
    A(eq2,iiexp) = 1i*ky*(dx/2.0);
    A(eq2,iieyp) = -1.0;
    A(eq2,iiezp) = 0.0;
    
    A(eq3,iiexm) = -1i*kz*(dx/2.0);
    A(eq3,iieym) = 0.0;
    A(eq3,iiezm) = -1.0;
    A(eq3,iiex) = -dx^2*k0^2*cpdt(3,1,kk);
    A(eq3,iiey) = -dx^2*(ky*kz + k0^2*cpdt(3,2,kk));
    A(eq3,iiez) = dx^2*(ky^2 - k0^2*cpdt(3,3,kk)) + 2.0;
    A(eq3,iiexp) = 1i*kz*(dx/2.0);
    A(eq3,iieyp) = 0.0;
    A(eq3,iiezp) = -1.0;
    
    ii = ii + 3;
    kk = kk + 1;

end

%--
% metallic wall BC
A(1,1) = 1.0;
A(2,2) = 1.0;
A(3,3) = 1.0;
A(end-2,end-2) = 1.0;
A(end-1,end-1) = 1.0;
A(end,end) = 1.0;

A = sparse(A);

%--
% set up rhs vector
rhs = zeros(3*npts,1);
mult = 1.0/sqrt(2.0*pi*source_width);
source = mult*exp(-(xax - source_loc).^2/(2.0*source_width^2));
source = source / max(source);
% rhs(1:3:3*npts) = 1i*om*mu0*source';
rhs(2:3:3*npts) = 1i*om*mu0*source';
rhs(3:3:3*npts) = 1i*om*mu0*source';

% --
% calculation solution as waveeq_mat^-1*rhs
% -- COMMENT OUT IF DOING SYMBOLIC MATRIX --%
rf_e = (A)\rhs;

rf_ex = rf_e(1:3:3*npts);
rf_ey = rf_e(2:3:3*npts);
rf_ez = rf_e(3:3:3*npts);

%%
% ----------------------plots----------------------- %
figure(9)
% set(gca,'YTickLabel','%.2f')

subplot(4,1,1)
plot(xax,om*mu0*source,'r')
ylabel('Source ($i\omega\mu_0J_{y,z}$)')

subplot(4,1,2)
plot(xax, real(rf_ex), 'k')
ylabel('E$_x$ $Vm^{-1}$')

hold on

plot(xax, imag(rf_ex), '--')
set(gca, 'XTickLabel', [])
legend('Re[Ex]', 'Im[Ex]', 'Location', 'northwest')
    
hold off

subplot(4,1,3)
plot(xax, real(rf_ey), 'k')
ylabel('E$_y$ $Vm^{-1}$')

hold on

plot(xax, imag(rf_ey), '--')
set(gca, 'XTickLabel', [])
legend('Re[Ey]', 'Im[Ey]', 'Location', 'northwest')

hold off

subplot(4,1,4)
plot(xax, real(rf_ez), 'k')
ylabel('E$_z$ $Vm^{-1}$')

hold on

plot(xax, imag(rf_ez), '--')
xlabel('Position')
legend('Re[Ez]', 'Im[Ez]', 'Location', 'northwest')

hold off




