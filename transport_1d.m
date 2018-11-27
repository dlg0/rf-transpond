%--------------------------------------------------------------------------------------------------------------%
% solve coupled transport equations                                                                            %
% continuity and momentum eqns                                                                                 %
% CONSERVATIVE FORMS                                                                                           %
% (partial derivatives)                                                                                        %
% dvz/dt + d(vz^2/2)/dz + (1/mn)(Te+Ti)dn/dz = 0                                                               %
% dn/dt + d(n*vz)/dz = 0                                                                                       %
% staggered n and vz grids                                                                                     %
% momentum eqn central differenced                                                                             %
% continuity eqn first order upwind (flux selecting)                                                           %
% ghost points on density for mom source term                                                                  %
%       -- first order neumann = 0                                                                             %
% rlbarnett c3149416 140818                                                                                    %
%--------------------------------------------------------------------------------------------------------------%
% set up code to accept 'switches' for left and right boundary conditions
% depending on the flux.
%
% need to use something like strcmp function to compare strings
%
% maybe also need to look into actually writing this as a function with
% whatever inputs?
%--------------------------------------------------------------------------------------------------------------%
%%
%--------------------------------------------------------------------------------------------------------------%
% --select differencing scheme
% --central should only work if there is a diffusion term
% --OR maybe set up so that the advetion term is always upwinded and the
% diffusion term is central differenced?
% --maybe this should go before the BCs, because if it is central
% differenced/has diffusion term, there will need to be two BCs


% function [n, vx] = transport_1d(grid_type,spatial_scheme,...
%   ln_bound_type,ln_bound_val,rn_bound_type,rn_bound_val,...
%   lv_bound_type,lv_bound_val,rv_bound_type,rv_bound_val,const,input_file)

% run(input_file);

% import parameter file
% params_transport_wave_ACM;
transport_test;

% initialise velocity and density 
vx = vx_new;
n = n_new;

staggered = NaN;
collocated = NaN;
v_ldirichlet = NaN;
v_rdirichlet = NaN;
v_rneumann = NaN;
v_lneumann = NaN;
v_periodic = NaN;
n_ldirichlet = NaN;
n_rdirichlet = NaN;
n_rneumann = NaN;
n_lneumann = NaN;
n_periodic = NaN;
explicit = NaN;
implicit = NaN;

grid_type = 'staggered or collocated grid? ';
gridt = input(grid_type, 's');
if isempty(gridt)
    gridt = 'staggered';
end

if strcmp(gridt,'staggered')
    staggered = 1;
    collocated = 0;
elseif strcmp(gridt,'collocated')
    staggered = 0;
    collocated = 1;
end


if (isnan(staggered)) || (isnan(collocated))
    error("Check spelling and/or type of answer for %s.\n",'"staggered or collocated grid?"')
    return
end

