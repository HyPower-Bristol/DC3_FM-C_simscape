%%  Thermofluids_Parameters_GS.m
%   Adam Driver 06/02/26
%   
%   This script holds all model parameters for the GS Simscape model. 


%% SHARED PARAMETERS

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

% QD Parameters
QD_Fuel_Diameter_m = 0.004;                     % From DC2 Model
QD_Fuel_OrificeArea_m2 = QD_Fuel_Diameter_m^2/4*pi;  % Mathematical Relationship
QD_Fuel_LeakageRatio = 1e-12;                   % From DC2 Model
QD_Fuel_DischargeRatio = 0.64;



%% GS OXIDISER SUBSYSTEM
GS_Initial_Ox_Temp_K = 300;
GS_Initial_Ox_Pressure_bar = 50;

% QD Parameters
QD_Ox_Diameter_m = 0.004;                     % From DC2 Model
QD_Ox_OrificeArea_m2 = QD_Ox_Diameter_m^2/4*pi;  % Mathematical Relationship
QD_Ox_LeakageRatio = 1e-12;                   % From DC2 Model
QD_Ox_DischargeRatio = 0.64;

GS_Ox_SOV_Actuator_Gain = 5e-4;
GS_Ox_SOV_Time_Constant = 0.01;
GS_Ox_SOV_Valve_Stroke = 0.005;

GS_Ox_SOV_Diameter_m = 0.004;                     % From DC2 Model
GS_Ox_SOV_OrificeArea_m2 = GS_Ox_SOV_Diameter_m^2/4*pi;  % Mathematical Relationship
GS_Ox_SOV_LeakageRatio = 1e-12;                   % From DC2 Model
GS_Ox_SOV_DischargeRatio = 0.64;


%% GS PRESSURANT SUBSYSTEM
GS_Initial_Pressurant_Temp_K = 300;
GS_Initial_Pressurant_Pressure_bar = 300;

GS_Pressurant_Tank_Volume_L = 50;    % TBC

GS_Pressurant_SOV_Actuator_Gain = 5e-4;
GS_Pressurant_SOV_Time_Constant = 0.01;
GS_Pressurant_SOV_Valve_Stroke = 0.005;

GS_Pressurant_SOV_Diameter_m = 0.004;                     % From DC2 Model
GS_Pressurant_SOV_OrificeArea_m2 = GS_Pressurant_SOV_Diameter_m^2/4*pi;  % Mathematical Relationship
GS_Pressurant_SOV_LeakageRatio = 1e-12;                   % From DC2 Model
GS_Pressurant_SOV_DischargeRatio = 0.64;

% QD Parameters
QD_Pressurant_Diameter_m = 0.004;                     % From DC2 Model
QD_Pressurant_OrificeArea_m2 = QD_Pressurant_Diameter_m^2/4*pi;  % Mathematical Relationship
QD_Pressurant_LeakageRatio = 1e-12;                   % From DC2 Model
QD_Pressurant_DischargeRatio = 0.64;