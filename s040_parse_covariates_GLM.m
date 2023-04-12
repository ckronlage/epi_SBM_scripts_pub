function [covariates] = s040_parse_covariates_GLM ()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

raw_covariates_filename='0covariates_raw.csv';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning('off','MATLAB:table:ModifiedAndSavedVarnames');

covariates_raw = readtable(raw_covariates_filename,...
      'fileType','delimitedtext',...
      'Delimiter','comma',...
      'ReadRowNames',true,...
      'ReadVariableNames',true,...
      'VariableNamesLine',1,...
      'VariableNamingRule','modify');

covariates = containers.Map('KeyType','char','ValueType','any');
  
for suffix = listofsuffixes    
    for subject = listofsubjects
        % disp([subject{1} suffix{1}])

        fid = fopen([subject{1} suffix{1} '/stats/aseg.stats']);
        line = fgetl(fid);
        while ischar(line)
            if strfind(line,'EstimatedTotalIntraCranialVol')
                eTIV = regexp(line,'\d+\.\d*','match');
                eTIV = str2double(eTIV{1});
                break;
            end
            line = fgetl(fid);
        end
        fclose(fid);

        covariates([ subject{1} suffix{1} ]) = [covariates_raw{subject{1},:} eTIV];
        
    end % subjects loop
end % listofsuffixes

end