if staggered
    
    ln_bound_type = 'Left (ghost) BC type? (dirichlet, neumann, periodic, linear extrap) ';
    leftGhost = input(ln_bound_type, 's');
    if isempty(leftGhost)
        leftGhost = 'linear extrap';
    end
    
    if strcmp('periodic',leftGhost)

    else
        rn_bound_type = 'Right (ghost) BC type? (dirichlet, neumann, linear extrap) ';
        rightGhost = input(rn_bound_type, 's');
        if isempty(rightGhost)
            rightGhost = 'linear extrap';
        end
    end
    
    if strcmp('linear extrap',leftGhost)
        lGhost = interp1([nxax(2), nxax(3)], [n_new(2), n_new(3)],...
            nxax(1),'linear','extrap');
        n_ldirichlet = 0;              
        n_lneumann = 0;
        n_periodic = 0;
    elseif strcmp('dirichlet',leftGhost)
        n_ldirichlet = 1;              
        n_lneumann = 0;
        n_periodic = 0;
    elseif strcmp('neumann',leftGhost)
        n_ldirichlet = 0;                
        n_lneumann = 1; 
        n_periodic = 0;
    end  
    
    if (isnan(n_ldirichlet)) || (isnan(n_lneumann)) || (isnan(n_periodic))
        error("Check spelling and/or type of answer for %s.\n",...
            '"Left (ghost) BC type? (dirichlet, neumann, periodic, linear extrap)"')
        return
    end
    
    if strcmp('linear extrap',leftGhost)
    else
        ln_bound_val = 'Left (ghost) BC value for density? ';
        lnBC_val = input(ln_bound_val);
        if isempty(lnBC_val)
            lnBC_val = lGhost;
        end
    end
    
    if strcmp('linear extrap',rightGhost)
        rGhost = interp1([nxax(npts-2), nxax(npts-1)], [n_new(npts-2), n_new(npts-1)],...
            nxax(npts),'linear','extrap');
        n_rdirichlet = 0;                
        n_rneumann = 0; 
        n_periodic = 0;
    elseif strcmp('dirichlet',rightGhost)
        n_rdirichlet = 1;              
        n_rneumann = 0;
        n_periodic = 0;
    elseif strcmp('neumann',rightGhost)
        n_rdirichlet = 0;                
        n_rneumann = 1; 
        n_periodic = 0;
    end
    
    if strcmp('linear extrap',rightGhost)
    else
        rn_bound_val = 'Right (ghost) BC value for density? ';
        rnBC_val = input(rn_bound_val);
        if isempty(rnBC_val)
            rnBC_val = rGhost;
        end
    end
    
    if (isnan(n_rdirichlet)) || (isnan(n_rneumann)) || (isnan(n_periodic))
        error("Check spelling and/or type of answer for %s.\n",...
            '"Right (ghost) BC type? (dirichlet, neumann, periodic)"')
        return
    end
    
end

if collocated
    
    if vx_new(1,2) > 0
        promptlnBC = 'Left BC type for density? (dirichlet, neumann, periodic) ';
        leftnBC = input(promptlnBC, 's');
        if strcmp('dirichlet',leftnBC)
            n_ldirichlet = 1;              
            n_lneumann = 0;
            n_periodic = 0;
        elseif strcmp('neumann',leftnBC)
            n_ldirichlet = 0;                
            n_lneumann = 1; 
            n_periodic = 0;
        end
        promptlnBCval = 'Left BC value for density? ';
        lnBC_val = input(promptlnBCval);
    elseif vx_new(1,2) < 0 
        fprintf("Left BC not required on density for the given flux direction.\n")
        n_ldirichlet = 0;
        n_lneumann = 0;
        n_periodic = 0;
    end
    if vx_new(1,end-1) < 0
        promptrnBC = 'Right BC type for density? (dirichlet, neumann, periodic) ';
        rightnBC = input(promptrnBC, 's');
        if strcmp('dirichlet',rightnBC)
            n_rdirichlet = 1;              
            n_rneumann = 0;
            n_periodic = 0;
        elseif strcmp('neumann',rightnBC)
            n_rdirichlet = 0;                
            n_rneumann = 1; 
            n_periodic = 0;
        end
        rn_bound_val = 'Right BC value for density? ';
        rnBC_val = input(rn_bound_val);
    elseif vx_new(1,end-1) > 0 
        fprintf("Right BC not required on density for the given flux direction.\n")
        n_rdirichlet = 0;
        n_rneumann = 0;
        n_periodic = 0;
    end
end

%%

upwind = NaN;
central = NaN;

spatial_scheme = 'Spatial differencing scheme for momentum equation? (upwind or central) ';
scheme = input(spatial_scheme, 's');
if isempty(scheme)
    scheme = 'central';
end

if strcmp(scheme,'upwind')
    upwind = 1;
    central = 0;
elseif strcmp(scheme, 'central')
    upwind = 0;
    central = 1;
end

% if central && nu==0
%     fprintf("nu==0: central difference scheme not stable.\n")
%     return
% end

%%
%--------------------------------------------------------------------------------------------------------------%
% select boundary conditions -- start with simple dirichlet
% what do you need?
% 1: to be able to specify the type of BC -- string
% 2: to be able to then set the value -- float


%----- need a prompt here to check whether the velocity is positive or
% negative next to the boundary, as this will determine whether left or right (or both)
% BC is required

