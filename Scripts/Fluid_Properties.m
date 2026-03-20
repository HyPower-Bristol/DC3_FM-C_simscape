%% Fluid_Properties.m
%   Adam Driver 06/02/26
%   
%   This file should hold fluid property LUTs or Load Relevant Files


%% Load LUTs

load("EthanolTable.mat");
load("N2GasTables.mat");
load("N2OTables.mat");

%% AMBIENT CONDITIONS
GroundAtmosphericPressure_Pa = 101325;    % ISA Sea Level Pressure, Pascals
GroundAmbientTemp_K = 288.15;             % ISA Sea Level Temp, Kelvin

%% Fluid limits
% Note: TBC if this should be defined here, or should be defined another
% way
% Define fluid limits based on the loaded tables
min_pres_N2 = min(N2GasTables.p);
min_temp_N2 = min(N2GasTables.Temp);
max_pres_N2 = max(N2GasTables.p);
max_temp_N2 = max(N2GasTables.Temp);
