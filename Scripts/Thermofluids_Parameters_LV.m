%%  Thermofluids_Parameters_LV.m
%   Adam Driver 06/02/26
%   Natnael Amanuel 19/02/26 -> Now
%   
%   This script holds all model parameters for the LV Simscape model. This
%   is implemented separately to GS to enable easier integration with the
%   MBSE model. 


%Note current cs_areas for the three tanks are not final (ref Niall)
%Note assumption fuel and oxidiser masses are dependent on the development of type II COPV
% fuel + oxidiser mass is around 11->12 kg  (ref 4.4 tank design overview DC3-PDR)


%% Nitrogen (N2) Tank Parameters

% Starting nitrogen tank pressure being 300 bar then drops linearly as run tank 
% Remains steady at a 50 bar demand (ref figure 46 of DC3-PDR) -> the run-tank referring to the propellant tank
% Nitrogen tank mass = 1.93 kg (ref 11.Appendices A.2 propulsion overview of DC3-PDR)
% Nitrogen burst disc threshold 350 bar (ref 4.3 feed system)
% Still needed length - not provided - making assumption for now**
N2_TANK_pressure = 30000000;           % tank pressure, Pa (done)
N2_BURST_DISC_pressure = 35000000;     % burst disc pressure, Pa (done) [*remember in simscape value/100000]
N2_TANK_mass = 1.93;                   % tank mass, kg
N2_TANK_cs_area = 0.029559;            % <-may not apply % tank cross sectional area, m^2 -> from diameter of 194mm
N2_TANK_inlet_cs_area = NaN;           % inlet cross-sectional area, m^2
N2_TANK_length = 0.3;                  % tank length, m
N2_TANK_inlet_h = NaN;                 % inlet height, m
N2_TANK_volume = 0.0088678;            % tank volume, m^3 <- derived value (done)


%% Oxidiser, Ox, (N20) Tank Parameters

% Oxidiser tank mass = 6kg (ref A.4 weight breakdown DC3-PDR)
% Oxidiser volume = 14.4 l (litres) (ref A.2 propulsion overview DC3-PDR)
% Oxidiser tank length = 525 mm (ref A.3 length breakdown DC3-PDR)
% Oxidiser tank pressure assumed 50 bar (ref figure 46 of DC3-PDR)
% Oxidiser burst disc threshold 65 bar (ref 4.3 feed system)
% In the case where the nitrous pressure in the oxidiser tank exceeds 58 bar
% Then close GS Ox fill(if still filling) and vent Ox tank (ref C.9.7 Nitrous Overpress p112 DC3-PDR)
Ox_TANK_pressure = 5000000;         % Tank pressure, Pa (done)
OX_BURST_DISC_pressure = 6500000;   % Burst disc pressure, Pa (done) [*remember in simscape value/100000]
OX_TANK_SAFETY_pressure = 5800000;  % **double check if modelling this -conditional pressure, Pa
OX_TANK_mass = 6;                   % Tank mass, kg
OX_volume = 14.4;                   % Oxidiser volume, l
Ox_TANK_cs_area = 0.029559;         % Tank cross sectional area, m^2 -> from diameter of 194mm (done)
Ox_TANK_inlet_cs_area = NaN;        % Inlet cross-sectional area, m^2
OX_TANK_length = 0.525;             % Tank length, m
OX_TANK_inlet_h = NaN;              % Inlet height, m
OX_TANK_volume = 0.0155186;         % Tank volume, m^3 <-derived value (done)
OX_INJECTOR_orifice_area = 80*1e-6; %injector orifice area (m^2) -> from EReg_Tank_Drain_N2O_Init.m
OX_INJECTOR_discharge_coefficient = 0.7; %injector orifice discharge coefficient -> from EReg_Tank_Drain_N2O_Init.m


%% Fuel (IPA) Tank Parameters

% Fuel (IPA) mass is 5kg (ref A.4 weight breakdown DC3-PDR)
% Fuel volume = 5.28 l (litres) ref A.2 propulsion overview DC3-PDR)
% Fuel tank length = 175mm (A.3 length breakdown DC3-PDR)
% Fuel tank pressure 50 bar (ref 4.7.4 performance analysis DC3-PDR)
% Fuel burst disc threshold 65 bar (ref 4.3 feed system)
FUEL_TANK_pressure = 5000000;        % Tank pressure, Pa
FUEL_BURST_DISC_pressure = 6500000;  % Burst disc pressure, Pa
FUEL_TANK_mass = 5;                  % Tank mass, kg
FUEL_volume = 5.28;                  % Fuel volume, l 
FUEL_TANK_cs_area =0.029559;         % Tank cross sectional area, m^2 -> from diameter of 194mm
FUEL_TANK_inlet_cs_area = NaN;       % Inlet cross-sectional area, m^2
FUEL_TANK_length = 0.175;            % Tank length, m
FUEL_TANK_inlet_h = NaN;             % Inlet height, m
FUEL_TANK_volume = 0.00517287;       % Tank volume, m^3 <-derived value
FUEL_INJECTOR_orifice_area = 60*1e-6; %injector orifice area (m^2) -> from EReg_Tank_Drain_Init.m
FUEL_INJECTOR_discharge_coefficient = 0.7; %injector orifice discharge coefficient -> from EReg_Tank_Drain_Init.m