if central

    lv_bound_type = 'Left BC type for velocity? (dirichlet, neumann, periodic) ';
    leftvBC = input(lv_bound_type, 's');
    if isempty(leftvBC)
        leftvBC = 'dirichlet';
    end
    if strcmp('periodic',leftvBC)

    else
        rv_bound_type = 'Right BC type for velocity? (dirichlet or neumann) ';
        rightvBC = input(rv_bound_type, 's');
        if isempty(rightvBC)
            rightvBC = 'dirichlet';
        end
    end

    if strcmp('dirichlet',leftvBC)
        v_ldirichlet = 1;               % this allows the use of ldirichlet as a logical 
        v_lneumann = 0;
        v_periodic = 0;
    elseif strcmp('neumann',leftvBC)
        v_ldirichlet = 0;                
        v_lneumann = 1; 
        v_periodic = 0;
    end

    if strcmp('dirichlet',rightvBC)
        v_rdirichlet = 1;
        v_rneumann = 0;
        v_periodic = 0;
    elseif strcmp('neumann',rightvBC)
        v_rneumann = 1;
        v_rdirichlet = 0;
        v_periodic = 0;
    end

    if strcmp('periodic',leftvBC)
        v_rdirichlet = 0;
        v_rneumann = 0;
        v_ldirichlet = 0;
        v_lneumann = 0;
        v_periodic = 1;
    end

    lv_bound_val = 'Left BC value for velocity? ';
    lvBC_val = input(lv_bound_val);
    if isempty(lvBC_val)
        lvBC_val = 0;
    end
    if strcmp('periodic',leftvBC)

    else
        rv_bound_val = 'Right BC value for velocity? ';
        rvBC_val = input(rv_bound_val);
        if isempty(rvBC_val)
            rvBC_val = cs;
        end
    end

    if v_ldirichlet && v_rdirichlet
        fprintf("left and right velocity BCs are dirichlet; lBC = %f, rBC = %f.\n", lvBC_val, rvBC_val)
    elseif v_lneumann && v_rdirichlet
        fprintf("left velocity BC is neumann, lBC = %f; right velocity BC is dirichlet, rBC = %f.\n", lvBC_val, rvBC_val)
    elseif v_rneumann && v_ldirichlet
        fprintf("left velocity BC is dirichlet, lBC = %f; right velocity BC is neumann, rBC = %f.\n", lvBC_val, rvBC_val)
    elseif v_rneumann && v_lneumann
        fprintf("left and right velocity BCs are dirichlet; lBC = %f, rBC = %f.\n", lvBC_val, rvBC_val)
    elseif v_periodic
        fprintf("periodic velocity BCs\n")
    end
    
elseif upwind
    
    if vx_new(1,2) > 0
            lv_bound_type = 'Left BC type for velocity? (dirichlet, neumann, periodic) ';
            leftvBC = input(lv_bound_type, 's');
            if strcmp('dirichlet',leftvBC)
                v_ldirichlet = 1;              
                v_lneumann = 0;
                v_periodic = 0;
            elseif strcmp('neumann',leftvBC)
                v_ldirichlet = 0;                
                v_lneumann = 1; 
                v_periodic = 0;
            end
            lv_bound_val = 'Left BC value for velocity? ';
            lvBC_val = input(lv_bound_val);
    elseif vx_new(1,2) < 0 
            fprintf("Left BC not required\n")
            v_ldirichlet = 0;
            v_lneumann = 0;
            v_periodic = 0;
    end
    
    if vx_new(1,end-1) < 0
            rv_bound_type = 'Right BC type? (dirichlet, neumann, periodic) ';
            rightvBC = input(rv_bound_type, 's');
            if strcmp('dirichlet',rightvBC)
                v_rdirichlet = 1;              
                v_rneumann = 0;
                v_periodic = 0;
            elseif strcmp('neumann',rightvBC)
                v_rdirichlet = 0;                
                v_rneumann = 1; 
                v_periodic = 0;
            end
            rv_bound_val = 'Right BC value? ';
            rvBC_val = input(rv_bound_val);
    elseif vx_new(1,end-1) > 0 
            fprintf("Right BC not required\n")
            v_rdirichlet = 0;
            v_rneumann = 0;
            v_periodic = 0;
    end
    
