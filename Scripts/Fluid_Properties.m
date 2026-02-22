%% Fluid_Properties.m
%   Adam Driver 06/02/26
%   
%   This file should hold fluid property LUTs or Load Relevant Files


%% Load LUTs

load("EthanolTable.mat");
load("N2GasTables.mat");
load("N2OTables.mat");

%% AMBIENT CONDITIONS
AtmosphericPressure_Pa = 101325;    % ISA Sea Level Pressure, Pascals
AmbientTemp_K = 288.15;             % ISA Sea Level Temp, Kelvin
