%% Performance and Accuracy Benchmark: Linear Grid vs. Golden Section Search

% Mock physical injector constants
Inj_Cd_Ox = 0.62;
Inj_A_Ox_m2 = 6.5e-5; 

% Operating parameters (Nominal sub-cooled test condition)
ox_abs_press = 5.0e6;   % 50 bar
Ox_abs_temp  = 293.15;  % 20 degC
P_Sat        = 4.5e6;   % 45 bar saturation

% Define an extensive pressure sweep to simulate a real transient run
Pc_sweep = linspace(0.5e6, 5.2e6, 200); 

%% 1. Profile Method A: Your Original 50-Point Linear Sweep
mdot_linear = zeros(size(Pc_sweep));
tic;
for i = 1:length(Pc_sweep)
    mdot_linear(i) = model_linear_sweep(Pc_sweep(i), P_Sat, Ox_abs_temp, ox_abs_press, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables);
end
t_linear = toc;

%% 2. Profile Method B: Vectorized 10-Iteration Golden Section Search
mdot_golden = zeros(size(Pc_sweep));
tic;
for i = 1:length(Pc_sweep)
    mdot_golden(i) = model_golden_section(Pc_sweep(i), P_Sat, Ox_abs_temp, ox_abs_press, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables);
end
t_golden = toc;

%% 3. Print Performance Metrics
fprintf('==================================================\n');
fprintf('         INJECTOR OPTIMIZATION BENCHMARK          \n');
fprintf('==================================================\n');
fprintf('Total Profiles Evaluated:       %d\n', length(Pc_sweep));
fprintf('Linear Sweep Execution Time:    %.5f seconds\n', t_linear);
fprintf('Golden Section Execution Time:  %.5f seconds\n', t_golden);
fprintf('Speedup Factor:                 %.2fx faster\n', t_linear / t_golden);
fprintf('--------------------------------------------------\n');
max_error = max(abs(mdot_linear - mdot_golden));
fprintf('Maximum Absolute Deviation:     %.6f kg/s\n', max_error);
fprintf('==================================================\n');

%% 4. Plot Comparison Results
figure('Name', 'Optimization Comparison Profile', 'Position', [100, 100, 1000, 500]);