end

%%
%--------------------------------------------------------------------------------------------------------------%
% INITALISE PLOTS; INCLUDE INITIAL CONDITIONS
%--------------------------------------------------------------------------------------------------------------%

% vx_source = source_stag(n_new,const.e,Te,Ti,const.mp,npts,dx);
vx_source = source_col(n_new,const.e,Te,Ti,const.mp,npts-1,dx);

figure(1)
set(gcf,'Position',[563 925 560 420])
semilogy(nxax,n_new,'DisplayName',['time = 0s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Density m^{-3}','Fontsize',16)
legend('show','Location','south')
hold on

figure(2)
set(gcf,'Position',[7 925 560 420])
plot(vxax,vx_new/cs,'DisplayName',['time = 0s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Mach number','Fontsize',16)
legend('show','Location','southeast')
hold on

figure(3)
set(gcf,'Position',[3 476 560 420])
plot(vxax(2:npts-2),(vx_source(2:npts-2)*dt),'DisplayName',['time = 0s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Velocity source ms^{-1}','Fontsize',16)
legend('show','Location','northwest')
hold on

figure(4)
set(gcf,'Position',[563 476 560 420])
plot(nxax(2:npts-1),n_source(2:npts-1)*dt,'DisplayName',['time = 0s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Density source ms^{-1}','Fontsize',16)
legend('show','Location','northwest')
hold on

%%
%--------------------------------------------------------------------------------------------------------------%
% START TIME STEPPING
%--------------------------------------------------------------------------------------------------------------%

count = 2;
timerVal = tic;

vx_rms = zeros(1,nmax);
n_rms = zeros(1,nmax);

for ii=1:40

%     ns_mult = (trapz(n) - trapz(n_new));

%     set the vectors with the old value going into the next loop
%     nfact = trapz(n)/trapz(n_new)
    n = n_new;
    vx = vx_new;
%     rGhost = interp1([nxax(npts-2), nxax(npts-1)], [n_new(npts-2), n_new(npts-1)],...
%         nxax(npts),'linear','extrap');   
%     lGhost = interp1([nxax(2), nxax(3)], [n_new(2), n_new(3)],...
%         nxax(1),'linear','extrap');
%     [om_c,om_p,cpdt,s_arr,d_arr,p_arr] = dielec_tens(e,B0,n_new,[m; me],om,eps0,npts);
%     dispersion;
%     [A,source,rf_ex,rf_ey,rf_ez] = wave_sol(nxax,real(kp22),0,k0,om,const.mu0,cpdt,...
%     xmax/100,xmax);
% 
%     Efield = interp1(nxax,abs(rf_ex),...
%         vxax(2:npts-1),'linear');
%     Efield = Efield.^2;
    
    if staggered
        
        % fill n coefficient matrix using the averaged value of the
        % velocities on surrounding grid points
        for jj=2:npts-1
            if ((vx(1,jj-1)+vx(1,jj))/2)>0
                nA(jj,jj) = - mult*vx(1,jj);
                nA(jj,jj-1) = mult*vx(1,jj-1);
            elseif ((vx(1,jj-1)+vx(1,jj))/2)<0
                nA(jj,jj) = mult*vx(1,jj-1);
                nA(jj,jj+1) = -mult*vx(1,jj);
            end
%             n_source(1,jj) = n_new(1,jj)*n_neut(1,jj)*rate_coeff;
        end
        
        n_source(1,2:npts-1) = n_new(1,2:npts-1).*n_neut(1,2:npts-1)*rate_coeff;
        
        n_avg = (n_new(1:npts-1) + n_new(2:npts))/2.0;
        source_int = trapz(n_source);
        ns_mult = source_int/(vx_new(end)*n_avg(end)) - 0.1;
        n_source = n_source / ns_mult;

        % build full coefficient matrices
%         An_exp = nI + dt*nA;
        An_imp = nI - dt*nA;
        
        % override values in top and bottom rows to reflect neumann
        % boundary conditions for the implicit calculation
        An_imp(1,1) = 1.0; %An_imp(1,2) = -1.0;
        An_imp(end,end) = 1.0; %An_imp(end,end-1) = -1.0;        
        
        % calculate explicit solution
%         n_new_exp = An_exp*n' + dt*n_source';
        % directly override solution vector to include neumann boundary
        % conditions for explicit method
%         n_new_exp(1,1) = n_new_exp(2,1);
%         n_new_exp(end,1) = n_new_exp(end-1,1);
        
        % zero old rhs values for top and bottom boundary equations for
        % implicit calculation
        n(1,1) = lGhost;
        n(1,end) = rGhost;
        % implicit calculation
        n_new_imp = An_imp\(n' + dt*n_source');
        
        % transpose solution vector
        n_new = n_new_imp;
        n_new = n_new';
        
     
    elseif collocated
 
        for jj=2:npts-2
            if vx(1,jj)>0
                nA(jj,jj) = -mult*vx(1,jj);
                nA(jj,jj-1) = mult*vx(1,jj-1);
            elseif vx(1,jj)<0
                nA(jj,jj) = mult*vx(1,jj);
                nA(jj,jj+1) = -mult*vx(1,jj+1);
            end
        end
        
        nA(end,end) = -mult*vx(1,end);
        nA(end,end-1) = mult*vx(1,end-1);
        
%         An_exp = nI + dt*nA;
        An_imp = nI - dt*nA;
        
        An_imp(1,1) = 1.0;
        
        n(1,1) = lnBC_val;
        
        n_source = n.*n_neut*rate_coeff;
        source_int = trapz(nxax, n_source);
        rflux = vx(end)*n(end);
        ns_mult = rflux/source_int;
        n_source = n_source*ns_mult;
        n_source(1,1) = 0.0;
        
%         if trapz(nxax,n_source) - rflux ~= 0
%             error("Flux at RH boundary and density source integral are not equal\n")
%             return  
%         end
        
        % implicit calculation
        n_new_imp = An_imp\(n' + dt*n_source');
        
        % transpose solution vector
        n_new = n_new_imp;
        n_new = n_new';
        
    end
    
%--------------------------------------------------------------------------------------------------------------%
% COLLOCATED (ABOVE) NOT IN USE
% BELOW IS IN USE
%--------------------------------------------------------------------------------------------------------------%
    
    % fill coefficient matrices for momentum equation, positive for v>0 and
    % negative for v<0 on the convective term; differencing of the
    % diffusion term is central and not dependent on flow direction
    for jj=2:npts-2
        if vx(1,jj)>0
            vx_pos(jj,jj) = - mult*vx(1,jj);
            vx_pos(jj,jj-1) = mult*vx(1,jj);
        elseif vx(1,jj)<0
            vx_neg(jj,jj) = mult*vx(1,jj);
            vx_neg(jj,jj+1) = -mult*vx(1,jj);
        end
        vx_diff(jj,jj) = - mult*((2.0*nu)/dx);
        vx_diff(jj,jj-1) = mult*(nu/dx);
        vx_diff(jj,jj+1) = mult*(nu/dx);
    end
    
%     vx_diff(2:npts-2,2:npts-2) = - mult*((2.0*nu)/dx);
%     vx_diff(2:npts-2,1:npts-3) = mult*(nu/dx);
%     vx_diff(2:npts-2,3:npts-1) = mult*(nu/dx);
   
%     vx_diff = (gallery('tridiag',10,- mult*((2.0*nu)/dx),...
%         mult*(nu/dx),mult*(nu/dx)));

%     vx_ones = ones(1,npts-3);
%     vx_ones = [0, vx_ones, 0];
%     vx_diff = sparse(diag(- mult*((2.0*nu)/dx)*vx_ones,0) +...
%         diag(vx_ones(2:npts-1)*mult*(nu/dx),-1) +...
%         diag(vx_ones(1:npts-2)*mult*(nu/dx),1));
         
    % construct full coefficient matrix for momentum equation
    if upwind 
        vxA = vx_pos + vx_neg;
    elseif central
        vxA = vx_pos + vx_neg + vx_diff;
    end
    
    % build full coefficient matrices
%     Avx_exp = vx_I + dt*vxA;
    Avx_imp = vx_I - dt*vxA;
    % override top and bottom rows to include dirichlet boundary conditions
    % for the momentum equation (explicit and implicit methods)
%     Avx_exp(1,1) = 1.0; Avx_exp(end,end) = 1.0;
    Avx_imp(1,1) = 1.0; Avx_imp(end,end) = 1.0;
    
    % override values in top and bottom rows to reflect neumann
    % boundary conditions for the implicit calculation
%     Avx_imp(1,2) = -1.0; Avx_imp(end,end-1) = -1.0;
    % ensure that the velocity value at the boundaries is correct
    vx(1,1) = lvBC_val;
    vx(1,end) = rvBC_val;
    
    % calculate the source term
    if staggered
        vx_source = source_stag(n,const.e,Te,Ti,const.mp,npts,dx);
        vx_scale = max(abs(-nu*gradient(vx_new(2:npts-2))./vx_source(2:npts-2)));
        pf_source = pond_source(const.mp,om,const.e,Efield,dx,npts-2);
        pf_source = [0,pf_source,0];
    elseif collocated
        vx_source = source_col(n,const.e,Te,Ti,m,npts-1,dx);
    end
      
    % zero the source term at the boundaries as it is not used (dirichlet
    % boundary conditions will override the source)
    vx_source(1,1) = 0.0;
    vx_source(1,end) = 0.0;
%     pf_source(1,end) = 0.0;
       
    % explicit calculation
%     vx_new_exp = Avx_exp*vx' + dt*(vx_source' + pf_source');
    % implicit calculation
%     vx_new_imp = Avx_imp\(vx' + dt*(vx_source' - pf_source'));
    vx_new_imp = Avx_imp\(vx' + dt*vx_source');
    
    % transpose solution vector
    vx_new = vx_new_imp;
    vx_new = vx_new';
    
    % reset CFL condition based on the lowest dt out of the
    % convective/diffusive CFLs
%     if (cfl_fact*(dx^2)/(2.0*nu))<(cfl_fact*dx/max(abs(vx_new)))
%         dt = cfl_fact*(dx^2)/(2.0*nu);
%     elseif (cfl_fact*(dx^2)/(2.0*nu))>(cfl_fact*dx/max(abs(vx_new)))
%         dt = cfl_fact*dx/max(abs(vx_new));
%     end
% 
% %     will stop running script if either of the CFL conditions is violated
%     if dt*max(abs(vx_new))/dx >= 1.0 || dt*2*nu/dx^2 >= 1.0
%         fprintf('CFL condition violated, ii=%d\n',ii)
%         return
%     end
    
    % will stop running script if there are any nans in the velocity array
    nan_check = isnan(vx_new);
    
    if sum(nan_check) ~= 0
        fprintf('unstable, ii=%d\n',ii)
        return
    end

    % plot loop; every 1/5 of iterations
    if mod(ii,4)==0
        fprintf('***--------------------***\n')
        fprintf('ii=%d, count=%d\n', [ii count])
        fprintf('dt=%ds\n', dt)
        fprintf('total time=%ds\n', dt*ii)
        fprintf('simulation time %d\n', toc(timerVal))
        fprintf('number of particles %d\n', trapz(nxax,n_new))
        fprintf('particle balance check %d\n', trapz(nxax,n) - trapz(nxax,n_new))
%         fprintf('source multiplier before normalisation %d\n',ns_mult)
        fprintf('flux out of RH boundary %d\n',rflux)
%         ns_mult = source_int/(vx_new(end)*n_avg(end));
%         fprintf('source multiplier after normalisation %d\n',ns_mult)
        fprintf('source integral %d\n',source_int)
%         fprintf('neutral density integral %d\n',trapz(n_neut))
        
%         if dt == cfl_fact*(dx^2)/(2.0*nu)
%             fprintf('Diffusive CFL condition\n')
%         elseif dt == cfl_fact*dx/max(abs(vx_new))
%             fprintf('Convective CFL condition\n')
%         end
        figure(1)
        set(gcf,'Position',[563 925 560 420])
        semilogy(nxax,n_new,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
        xlim([min(nxax+dx) max(nxax-dx)])
        hold on
%         semilogy(nxax(2:npts-1),n_new_exp(2:npts-1),'--','DisplayName',['(imp)time = ' num2str(double(ii)*dt) ' s'])
        figure(2)
        set(gcf,'Position',[7 925 560 420])
        plot(vxax,vx_new/cs,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
        xlim([min(vxax) max(vxax)])
        hold on
%         plot(vxax,vx_new_imp/cs,'--','DisplayName',['(exp)time = ' num2str(double(ii)*dt) ' s'])
        figure(3)
        set(gcf,'Position',[3 476 560 420])
        plot(vxax(2:npts-2),(vx_source(2:npts-2)*dt),'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
        xlim([min(vxax) max(vxax)])
        hold on
        figure(4)
        set(gcf,'Position',[563 476 560 420])
        plot(nxax(2:npts-1),n_source(2:npts-1)*dt,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
        xlabel('Position (m)','Fontsize',16)
        ylabel('Density source ms^{-1}','Fontsize',16)
        legend('show','Location','northwest')
        hold on
%         figure(10)
%         plot(nxax,real(kp21),'.k')
% 
%         hold on
% 
%         plot(nxax,imag(kp21),'.r')
%         plot(nxax,real(kp22),'dk','MarkerSize',3)
%         plot(nxax,imag(kp22),'dr','MarkerSize',3)
%         legend('Re[k_{\perp2}]', 'Im[k_{\perp2}]', 'Re[k_{\perp2}]', 'Im[k_{\perp2}]')
%         xlabel('log_{10}|n|','Fontsize',16)
%         % vline(log10(N0(imme)),'--k') 
%         ylabel('|k_{\perp2}|','Fontsize',16)
%         xlim([xmin,xmax])
%         hold off
%         figure(5)
%         plot(vxax(2:npts-2),sqrt(Efield(2:npts-2)),'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
%         xlabel('Position (m)','Fontsize',16)
%         ylabel('Electric field (Vm^{-1})','Fontsize',16)
%         legend('show','Location','northwest')
%         hold on
        vx_mat(count,:) = vx_new;
        n_mat(count,:) = n_new;
        count = count + 1;
    end
    
    if rms(n_new - n)<=1.0e-9*rms(n_new)
        fprintf('tolerance reached, ii=%d\n',ii)
        break
    else
        continue
    end
%     vx_rms(1,ii) = rms(vx_new);
%     n_rms(1,ii) = rms(n_new);
    
end

vx_mat(count,:) = vx_new;
n_mat(count,:) = n_new;

fprintf('***--------------------***\n')
fprintf('ii=%d, count=%d\n', [ii count])
fprintf('dt=%ds\n', dt)
fprintf('total time=%ds\n', dt*ii)
fprintf('simulation time %d\n', toc(timerVal))

        
%%

figure(1)
set(gcf,'Position',[563 925 560 420])
semilogy(nxax,n_new,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
hold on
% semilogy(nxax(2:npts-1),n_new_exp(2:npts-1),'--','DisplayName',['(imp)time = ' num2str(double(ii)*dt) ' s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Density m^{-3}','Fontsize',16)
legend('show','Location','south')
hold off

figure(2)
set(gcf,'Position',[7 925 560 420])
plot(vxax,vx_new/cs,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
hold on
% plot(vxax,vx_new_imp/cs,'--','DisplayName',['(exp)time = ' num2str(double(ii)*dt) ' s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Mach number','Fontsize',16)
legend('show','Location','southeast')
hold off

figure(3)
set(gcf,'Position',[3 476 560 420])
plot(vxax(2:npts-2),vx_source(2:npts-2)*dt,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Velocity source ms^{-1}','Fontsize',16)
legend('show','Location','northwest')
hold off

figure(4)
set(gcf,'Position',[563 476 560 420])
plot(nxax(2:npts-1),n_source(2:npts-1)*dt,'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Density source ms^{-1}','Fontsize',16)
legend('show','Location','northwest')
hold off

figure(5)
plot(vxax(2:npts-2),sqrt(Efield(2:npts-2)),'DisplayName',['time = ' num2str(double(ii)*dt) ' s'])
xlabel('Position (m)','Fontsize',16)
ylabel('Electric field (Vm^{-1})','Fontsize',16)
legend('show','Location','northwest')
hold off

%%

tax = linspace(0,nmax*dt,plot_num+2);

% % for ii=1:nmax
% for jj=1:npts
%     pressure(:,jj) = (Te + Ti)*n_mat(:,jj)*e;
% end
% for jj=1:npts-1
%     pressure_av(:,jj) = 0.5*(pressure(:,jj) + pressure(:,jj+1));
%     pressure_mat(:,jj) = pressure_av(:,jj) + (1/2)*0.5*(n_mat(:,jj+1)+n_mat(:,jj))*m.*(vx_mat(:,jj).^2);
% end
% % end
% 
% figure(7)
% % levels = linspace((min(vx_mat(:))/(vx_init(2))),(max(vx_mat(:))/max(vx_init)),100);
% % levels = levels/cs;
% levels = linspace(-2.5e-2,0,100);
% % set(gca,'colorscale','log')
% contourf(vxax(2:npts-1),tax,(vx_mat(1:plot_num+2,2:npts-1) - vx_init(2:npts-1))/cs,...
%     'LineColor','none')
% xlabel('Position (m)','Fontsize',16); ylabel('Time (s)','Fontsize',16)
% colorbar;
% 
% 
% 
% figure(8)
% % levels = linspace(round(min(n_mat(:)),-3),round(max(n_mat(:)),-3),25);
% % levels = linspace(min(n_mat(:)),max(n_mat(:)),100);
% levels = linspace(-3.0e15,3.0e15,100);
% % set(gca,'colorscale','log')
% contourf(nxax(2:npts-1),tax,n_mat(1:plot_num+2,2:npts-1) - n_init(2:npts-1),...
%     'LineColor','none')
% xlabel('Position (m)','Fontsize',16); ylabel('Time (s)','Fontsize',16)
% colorbar

% figure(10)
% % levels = linspace((min(pressure_mat(:))),(max(pressure_mat(:))),25);
% levels = linspace(min(pressure_mat(:)),max(pressure_mat(:)),25);
% contourf(vxax,tax,pressure_mat,levels,'LineColor','none')
% xlabel('Position (m)','Fontsize',16); ylabel('Time (s)','Fontsize',16)
% colorbar

%%

function [ans] = grad(n,dx,npts)
    ans = (n(2:npts) - n(1:npts-1))/dx;
end

function [ans] = grad2(n,dx,npts)
    cen_diff = (n(3:npts) - n(1:npts-2))/(2.0*dx);
    fwd_diff = (-3*n(1) + 4*n(2) - n(3))/(2.0*dx);
    bwd_diff = (3*n(npts) - 4*n(npts-1) + n(npts-2))/(2.0*dx);
    ans = [fwd_diff, cen_diff, bwd_diff];
end

function [ans] = avg(n,npts)
    ans = (n(2:npts) + n(1:npts-1))/2.0;
end

function [ans] = pond_source(m,omega,q,Efield,dx,npts)
    pond_const = (1.0/4.0)*((q^2)/(m*omega^2));
    ans = (1.0/m)*pond_const*grad(Efield,dx,npts);
end

function [ans] = source_stag(n,q,Te,Ti,m,npts,dx)
    ans = -((Te + Ti)*q./(m*avg(n,npts))).*(grad(n,dx,npts));
end

function [ans] = source_col(n,q,Te,Ti,m,npts,dx)
    ans = -((Te + Ti)*q./(m*n)).*(grad2(n,dx,npts));
end

% end




