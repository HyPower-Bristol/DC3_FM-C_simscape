%% E-reg test sequence
%   Man Wui Fung
%   
%   This script runs E-reg controller with simscape model


%% Initial parameters
N2_TANK_pressure = 300*10^5;
Ox_TANK_pressure = 50*10^5; 
OX_TANK_Initial_Mass_frac = 0.25;
FUEL_TANK_Initial_Mass_kg = 1.375; 
FUEL_TANK_pressure = 3*10^5; 
Engine_Initial_Fuel_Pressure_bar = 3;
Engine_Initial_Ox_Pressure_bar = 3;

%% Run sim
run("Test_Models\FMC_Ereg_Test.slx")