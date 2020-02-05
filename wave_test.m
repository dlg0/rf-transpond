%-----------------------------------------%
% Run wave solver for lapd-like 
% parameters. 
%-----------------------------------------%

lapd_params;
[om_c,om_p,cpdt,s_arr,d_arr,p_arr,sig] = dielec_tens(q_s,B0,1.66e18*ones(1,npts),m_s,om,eps0,npts,1);
[A,rf_e,rf_ex,rf_ey,rf_ez,diss_pow] = wave_sol(zax,ky,kx,k0,...
om,mu0,cpdt,source,0,1,1);
wave_sol_plots

%%

xax = linspace(-2,2,npts/2);
yax = 0.0;%linspace(-2,2,npts/4);

[Ex_x, Ey_x, Ez_x, Ex_y, Ey_y, Ez_y, Emag_x, Emag_y] = wave_projection(xax,yax,kx,ky,rf_ex,...
    rf_ey,rf_ez,npts);

