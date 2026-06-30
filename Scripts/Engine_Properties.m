%% Engine_Properties.m
%   Adam Driver 21/03/26
%   
%   This script contains all parameterized values for the engine model. 


%% Constants
% Injector 
Inj_Cd_Fuel = 0.62;                  % Injector Fuel Discharge Coefficient, assumed
Inj_A_Fuel_m2 = 1.8e-5;              % Injector Fuel Orifice Area, assumed
Inj_Cd_Ox = 0.62;                    % Injector Oxidiser Discharge Coefficient, assumed
Inj_A_Ox_m2 = 6e-5;                  % Injector Oxidiser Orifice Area, assumed

% Engine Sizes
Engine_NozzleExitArea_m2 = 0.006221;        % Engine3_BaseRPAFile.cfg
Engine_NozzleThroatArea_m2 = 0.0018505;     % Engine3_BaseRPAFile.cfg
Chamber_Volume_m3 = 0.00156;                % Engine3_BaseRPAFile.cfg  

% Thermodynamics
Exhaust_Gamma_JpKgK = 1.18;         % Gemini Assumed Value
C_STAR_Ideal_mps = 1550;            % Placeholder until LUT made
Nu_C_STAR_Ideal = 0.9;              % Placeholder Engine Efficiency
g0_mps2 = 9.80665;                  % Standard Value, for conversion of Isp