%% Advanced Validation Suite for Injector_Oxidizer_NHNE


% Ensure N2OTables is in your workspace before running this
% load('Your_Data_File.mat'); 

% Mock physical injector constants
Inj_Cd_Ox = 0.62;
Inj_A_Ox_m2 = 6.5e-5; 

% Baseline operating points
Pc_sweep = linspace(5e5, 52e5, 150); % 5 to 52 bar sweep

%% =========================================================================
%% CHECK 1: Temperature Dependency & Saturation Shift
%% =========================================================================
% We test cold (283.15 K), nominal (293.15 K), and hot (303.15 K) states.
% Saturation pressures for N2O roughly map to: ~38 bar, ~45 bar, and ~54 bar.
T_test = [283.15, 293.15, 303.15]; 
Psat_test = [38e5, 45e5, 54e5]; 
labels_T = {'Cold (10°C / 283K)', 'Nominal (20°C / 293K)', 'Hot (30°C / 303K)'};
colors = {'b', 'g', 'r'};

figure('Name', 'Check 1: Temperature Dependency', 'NumberTitle', 'off');
hold on;

for k = 1:3
    mdot_sweep = zeros(size(Pc_sweep));
    for i = 1:length(Pc_sweep)
        mdot_sweep(i) = test_wrapper_NHNE(Pc_sweep(i), Psat_test(k), T_test(k), 50e5, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables);
    end
    plot(Pc_sweep/1e5, mdot_sweep, colors{k}, 'LineWidth', 2, 'DisplayName', labels_T{k});
end

grid on; box on;
xlabel('Chamber Pressure (bar)');
ylabel('Oxidizer Mass Flow (kg/s)');
title('Check 1: Temperature Dependency & Saturation Shift');
legend('Location', 'southwest');

%% =========================================================================
%% CHECK 2: Upstream Feed Pressure Scaling
%% =========================================================================
% Keep nominal temp (293.15 K, Psat = 45 bar) but change feed pressure
P_feed_test = [40e5, 50e5, 60e5]; 
labels_P = {'Low Feed (40 bar)', 'Nominal Feed (50 bar)', 'High Feed (60 bar)'};

figure('Name', 'Check 2: Feed Pressure Scaling', 'NumberTitle', 'off');
hold on;

for k = 1:3
    mdot_sweep = zeros(size(Pc_sweep));
    for i = 1:length(Pc_sweep)
        mdot_sweep(i) = test_wrapper_NHNE(Pc_sweep(i), 45e5, 293.15, P_feed_test(k), Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables);
    end
    plot(Pc_sweep/1e5, mdot_sweep, 'Color', colors{k}, 'LineWidth', 2, 'DisplayName', labels_P{k});
end

grid on; box on;
xlabel('Chamber Pressure (bar)');
ylabel('Oxidizer Mass Flow (kg/s)');
title('Check 2: Upstream Run Tank Pressure Scaling');
legend('Location', 'southwest');

%% =========================================================================
%% CHECK 3: Aerodynamic Throat Choking Limit
%% =========================================================================
% Track the chosen throat pressure to map the transition out of choking
Pt_sweep = zeros(size(Pc_sweep));

for i = 1:length(Pc_sweep)
    % Call a modified local tracker function to return the selected throat pressure
    [~, Pt_sweep(i)] = test_wrapper_NHNE_with_Pt(Pc_sweep(i), 45e5, 293.15, 50e5, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables);
end

figure('Name', 'Check 3: Choking Boundary', 'NumberTitle', 'off');
plot(Pc_sweep/1e5, Pt_sweep/1e5, 'm', 'LineWidth', 2);
hold on;
plot(Pc_sweep/1e5, Pc_sweep/1e5, 'k--', 'LineWidth', 1.5, 'DisplayName', 'P_t = P_c Boundary');
grid on; box on;
xlabel('Chamber Pressure (bar)');
ylabel('Selected Throat Pressure (bar)');
title('Check 3: Aerodynamic Throat Pressure Choking');

