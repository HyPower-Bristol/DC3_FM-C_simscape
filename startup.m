%% Startup.m
%   Adam Driver 06/02/26
%   
%   This script runs all files necessary to setup the model when opened. 


%% Tidy Up Workspace
clear all
clc


%% Loading File Structure
disp("Loading DC3 FMC Model")
[CurrentPath, ~, ~] = fileparts(mfilename('fullpath'));
cd(CurrentPath);
addpath(genpath(CurrentPath));
fprintf('Project Root set to: %s\n', pwd);


%% Load Relevant Files
Fluid_Properties                  % Load Fluids LUTs
Ally_Properties                   % Load aluminium material proprties
Thermofluids_Parameters_GS        % Load GS Simscape Block Parameters
Thermofluids_Parameters_LV        % Load LV Simscape Block Parameters
