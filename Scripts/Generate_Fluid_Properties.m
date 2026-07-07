%%  Generate_Fluid_Properties.m
%   Adam Driver 06/02/26
%   
%   This script formats output of a CEA run script to generate
%   thermodynamic property look-up tables of chamber combustion, to be used
%   in the engine model. 

% INLINE SCRIPT: process_cea_hardened.m
clear; clc;

txtFile = 'CEA_Hot.txt'; 
matFile = 'CEA_Thermodynamic_LUTs.mat';

if ~exist(txtFile, 'file')
    error('Could not find file: %s', txtFile);
end

fid = fopen(txtFile, 'r');
textContent = fread(fid, '*char').';
fclose(fid);

textContent = upper(textContent);
pages = strsplit(textContent, 'THEORETICAL ROCKET PERFORMANCE');

list_OF     = [];
list_P      = [];
list_Cstar  = [];
list_Gamma  = [];
list_Ivac   = [];
list_IspOpt = [];

for p = 1:length(pages)
    pageText = pages{p};
    
    % Core validation: check for O/F profile
    ofTokens = regexp(pageText, 'O/F\s*=\s*([0-9\.]+)', 'tokens');
    if isempty(ofTokens); continue; end
    page_OF = str2double(ofTokens{1}{1});
    
    % Clear local arrays for this page
    p_vals = []; g_vals = []; c_vals = []; v_vals = []; i_vals = [];
    
    % Split into individual text lines
    lines = strsplit(pageText, '\n');
    
    for l = 1:length(lines)
        line = strtrim(lines{l});
        
        % CRITICAL FILTER: Completely skip iteration trace lines
        if startsWith(line, 'POINT ITN') || startsWith(line, 'Pinf/Pt'); continue; end
        
        % Anchor each variable to its explicit row identifier
        if startsWith(line, 'P, BAR')
            p_vals = str2num(regexprep(line, 'P, BAR', '')); %#ok<ST2NM>
        elseif startsWith(line, 'GAMMAs')
            g_vals = str2num(regexprep(line, 'GAMMAs', '')); %#ok<ST2NM>
        elseif startsWith(line, 'CSTAR, M/SEC')
            c_vals = str2num(regexprep(line, 'CSTAR, M/SEC', '')); %#ok<ST2NM>
        elseif startsWith(line, 'Ivac, M/SEC')
            v_vals = str2num(regexprep(line, 'Ivac, M/SEC', '')); %#ok<ST2NM>
        elseif startsWith(line, 'Isp, M/SEC')
            i_vals = str2num(regexprep(line, 'Isp, M/SEC', '')); %#ok<ST2NM>
        end
    end
    
    % Only synchronize columns if all variables were parsed for this block
    if isempty(p_vals) || isempty(g_vals) || isempty(c_vals) || isempty(v_vals) || isempty(i_vals)
        continue;
    end
    
    nCols = min([length(p_vals), length(g_vals), length(c_vals), length(v_vals), length(i_vals)]);
    for c = 1:nCols
        list_OF(end+1)     = page_OF;         %#ok<AGROW>
        list_P(end+1)      = p_vals(c);       %#ok<AGROW>
        list_Gamma(end+1)  = g_vals(c);       %#ok<AGROW>
        list_Cstar(end+1)  = c_vals(c);       %#ok<AGROW>
        list_Ivac(end+1)   = v_vals(c);       %#ok<AGROW>
        list_IspOpt(end+1) = i_vals(c);       %#ok<AGROW>
    end
end

% Rebuild coordinates securely via column operations
X_of = list_OF(:); Y_p = list_P(:);
Z_cstar = list_Cstar(:); Z_gamma = list_Gamma(:); Z_vac = list_Ivac(:); Z_isp = list_IspOpt(:);

[uniqueCoords, uniqueIdx] = unique([X_of, Y_p], 'rows');
X_of = uniqueCoords(:, 1); Y_p = uniqueCoords(:, 2);
Z_cstar = Z_cstar(uniqueIdx); Z_gamma = Z_gamma(uniqueIdx); Z_vac = Z_vac(uniqueIdx); Z_isp = Z_isp(uniqueIdx);

