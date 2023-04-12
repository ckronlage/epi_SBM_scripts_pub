function s041_run_GLM(suffix,subject)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load and set variables
addpath('/home/ckronlage/epi/epi_SBM_scripts');
s019_set_variables;

% check arguments
if ~any(matches(listofsuffixes,suffix)) || ~any(matches(listofsubjects,subject))
    error("wrong arguments")
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% GLM - linear regression is performed using freesurfer mri_glmfit because
% it runs much faster than matlab-routines (such as fitlm)

covariates = s040_parse_covariates_GLM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%loop over all measures selectedx for GLM and both hemis

for measure = listofmeasures_GLM

    for hemi = hemis

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % concatenate surface measures and construct GLM design matrix

        cmd = 'mri_concat ';
        X = [];

        for comparedsubject = listofsubjects

            % include controls and the one patient in question
            if comparedsubject{1}(1) == 'C' || strcmp(comparedsubject,subject)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % add compared subject to data concatenation cmd
                cmd = strcat(cmd," --i ",comparedsubject,suffix,"/0surf_features/",...
                    hemi,".",measure,".fsaverage_sym.mgh");

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % construct GLM design matrix for one vs. all others comparison
                % (leave one out in case of controls)
                if strcmp(comparedsubject,subject)
                   subj_vars = [0 1];
                else
                   subj_vars = [1 0];
                end

                subj_covars = covariates(strcat(comparedsubject{1},suffix));

                subj_vars = [subj_vars subj_covars];
                X = vertcat(X,subj_vars);

            end

        end % loop over comparedsubject

        % normalize eTIV column (causes problems with mri_glmfit otherwise)
        X(:,6) = normalize(X(:,6));
        
        % remove eTIV as covariate for everything but
        % nthickness, area and volume
        if isempty(strfind(measure{1},"nthickness")) && ...
           isempty(strfind(measure{1},"area")) && ...
           isempty(strfind(measure{1},"volume"))
            X = X(:,1:end-1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % set an create glmdir
        glmdir = strcat(subject,suffix,"/0GLM");
        status = system(strcat("mkdir -p ",glmdir));
        
        % for running on the grid, use local tmpdir (significantly speeds
        % things up)
        if isempty(getenv('TMPDIR'))
            tmpdir = glmdir;
        else
            tmpdir = tempname(getenv('TMPDIR'));
            status = system(strcat("mkdir -p ",tmpdir));
        end
        
        
        % run concatenation
        Yfile = strcat(tmpdir,"/",...
            hemi,".",measure,".fsaverage_sym.mgh");
        cmd = strcat(cmd," --o ",Yfile);
        status = system(cmd);

        % save design matrix
        Xfile = strcat(tmpdir,"/",...
            hemi,".",measure,".fsaverage_sym.X.mat");
        save(Xfile,'X','-v4'); 

        % save contrast
        contrast = "-1 1";
        for i=3:size(X,2) % match number of nuisance covariates 
            contrast = strcat(contrast," 0");
        end

        Cfile = strcat(tmpdir,"/",...
            "groupdiff.mtx");
        fid = fopen(Cfile,'wt');
        fprintf(fid, contrast);
        fclose(fid);

        % fit GLM
        cmd = strcat("mri_glmfit --y ",Yfile," --X ",Xfile,...
            " --C ",Cfile," --surf fsaverage_sym lh --cortex ",...
            "--glmdir ",strcat(glmdir,"/",...
            hemi,".",measure,".fsaverage_sym_glmdir"));
        status = system(cmd);

        % cleanup
        cmd = strcat("rm ",Yfile," ",Xfile," ",Cfile);
        status = system(cmd);

    end
end
