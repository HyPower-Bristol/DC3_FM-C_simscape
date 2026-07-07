%%  Generate_Fluid_Properties.m
%   Adam Driver 06/02/26
%   
%   This script formats output of a CEA run script to generate
%   thermodynamic property look-up tables of chamber combustion, to be used
%   in the engine model. 

%
% INLINE SCRIPT: process_cea_hardened.m
% INLINE SCRIPT: process_cea_final_robust.m
% INLINE SCRIPT: process_cea_final_robust.m
% INLINE SCRIPT: process_cea_final_fixed.m
% INLINE SCRIPT: process_cea_column_aligned.m
clear; clc;

txtFile = 'CEA_Hot.txt'; 
matFile = 'CEA_Thermodynamic_LUTs.mat';

if ~exist(txtFile, 'file')
    error('Could not find file: %s', txtFile);
end

fid = fopen(txtFile, 'r');
textContent = fread(fid, '*char').';
fclose(fid);

textContent = strrep(textContent, char(13), ''); 
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
    
    ofTokens = regexp(pageText, 'O/F\s*=\s*([0-9\.]+)', 'tokens');
    if isempty(ofTokens); continue; end
    page_OF = str2double(ofTokens{1}{1});
    
    lines = strsplit(pageText, '\n');
    
    idx_P = []; idx_Gamma = []; idx_Cstar = []; idx_Ivac = []; idx_Isp = [];
    
    for l = 1:length(lines)
        line = strtrim(lines{l});
        
        if startsWith(line, 'POINT ITN') || startsWith(line, 'PINF/PT'); continue; end
        
        if startsWith(line, 'P, BAR')
            numsStr = regexp(line, 'P,\s*BAR\s+([0-9\.\s\-]+)', 'tokens', 'once');
            if ~isempty(numsStr); idx_P{end+1} = str2num(numsStr{1}); end
        elseif startsWith(line, 'GAMMAS')
            numsStr = regexp(line, 'GAMMAS\s+([0-9\.\s\-]+)', 'tokens', 'once');
            if ~isempty(numsStr); idx_Gamma{end+1} = str2num(numsStr{1}); end
        elseif startsWith(line, 'CSTAR, M/SEC')
            numsStr = regexp(line, 'CSTAR,\s*M/SEC\s+([0-9\.\s\-]+)', 'tokens', 'once');
            if ~isempty(numsStr); idx_Cstar{end+1} = str2num(numsStr{1}); end
        elseif startsWith(line, 'IVAC, M/SEC')
            numsStr = regexp(line, 'IVAC,\s*M/SEC\s+([0-9\.\s\-]+)', 'tokens', 'once');
            if ~isempty(numsStr); idx_Ivac{end+1} = str2num(numsStr{1}); end
        elseif startsWith(line, 'ISP, M/SEC')
            numsStr = regexp(line, 'ISP,\s*M/SEC\s+([0-9\.\s\-]+)', 'tokens', 'once');
            if ~isempty(numsStr); idx_Isp{end+1} = str2num(numsStr{1}); end
        end
    end
    
    numSubBlocks = min([length(idx_P), length(idx_Gamma), length(idx_Cstar), length(idx_Ivac), length(idx_Isp)]);
    
    for b = 1:numSubBlocks
        subP     = idx_P{b};
        subGamma = idx_Gamma{b};
        subCstar = idx_Cstar{b};
        subIvac  = idx_Ivac{b};
        subIsp   = idx_Isp{b};
        
        % --- EXPLICIT POSITION MATCHING ---
        % SubP and SubGamma have 3 values: [Chamber, Throat, Exit]
        % Performance parameters have 2 values: [Throat, Exit]
        if length(subP) >= 1 && length(subGamma) >= 1 && length(subCstar) >= 1 && length(subIvac) >= 2 && length(subIsp) >= 2
            list_OF(end+1)     = page_OF;         
            list_P(end+1)      = subP(1);         % Chamber Stagnation Pressure
            list_Gamma(end+1)  = subGamma(1);     % Chamber Gamma
            list_Cstar(end+1)  = subCstar(1);     % C* (Throat value matches chamber property)
            list_Ivac(end+1)   = subIvac(2);      % Nozzle Exit Vacuum Isp
            list_IspOpt(end+1) = subIsp(2);       % Nozzle Exit Optimum Isp
        end
    end
end

if isempty(list_OF)
    error('Data arrays are empty. Verification failed.');
end

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
          
fprintf('Successfully generated pure chamber arrays and saved workspace to %s\n', matFile);
%}
%% PLOTTING
%
matFile = 'CEA_Thermodynamic_LUTs.mat';

if ~exist(matFile, 'file')
    error('Could not find %s.', matFile);
end

load(matFile, 'LUT_Breakpoints_OF', 'LUT_Breakpoints_P_bar', ...
              'LUT_Matrix_Cstar_mps', 'LUT_Matrix_Gamma', ...
              'LUT_Matrix_Ivac_mps', 'LUT_Matrix_Isp_mps');

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

%}