%%  Thermofluids_Parameters_LV.m
%   Adam Driver 06/02/26
%   Natnael Amanuel 19/02/26 -> Now
%   This script holds all model parameters for the LV Simscape model. This
%   is implemented separately to GS to enable easier integration with the
%   MBSE model. 

%Note current cs_areas for the three tanks are not final (ref Niall)
%Note assumption fuel and oxidiser masses are dependent on the development of type II COPV
% fuel + oxidiser mass is around 11->12 kg  (ref 4.4 tank design overview DC3-PDR)

%%nitrogen (N2) tank parameters

%starting nitrogen tank pressure being 300 bar then drops linearly as run tank 
%remains steady at a 50 bar demand (ref figure 46 of DC3-PDR) -> the run-tank referring to the propellant tank either fuel or oxidiser
%nitrogen tank mass = 1.93 kg (ref 11.Appendices A.2 propulsion overview of DC3-PDR)
%nitrogen burst disc threshold 350 bar (ref 4.3 feed system)
%still needed length - not provided - making assumption for now**
N2_TANK_pressure = 30000000; %tank pressure, Pa
N2_BURST_DISC_pressure = 35000000; % burst disc pressure, Pa
N2_TANK_mass = 1.93;  % tank mass, kg
N2_TANK_cs_area = 0.029559; %<----may not apply %tank cross sectional area, m^2 -> from diameter of 194mm
N2_TANK_inlet_cs_area = NaN; %inlet cross-sectional area, m^2
N2_TANK_length = 0.3; %tank length, m
N2_TANK_inlet_h = NaN; %inlet height, m
N2_TANK_volume = 0.0088678; %tank volume, m^3 <- derived value

%%Oxidiser, Ox, N20 tank parameters

%oxidiser tank mass = 6kg (ref A.4 weight breakdown DC3-PDR)
%oxidiser volume = 14.4 l (litres) (ref A.2 propulsion overview DC3-PDR)
%oxidiser tank length = 525 mm (ref A.3 length breakdown DC3-PDR)
%oxidiser tank pressure assumed 50 bar (ref figure 46 of DC3-PDR)
%oxidiser burst disc threshold 65 bar (ref 4.3 feed system)
%in the case where the nitrous pressure in the oxidiser tank exceeds 58 bar
%then close GS Ox fill(if still filling) and vent Ox tank (ref C.9.7 Nitrous Overpress p112 DC3-PDR)
Ox_TANK_pressure = 5000000; %tank pressure, Pa
OX_BURST_DISC_pressure = 6500000; % burst disc pressure, Pa
OX_TANK_SAFETY_pressure = 5800000; % **double check if modelling this -conditional pressure, Pa
OX_TANK_mass = 6; %tank mass, kg
OX_volume = 14.4; %oxidiser volume, l
Ox_TANK_cs_area = 0.029559; %tank cross sectional area, m^2 -> from diameter of 194mm
Ox_TANK_inlet_cs_area = NaN; %inlet cross-sectional area, m^2
OX_TANK_length = 0.525; %tank length, m
OX_TANK_inlet_h = NaN; %inlet height, m
OX_TANK_volume = 0.0155186; %tank volume, m^3 <-derived value


%%Fuel tank parameters

%also known as the IPA (isopropyl alcohol) tank
%fuel (IPA) mass is 5kg (ref A.4 weight breakdown DC3-PDR)
%fuel volume = 5.28 l (litres) ref A.2 propulsion overview DC3-PDR)
%fuel tank length = 175mm (A.3 length breakdown DC3-PDR)
%fuel tank pressure 50 bar (ref 4.7.4 performance analysis DC3-PDR)
%fuel burst disc threshold 65 bar (ref 4.3 feed system)
FUEL_TANK_pressure = 5000000; %tank pressure, Pa
FUEL_BURST_DISC_pressure = 6500000; % burst disc pressure, Pa
FUEL_TANK_mass = 5; %tank mass, kg
FUEL_volume = 5.28; %fuel volume, l 
FUEL_TANK_cs_area =0.029559; %tank cross sectional area, m^2 -> from diameter of 194mm
FUEL_TANK_inlet_cs_area = NaN; %inlet cross-sectional area, m^2
FUEL_TANK_length = 0.175; %tank length, m
FUEL_TANK_inlet_h = NaN; %inlet height, m
FUEL_TANK_volume = 0.00517287; %tank volume, m^3 <-derived value