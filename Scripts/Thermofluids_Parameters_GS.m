%%  Thermofluids_Parameters_GS.m
%   Adam Driver 06/02/26
%   
%   This script holds all model parameters for the GS Simscape model. 


%% SHARED PARAMETERS
% QD Parameters
QD_Diameter_m = 0.004;                     % From DC2 Model
QD_OrificeArea_m2 = QD_Diameter_m^2/4*pi;  % Mathematical Relationship
QD_LeakageRatio = 1e-12;                   % From DC2 Model
Pressurant_pipe_diameter_m = 0.005;                  % TODO: update to new standards
GS_hose_thickness_m = 0.008;                 % TODO: update to new standards
Pressurant_pipe_area_m2 = Pressurant_pipe_diameter_m^2*pi/4; % Mathematical Relationship

% Hose Parameters
GS_Hose_Length_m = 5;                       % From DC2 Model
GS_Hose_Thickness_m = 0.004;                % From DC2 Model
GS_Hose_MassPerLength_kgpm = Pressurant_pipe_diameter_m*pi*GS_hose_thickness_m*Ally_density_kgpm3; % Mathematical Relationship
GS_Hose_SurfaceAreaPerLength = Pressurant_pipe_diameter_m*pi;                              % Mathematical Relationship

%% GS FUEL SUBSYSTEM
GS_Initial_Fuel_Temp_K = 300;
GS_Initial_Fuel_Pressure_bar = 50;





%% GS OXIDISER SUBSYSTEM
GS_Initial_Ox_Temp_K = 300;
GS_Initial_Ox_Pressure_bar = 50;




%% GS PRESSURANT SUBSYSTEM
GS_Initial_Pressurant_Temp_K = 300;
GS_Initial_Pressurant_Pressure_bar = 300;
GS_Pressurant_Tank_Volume_L = 50;    % TBC