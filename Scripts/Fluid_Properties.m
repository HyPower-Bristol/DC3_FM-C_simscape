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


%% N2 LIMITS
max_pres_N2_bar = 318;
min_pres_N2_bar = 0.5;
min_temp_N2_K = 100;
max_temp_N2_K = 400;