subplot(1,2,1);
plot(Pc_sweep/1e5, mdot_linear, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Linear 50-Point Sweep');
hold on;
plot(Pc_sweep/1e5, mdot_golden, 'r--', 'LineWidth', 2, 'DisplayName', 'Golden Section (10 Iter)');
grid on; box on;
xlabel('Chamber Pressure (bar)');
ylabel('Oxidizer Mass Flow (kg/s)');
title('Mass Flow Profile Matching');
legend('Location', 'southwest');

subplot(1,2,2);
plot(Pc_sweep/1e5, abs(mdot_linear - mdot_golden), 'm-', 'LineWidth', 1.5);
grid on; box on;
xlabel('Chamber Pressure (bar)');
ylabel('Absolute Error Delta (kg/s)');
title('Discretization Accuracy Error Delta');

%% =========================================================================
%% IMPLEMENTATION A: Linear Fixed Grid Sweep
%% =========================================================================
function OX_MASS_FLOW_kgps = model_linear_sweep(CHAMBER_PRESS_Pa, P_Sat, OX_ABS_TEMP_K, OX_ABS_PRESS_Pa, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables)
    P_in_MPa = OX_ABS_PRESS_Pa / 1e6;
    [~, p_idx] = min(abs(N2OTables.p - P_in_MPa));
    
    T_col     = N2OTables.liquid.T(:, p_idx);
    unorm_col = N2OTables.liquid.unorm;
    s_col     = N2OTables.liquid.s(:, p_idx);
    v_col     = N2OTables.liquid.v(:, p_idx);
    u_col     = N2OTables.liquid.U(p_idx, :).'; 
    
    T_in_clamped = max(min(OX_ABS_TEMP_K, max(T_col)), min(T_col));
    unorm_in = interp1(T_col, unorm_col, T_in_clamped, 'linear');
    s_in     = interp1(unorm_col, s_col, unorm_in, 'linear'); 
    
    if mean(v_col) > 100
        v_in = 1 / interp1(unorm_col, v_col, unorm_in, 'linear');
    else
        v_in = interp1(unorm_col, v_col, unorm_in, 'linear');
    end
    rho_in   = 1 / v_in;
    u_in     = interp1(unorm_col, u_col, unorm_in, 'linear');
    h_in     = u_in + (OX_ABS_PRESS_Pa * v_in); 

    delta_P_SPI = max(0, OX_ABS_PRESS_Pa - CHAMBER_PRESS_Pa); 
    m_dot_SPI   = Inj_Cd_Ox * Inj_A_Ox_m2 * sqrt(2 * rho_in * delta_P_SPI);

    P_grid_Pa    = N2OTables.p * 1e6; 
    s_liquid_sat = N2OTables.liquid.s(end, :); 
    v_liquid_sat = N2OTables.liquid.v(end, :); 
    s_vapor_sat  = N2OTables.vapour.s(1, :);    
    v_vapor_sat  = N2OTables.vapour.v(1, :);   
    u_liquid_sat = N2OTables.liquid.U(:, end).'; 
    u_vapor_sat  = N2OTables.vapour.U(:, 1).';  

    if mean(v_liquid_sat) > 100
        v_liquid_sat = 1 ./ v_liquid_sat;
        v_vapor_sat  = 1 ./ v_vapor_sat;
    end

    P_lower_lim = max(CHAMBER_PRESS_Pa, min(P_grid_Pa)); 
    P_upper_lim = min(P_Sat, max(P_grid_Pa));
    
    if P_lower_lim >= P_upper_lim
        m_dot_HEM = m_dot_SPI;
    else
        max_flux = 0;
        P_steps_Pa = linspace(P_upper_lim, P_lower_lim, 50);
        for i = 1:50
            P_guess_Pa = P_steps_Pa(i);
            sl = interp1(P_grid_Pa, s_liquid_sat, P_guess_Pa, 'linear');
            sv = interp1(P_grid_Pa, s_vapor_sat,  P_guess_Pa, 'linear');
            vl = interp1(P_grid_Pa, v_liquid_sat, P_guess_Pa, 'linear');
            vv = interp1(P_grid_Pa, v_vapor_sat,  P_guess_Pa, 'linear');
            ul = interp1(P_grid_Pa, u_liquid_sat, P_guess_Pa, 'linear');
            uv = interp1(P_grid_Pa, u_vapor_sat,  P_guess_Pa, 'linear');
            
            if sv > sl
                x_t = (s_in - sl) / (sv - sl);
                x_t = max(0, min(1, x_t)); 
            else
                x_t = 0;
            end
            v_t = (1 - x_t)*vl + x_t*vv;
            u_t = (1 - x_t)*ul + x_t*uv;
            rho_t = 1 / v_t;
            h_t = u_t + (P_guess_Pa * v_t); 
            delta_h = max(0, h_in - h_t);
            current_flux = rho_t * sqrt(2 * delta_h);
            if current_flux > max_flux
                max_flux = current_flux;
            end
        end
        m_dot_HEM = Inj_Cd_Ox * Inj_A_Ox_m2 * max_flux;
    end

    if CHAMBER_PRESS_Pa >= P_Sat
        OX_MASS_FLOW_kgps = m_dot_SPI;
    else
        kappa = sqrt((OX_ABS_PRESS_Pa - P_Sat) / (P_Sat - CHAMBER_PRESS_Pa));
        OX_MASS_FLOW_kgps = (1 / (1 + kappa)) * m_dot_SPI + (kappa / (1 + kappa)) * m_dot_HEM;
    end
end

%% =========================================================================
%% IMPLEMENTATION B: High-Performance Vectorized Golden Section Search
%% =========================================================================
function OX_MASS_FLOW_kgps = model_golden_section(CHAMBER_PRESS_Pa, P_Sat, OX_ABS_TEMP_K, OX_ABS_PRESS_Pa, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables)
    % Upstream properties extraction
    P_in_MPa = OX_ABS_PRESS_Pa / 1e6;
    [~, p_idx] = min(abs(N2OTables.p - P_in_MPa));
    
    T_col     = N2OTables.liquid.T(:, p_idx);
    unorm_col = N2OTables.liquid.unorm;
    s_col     = N2OTables.liquid.s(:, p_idx);
    v_col     = N2OTables.liquid.v(:, p_idx);
    u_col     = N2OTables.liquid.U(p_idx, :).'; 
    
    T_in_clamped = max(min(OX_ABS_TEMP_K, max(T_col)), min(T_col));
    unorm_in = interp1(T_col, unorm_col, T_in_clamped, 'linear');
    s_in     = interp1(unorm_col, s_col, unorm_in, 'linear'); 
    
    if mean(v_col) > 100
        v_in = 1 / interp1(unorm_col, v_col, unorm_in, 'linear');
    else
        v_in = interp1(unorm_col, v_col, unorm_in, 'linear');
    end
    rho_in   = 1 / v_in;
    u_in     = interp1(unorm_col, u_col, unorm_in, 'linear');
    h_in     = u_in + (OX_ABS_PRESS_Pa * v_in); 

    % SPI Limit
    delta_P_SPI = max(0, OX_ABS_PRESS_Pa - CHAMBER_PRESS_Pa); 
    m_dot_SPI   = Inj_Cd_Ox * Inj_A_Ox_m2 * sqrt(2 * rho_in * delta_P_SPI);

    % Establish boundaries for HEM search
    P_grid_Pa    = N2OTables.p * 1e6; 
    s_liquid_sat = N2OTables.liquid.s(end, :); 
    v_liquid_sat = N2OTables.liquid.v(end, :); 
    s_vapor_sat  = N2OTables.vapour.s(1, :);    
    v_vapor_sat  = N2OTables.vapour.v(1, :);   
    u_liquid_sat = N2OTables.liquid.U(:, end).'; 
    u_vapor_sat  = N2OTables.vapour.U(:, 1).';  

    if mean(v_liquid_sat) > 100
        v_liquid_sat = 1 ./ v_liquid_sat;
        v_vapor_sat  = 1 ./ v_vapor_sat;
    end

    P_lower_lim = max(CHAMBER_PRESS_Pa, min(P_grid_Pa)); 
    P_upper_lim = min(P_Sat, max(P_grid_Pa));
    
    if P_lower_lim >= P_upper_lim
        m_dot_HEM = m_dot_SPI;
    else
        % Golden Ratio Search Constants
        invphi = 0.618033988749895; % 1/phi
        
        % Initialization of intervals
        a = P_lower_lim;
        b = P_upper_lim;
        h = b - a;
        
        % Compute initial interior points
        P1 = b - invphi * h;
        P2 = a + invphi * h;
        
        % Vectorized properties collection for both interior points simultaneously
        P_vec = [P1, P2];
        sl = interp1(P_grid_Pa, s_liquid_sat, P_vec, 'linear');
        sv = interp1(P_grid_Pa, s_vapor_sat,  P_vec, 'linear');
        vl = interp1(P_grid_Pa, v_liquid_sat, P_vec, 'linear');
        vv = interp1(P_grid_Pa, v_vapor_sat,  P_vec, 'linear');
        ul = interp1(P_grid_Pa, u_liquid_sat, P_vec, 'linear');
        uv = interp1(P_grid_Pa, u_vapor_sat,  P_vec, 'linear');
        
        % Vectorized properties evaluation
        x_t = (s_in - sl) ./ (sv - sl);
        x_t(sv <= sl) = 0;
        x_t = max(0, min(1, x_t));
        
        v_t = (1 - x_t).*vl + x_t.*vv;
        u_t = (1 - x_t).*ul + x_t.*uv;
        rho_t = 1 ./ v_t;
        h_t = u_t + (P_vec .* v_t);
        
        delta_h = max(0, h_in - h_t);
        flux_vec = rho_t .* sqrt(2 * delta_h);
        
        f1 = flux_vec(1);
        f2 = flux_vec(2);
        
        % 10 Fixed Iterations (Slices intervals by ~99% accuracy precision)
        for iter = 1:10
            h = invphi * h;
            if f1 > f2
                b = P2;
                P2 = P1;
                f2 = f1;
                P1 = b - invphi * h;
                
                % Single vectorized calculation step for the newly exposed point
                sl_1 = interp1(P_grid_Pa, s_liquid_sat, P1, 'linear');
                sv_1 = interp1(P_grid_Pa, s_vapor_sat,  P1, 'linear');
                vl_1 = interp1(P_grid_Pa, v_liquid_sat, P1, 'linear');
                vv_1 = interp1(P_grid_Pa, v_vapor_sat,  P1, 'linear');
                ul_1 = interp1(P_grid_Pa, u_liquid_sat, P1, 'linear');
                uv_1 = interp1(P_grid_Pa, u_vapor_sat,  P1, 'linear');
                
                x_t1 = (sv_1 > sl_1) * max(0, min(1, (s_in - sl_1) / (sv_1 - sl_1)));
                v_t1 = (1 - x_t1)*vl_1 + x_t1*vv_1;
                h_t1 = ((1 - x_t1)*ul_1 + x_t1*uv_1) + (P1 * v_t1);
                f1 = (1 / v_t1) * sqrt(2 * max(0, h_in - h_t1));
            else
                a = P1;
                P1 = P2;
                f1 = f2;
                P2 = a + invphi * h;
                
                % Single vectorized calculation step for the newly exposed point
                sl_2 = interp1(P_grid_Pa, s_liquid_sat, P2, 'linear');
                sv_2 = interp1(P_grid_Pa, s_vapor_sat,  P2, 'linear');
                vl_2 = interp1(P_grid_Pa, v_liquid_sat, P2, 'linear');
                vv_2 = interp1(P_grid_Pa, v_vapor_sat,  P2, 'linear');
                ul_2 = interp1(P_grid_Pa, u_liquid_sat, P2, 'linear');
                uv_2 = interp1(P_grid_Pa, u_vapor_sat,  P2, 'linear');
                
                x_t2 = (sv_2 > sl_2) * max(0, min(1, (s_in - sl_2) / (sv_2 - sl_2)));
                v_t2 = (1 - x_t2)*vl_2 + x_t2*vv_2;
                h_t2 = ((1 - x_t2)*ul_2 + x_t2*uv_2) + (P2 * v_t2);
                f2 = (1 / v_t2) * sqrt(2 * max(0, h_in - h_t2));
            end
        end
        m_dot_HEM = Inj_Cd_Ox * Inj_A_Ox_m2 * max(f1, f2);
    end

    % Dyer Blending Rule Implementation
    if CHAMBER_PRESS_Pa >= P_Sat
        OX_MASS_FLOW_kgps = m_dot_SPI;
    else
        kappa = sqrt((OX_ABS_PRESS_Pa - P_Sat) / (P_Sat - CHAMBER_PRESS_Pa));
        OX_MASS_FLOW_kgps = (1 / (1 + kappa)) * m_dot_SPI + (kappa / (1 + kappa)) * m_dot_HEM;
    end
end