%% =========================================================================
%% Core Function Copies for Standalone Run
%% =========================================================================
function OX_MASS_FLOW_kgps = test_wrapper_NHNE(CHAMBER_PRESS_Pa, P_Sat, OX_ABS_TEMP_K, OX_ABS_PRESS_Pa, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables)
% #########################################################################
% NON-HOMOGENEOUS NON-EQUILIBRIUM (NHNE) DYER OXIDIZER MODEL
% #########################################################################
    %% 1. UPSTREAM STATE EXTRACTION (SUB-COOLED NITROUS)
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
    
    % MULTIPLIERS REMOVED: Using raw table entries
    u_in     = interp1(unorm_col, u_col, unorm_in, 'linear');
    h_in     = u_in + (OX_ABS_PRESS_Pa * v_in); 

    %% 2. SINGLE-PHASE INCOMPRESSIBLE (SPI) LIMIT
    delta_P_SPI = max(0, OX_ABS_PRESS_Pa - CHAMBER_PRESS_Pa); 
    m_dot_SPI   = Inj_Cd_Ox * Inj_A_Ox_m2 * sqrt(2 * rho_in * delta_P_SPI);

    %% 3. HOMOGENEOUS EQUILIBRIUM MODEL (HEM) LIMIT
    P_grid_Pa    = N2OTables.p * 1e6; 
    s_liquid_sat = N2OTables.liquid.s(end, :); 
    v_liquid_sat = N2OTables.liquid.v(end, :); 
    s_vapor_sat  = N2OTables.vapour.s(1, :);    
    v_vapor_sat  = N2OTables.vapour.v(1, :);   
    
    % FIX: Extract saturation boundaries directly from the main U matrix columns 
    % to guarantee 100% unit alignment with u_in
    u_liquid_sat = N2OTables.liquid.U(:, end).'; 
    u_vapor_sat  = N2OTables.vapour.U(:, 1).';  

    if mean(v_liquid_sat) > 100
        v_liquid_sat = 1 ./ v_liquid_sat;
        v_vapor_sat  = 1 ./ v_vapor_sat;
    end

    % Boundary set by Chamber Pressure
    P_lower_lim = max(CHAMBER_PRESS_Pa, min(P_grid_Pa)); 
    P_upper_lim = min(P_Sat, max(P_grid_Pa));
    
    max_flux    = 0;
    best_Pt     = 0;
    best_ht     = 0;
    best_rhot   = 0;
    best_xt     = 0;
    best_deltah = 0;

    if P_lower_lim >= P_upper_lim
        m_dot_HEM = m_dot_SPI;
    else
        % Scan down from high pressure (Psat) to low pressure (Pc)
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
            
            v_t   = (1 - x_t)*vl + x_t*vv;
            u_t   = (1 - x_t)*ul + x_t*uv;
            rho_t = 1 / v_t;
            h_t   = u_t + (P_guess_Pa * v_t); 
            
            delta_h = max(0, h_in - h_t);
            current_flux = rho_t * sqrt(2 * delta_h);
            
            if current_flux > max_flux
                max_flux     = current_flux;
                best_Pt      = P_guess_Pa;
                best_ht      = h_t;
                best_rhot    = rho_t;
                best_xt      = x_t;
                best_deltah  = delta_h;
            end
        end
        m_dot_HEM = Inj_Cd_Ox * Inj_A_Ox_m2 * max_flux;
    end

    %% 4. NON-EQUILIBRIUM BLENDING & FINAL MASS FLOW
    if CHAMBER_PRESS_Pa >= P_Sat
        kappa = 0;
        OX_MASS_FLOW_kgps = m_dot_SPI;
    else
        kappa = sqrt((OX_ABS_PRESS_Pa - P_Sat) / (P_Sat - CHAMBER_PRESS_Pa));
        OX_MASS_FLOW_kgps = (1 / (1 + kappa)) * m_dot_SPI + (kappa / (1 + kappa)) * m_dot_HEM;
    end
end