LUT_Breakpoints_OF    = unique(X_of);
LUT_Breakpoints_P_bar = unique(Y_p);
LUT_Breakpoints_P_Pa  = LUT_Breakpoints_P_bar * 1e5;

[Grid_OF, Grid_P] = ndgrid(LUT_Breakpoints_OF, LUT_Breakpoints_P_bar);

F_Cstar = scatteredInterpolant(X_of, Y_p, Z_cstar, 'linear', 'nearest');
F_Gamma = scatteredInterpolant(X_of, Y_p, Z_gamma, 'linear', 'nearest');
F_Ivac  = scatteredInterpolant(X_of, Y_p, Z_vac, 'linear', 'nearest');
F_Isp   = scatteredInterpolant(X_of, Y_p, Z_isp, 'linear', 'nearest');

LUT_Matrix_Cstar_mps = F_Cstar(Grid_OF, Grid_P);
LUT_Matrix_Gamma     = F_Gamma(Grid_OF, Grid_P);
LUT_Matrix_Ivac_mps  = F_Ivac(Grid_OF, Grid_P);
LUT_Matrix_Isp_mps   = F_Isp(Grid_OF, Grid_P);

save(matFile, 'LUT_Breakpoints_OF', 'LUT_Breakpoints_P_bar', 'LUT_Breakpoints_P_Pa', ...
              'LUT_Matrix_Cstar_mps', 'LUT_Matrix_Gamma', 'LUT_Matrix_Ivac_mps', 'LUT_Matrix_Isp_mps');
          
fprintf('Secure processing complete! Saved to %s\n', matFile);

%% PLOTTING

% Create grid shapes for the plotting canvas
[X_Pressure, Y_OF] = meshgrid(LUT_Breakpoints_P_bar, LUT_Breakpoints_OF);

figure('Name', 'NASA CEA Thermodynamic Lookup Table Grids (Fixed Axis Alignment)', ...
       'Color', [1 1 1], 'Position', [100, 100, 1200, 800]);
   
%% Panel 1: Characteristic Velocity (C*) Surface
subplot(2,2,1);
surf(X_Pressure, Y_OF, LUT_Matrix_Cstar_mps, 'EdgeColor', 'interp', 'FaceAlpha', 0.85);
title('Characteristic Velocity (C*) Grid');
xlabel('Chamber Pressure (bar)'); ylabel('Oxidizer-to-Fuel Ratio (O/F)'); zlabel('C* (m/s)');
grid on; view(-45, 30); colorbar;

%% Panel 2: Specific Heat Ratio (Gamma) Surface
subplot(2,2,2);
surf(X_Pressure, Y_OF, LUT_Matrix_Gamma, 'EdgeColor', 'interp', 'FaceAlpha', 0.85);
title('Chamber Specific Heat Ratio (\gamma) Grid');
xlabel('Chamber Pressure (bar)'); ylabel('Oxidizer-to-Fuel Ratio (O/F)'); zlabel('\gamma');
grid on; view(-45, 30); colorbar;

%% Panel 3: Vacuum Specific Impulse (Ivac) Surface
subplot(2,2,3);
surf(X_Pressure, Y_OF, LUT_Matrix_Ivac_mps, 'EdgeColor', 'interp', 'FaceAlpha', 0.85);
title('Vacuum Specific Impulse (Ivac) Grid');
xlabel('Chamber Pressure (bar)'); ylabel('Oxidizer-to-Fuel Ratio (O/F)'); zlabel('Ivac (m/s)');
grid on; view(-45, 30); colorbar;

%% Panel 4: Optimal Specific Impulse (Isp) Surface
subplot(2,2,4);
surf(X_Pressure, Y_OF, LUT_Matrix_Isp_mps, 'EdgeColor', 'interp', 'FaceAlpha', 0.85);
title('Optimal Specific Impulse (Isp) Grid');
xlabel('Chamber Pressure (bar)'); ylabel('Oxidizer-to-Fuel Ratio (O/F)'); zlabel('Isp (m/s)');
grid on; view(-45, 30); colorbar;

sgtitle('NASA CEA Thermodynamic Surface Profiles (Fixed Axis Alignment)', ...
        'FontSize', 14, 'FontWeight', 'bold');