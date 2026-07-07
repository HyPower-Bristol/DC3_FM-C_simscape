%%  Generate_Fluid_Properties.m
%   Adam Driver 06/02/26
%   
%   This script formats output of a CEA run script to generate
%   thermodynamic property look-up tables of chamber combustion, to be used
%   in the engine model. 

function Generate_Fluid_Properties()
    % Define the source file and destination
    txtFile = 'CEA_Hot.txt';
    matFile = 'CEA_Thermodynamic_LUTs.mat';
    
    if ~exist(txtFile, 'file')
        error('Could not find %s. Place it in your active MATLAB directory.', txtFile);
    end
    
    % Read full file text content
    fid = fopen(txtFile, 'r');
    textContent = fread(fid, '*char').';
    fclose(fid);
    
    % Split the massive text wall by each distinct data page block
    pageDelimiter = 'THEORETICAL ROCKET PERFORMANCE';
    pages = strsplit(textContent, pageDelimiter);
    
    % Initialize flat temporary storage vectors
    raw_OF     = [];
    raw_P      = [];
    raw_Cstar  = [];
    raw_Gamma  = [];
    raw_Ivac   = [];
    raw_IspOpt = [];
    
    % Parse page blocks sequentially
    for p = 2:length(pages)
        pageText = pages{p};
        
        % 1. Extract the current O/F ratio for this whole page block
        ofTokens = regexp(pageText, 'O/F=\s*([0-9\.]+)', 'tokens');
        if isempty(ofTokens); continue; end
        page_OF = str2double(ofTokens{1}{1});
        
        % 2. Extract Chamber Pressures listed on this page (row can have multiple columns)
        pTokens = regexp(pageText, 'P, BAR\s+([0-9\.\s-]+)', 'tokens');
        if isempty(pTokens); continue; end
        % Clean text line from stray scientific formatting and convert to vector
        pLine = regexprep(pTokens{1}{1}, '-\d+', ''); 
        page_Pressures = str2num(pLine); %#ok<ST2NM>
        numCols = length(page_Pressures);
        
        % 3. Extract Chamber Specific Heat Ratios (GAMMAs)
        gammaTokens = regexp(pageText, 'GAMMAs\s+([0-9\.\s-]+)', 'tokens');
        if isempty(gammaTokens); continue; end
        page_Gammas = str2num(gammaTokens{1}{1}); %#ok<ST2NM>
        
        % 4. Extract Characteristic Velocity (CSTAR)
        cstarTokens = regexp(pageText, 'CSTAR, M/SEC\s+([0-9\.\s-]+)', 'tokens');
        if isempty(cstarTokens); continue; end
        page_Cstars = str2num(cstarTokens{1}{1}); %#ok<ST2NM>
        
        % 5. Extract Vacuum Specific Impulse (Ivac)
        ivacTokens = regexp(pageText, 'Ivac, M/SEC\s+([0-9\.\s-]+)', 'tokens');
        if isempty(ivacTokens); continue; end
        page_Ivacs = str2num(ivacTokens{1}{1}); %#ok<ST2NM>
        
        % 6. Extract Optimal Specific Impulse (Isp)
        ispTokens = regexp(pageText, 'Isp, M/SEC\s+([0-9\.\s-]+)', 'tokens');
        if isempty(ispTokens); continue; end
        page_Isps = str2num(ispTokens{1}{1}); %#ok<ST2NM>
        
        % Ensure data vector shapes line up perfectly for this page
        validCols = min([numCols, length(page_Gammas), length(page_Cstars), length(page_Ivacs), length(page_Isps)]);
        
        % Append into a flat structured list
        for c = 1:validCols
            raw_OF(end+1)     = page_OF;         %#ok<AGROW>
            raw_P(end+1)      = page_Pressures(c);%#ok<AGROW>
            raw_Gamma(end+1)  = page_Gammas(c);  %#ok<AGROW>
            raw_Cstar(end+1)  = page_Cstars(c);  %#ok<AGROW>
            raw_Ivac(end+1)   = page_Ivacs(c);   %#ok<AGROW>
            raw_IspOpt(end+1) = page_Isps(c);    %#ok<AGROW>
        end
    end
    
    if isempty(raw_OF)
        error('Data extraction failed. Verify that your file matches standard NASA CEA printouts.');
    end
    
    % Extract clean, sorted independent axis coordinates (unique values only)
    LUT_Breakpoints_OF       = unique(raw_OF);
    LUT_Breakpoints_P_bar    = unique(raw_P);
    LUT_Breakpoints_P_Pa     = LUT_Breakpoints_P_bar * 1e5; % For direct Simscape scaling
    
    % Grid dimensions
    nOF = length(LUT_Breakpoints_OF);
    nP  = length(LUT_Breakpoints_P_bar);
    
    % Initialize 2D matrix sheets for the lookup fields
    LUT_Matrix_Cstar_mps = zeros(nOF, nP);
    LUT_Matrix_Gamma     = zeros(nOF, nP);
    LUT_Matrix_Ivac_mps  = zeros(nOF, nP);
    LUT_Matrix_Isp_mps   = zeros(nOF, nP);
    
    % Map the flat raw arrays into the formal 2D Grid structure
    for i = 1:length(raw_OF)
        of_idx = find(LUT_Breakpoints_OF == raw_OF(i), 1);
        p_idx  = find(LUT_Breakpoints_P_bar == raw_P(i), 1);
        
        LUT_Matrix_Cstar_mps(of_idx, p_idx) = raw_Cstar(i);
        LUT_Matrix_Gamma(of_idx, p_idx)     = raw_Gamma(i);
        LUT_Matrix_Ivac_mps(of_idx, p_idx)  = raw_Ivac(i);
        LUT_Matrix_Isp_mps(of_idx, p_idx)   = raw_IspOpt(i);
    end
    
    % Save all structures directly to a .mat file workspace
    save(matFile, ...
         'LUT_Breakpoints_OF', 'LUT_Breakpoints_P_bar', 'LUT_Breakpoints_P_Pa', ...
         'LUT_Matrix_Cstar_mps', 'LUT_Matrix_Gamma', 'LUT_Matrix_Ivac_mps', 'LUT_Matrix_Isp_mps');
     
    fprintf('\n========================================================\n');
    fprintf('SUCCESS: CEA data processed and compiled cleanly!\n');
    fprintf('File saved as: %s\n', matFile);
    fprintf('Grid compiled: [%d O/F points] x [%d Pressure points]\n', nOF, nP);
    fprintf('========================================================\n');
end