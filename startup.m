%% Startup.m
%   Adam Driver 06/02/26
%   
%   This script runs all files necessary to setup the model when opened. 

%% Loading File Structure
disp("Loading DC3 FMC Model")
[currentPath, ~, ~] = fileparts(mfilename('fullpath'));
cd(currentPath);
addpath(genpath(currentPath));
fprintf('Project Root set to: %s\n', pwd);


