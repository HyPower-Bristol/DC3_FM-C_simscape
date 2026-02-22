%%  Thermofluids_Parameters_GS.m
%   Adam Driver 06/02/26
%   
%   This script holds all model parameters for the GS Simscape model. 


%% SHARED PARAMETERS
% QD Parameters
QD_Diameter_m = 0.004;                     % From DC2 Model
QD_OrificeArea_m2 = QD_Diameter_m^2/4*pi;  % Mathematical Relationship
QD_LeakageRatio = 1e-12;                   % From DC2 Model

% Hose Parameters
GS_Hose_Length_m = 5;                       % From DC2 Model
GS_Hose_Thickness_m = 0.004;                % From DC2 Model
GS_Hose_MassPerLength_kgpm = N2_pipe_diameter*pi*GS_hose_thickness*Ally_density; % Mathematical Relationship
GS_Hose_SurfaceAreaPerLength = N2_pipe_diameter*pi;                              % Mathematical Relationship

%% GS FUEL SUBSYSTEM





%% GS OXIDISER SUBSYSTEM





%% GS PRESSURANT SUBSYSTEM