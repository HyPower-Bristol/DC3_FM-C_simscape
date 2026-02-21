%% Fluid_Properties.m
%   Adam Driver 06/02/26
%   
%   This file should hold fluid property LUTs or Load Relevant Files


%% Load LUTs

load("EthanolTable.mat");
load("N2GasTables.mat");
load("N2OTables.mat");

%%
ATMOSPHERIC_PRESS_Pa = 101325;                                             % Atmospheric Pressure, Pascals