function [OX_MASS_FLOW_kgps, best_Pt] = test_wrapper_NHNE_with_Pt(CHAMBER_PRESS_Pa, P_Sat, OX_ABS_TEMP_K, OX_ABS_PRESS_Pa, Inj_Cd_Ox, Inj_A_Ox_m2, N2OTables)
% #########################################################################
% NON-HOMOGENEOUS NON-EQUILIBRIUM (NHNE) DYER OXIDIZER MODEL
% #########################################################################
    %% 1. UPSTREAM STATE EXTRACTION (SUB-COOLED NITROUS)
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
    
    % MULTIPLIERS REMOVED: Using raw table entries
    u_in     = interp1(unorm_col, u_col, unorm_in, 'linear');
    h_in     = u_in + (OX_ABS_PRESS_Pa * v_in); 

    %% 2. SINGLE-PHASE INCOMPRESSIBLE (SPI) LIMIT
    delta_P_SPI = max(0, OX_ABS_PRESS_Pa - CHAMBER_PRESS_Pa); 
    m_dot_SPI   = Inj_Cd_Ox * Inj_A_Ox_m2 * sqrt(2 * rho_in * delta_P_SPI);

    %% 3. HOMOGENEOUS EQUILIBRIUM MODEL (HEM) LIMIT
    P_grid_Pa    = N2OTables.p * 1e6; 
    s_liquid_sat = N2OTables.liquid.s(end, :); 
    v_liquid_sat = N2OTables.liquid.v(end, :); 
    s_vapor_sat  = N2OTables.vapour.s(1, :);    
    v_vapor_sat  = N2OTables.vapour.v(1, :);   
    
    % FIX: Extract saturation boundaries directly from the main U matrix columns 
    % to guarantee 100% unit alignment with u_in
    u_liquid_sat = N2OTables.liquid.U(:, end).'; 
    u_vapor_sat  = N2OTables.vapour.U(:, 1).';  

    if mean(v_liquid_sat) > 100
        v_liquid_sat = 1 ./ v_liquid_sat;
        v_vapor_sat  = 1 ./ v_vapor_sat;
    end

    % Boundary set by Chamber Pressure
    P_lower_lim = max(CHAMBER_PRESS_Pa, min(P_grid_Pa)); 
    P_upper_lim = min(P_Sat, max(P_grid_Pa));
    
    max_flux    = 0;
    best_Pt     = 0;
    best_ht     = 0;
    best_rhot   = 0;
    best_xt     = 0;
    best_deltah = 0;

    if P_lower_lim >= P_upper_lim
        m_dot_HEM = m_dot_SPI;
    else
        % Scan down from high pressure (Psat) to low pressure (Pc)
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
            
            v_t   = (1 - x_t)*vl + x_t*vv;
            u_t   = (1 - x_t)*ul + x_t*uv;
            rho_t = 1 / v_t;
            h_t   = u_t + (P_guess_Pa * v_t); 
            
            delta_h = max(0, h_in - h_t);
            current_flux = rho_t * sqrt(2 * delta_h);
            
            if current_flux > max_flux
                max_flux     = current_flux;
                best_Pt      = P_guess_Pa;
                best_ht      = h_t;
                best_rhot    = rho_t;
                best_xt      = x_t;
                best_deltah  = delta_h;
            end
        end
        m_dot_HEM = Inj_Cd_Ox * Inj_A_Ox_m2 * max_flux;
    end

    %% 4. NON-EQUILIBRIUM BLENDING & FINAL MASS FLOW
    if CHAMBER_PRESS_Pa >= P_Sat
        kappa = 0;
        OX_MASS_FLOW_kgps = m_dot_SPI;
    else
        kappa = sqrt((OX_ABS_PRESS_Pa - P_Sat) / (P_Sat - CHAMBER_PRESS_Pa));
        OX_MASS_FLOW_kgps = (1 / (1 + kappa)) * m_dot_SPI + (kappa / (1 + kappa)) * m_dot_HEM;
    end

    %% 5. COMPREHENSIVE ADVANCED DIAGNOSTIC LOGGING ENGINE
    if abs(CHAMBER_PRESS_Pa - 1.5e6) < 1e5 % Isolates print message to your 15 bar test step
        fprintf('\n==================================================\n');
        fprintf('       NHNE RUNTIME DIAGNOSTIC SNAPSHOT           \n');
        fprintf('==================================================\n');
        fprintf('--- OPERATING POINTS ---\n');
        fprintf('  Inlet Pressure (Pa):       %.2f\n', OX_ABS_PRESS_Pa);
        fprintf('  Saturation Pressure (Pa):  %.2f\n', P_Sat);
        fprintf('  Chamber Pressure (Pa):     %.2f\n', CHAMBER_PRESS_Pa);
        fprintf('  Inlet Temperature (K):     %.2f\n', OX_ABS_TEMP_K);
        
        fprintf('\n--- UPSTREAM STATE ---\n');
        fprintf('  v_in (m3/kg):              %.8f\n', v_in);
        fprintf('  rho_in (kg/m3):            %.2f\n', rho_in);
        fprintf('  u_in (Table Scale):        %.2f\n', u_in);
        fprintf('  P*v Work Term (Pa*v):      %.2f\n', OX_ABS_PRESS_Pa * v_in);
        fprintf('  h_in Total (Computed):     %.2f\n', h_in);
        fprintf('  s_in (J/kg*K):             %.2f\n', s_in);

        fprintf('\n--- OPTIMIZATION SEARCH PROFILE ---\n');
        fprintf('  Search Lower Limit (Pa):   %.2f\n', P_lower_lim);
        fprintf('  Search Upper Limit (Pa):   %.2f\n', P_upper_lim);
        fprintf('  Selected Throat Press (Pa):%.2f\n', best_Pt);

        fprintf('\n--- CHOKED THROAT PROPERTIES (HEM Peak) ---\n');
        fprintf('  Throat x Quality:          %.6f\n', best_xt);
        fprintf('  Throat rho_t (kg/m3):      %.2f\n', best_rhot);
        fprintf('  Throat h_t Total:          %.2f\n', best_ht);
        fprintf('  Evaluated delta_h (J/kg):  %.2f\n', best_deltah);
        fprintf('  Max Flux Achieved (kg/m2s):%.2f\n', max_flux);

        fprintf('\n--- BLENDING & FINAL FLOWS ---\n');
        fprintf('  m_dot_SPI Incompressible:  %.4f kg/s\n', m_dot_SPI);
        fprintf('  m_dot_HEM Equilibrium:     %.4f kg/s\n', m_dot_HEM);
        fprintf('  Dyer Weight Parameter (k): %.4f\n', kappa);
        fprintf('  FINAL BLENDED FLOW RATE:   %.4f kg/s\n', OX_MASS_FLOW_kgps);
        fprintf('==================================================\n\n');
    end
end