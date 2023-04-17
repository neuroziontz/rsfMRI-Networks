basedir='/home/jagust/ziontzja/rsfmri_networks/ADNI_sample/';
%basedir='/Users/jacob/NeuroCluster/jagust/ziontzja/rsfmri_networks/ADNI_sample/';
addpath(genpath([basedir,filesep,'code']));

%% Define initial batch inputs
disp('Locating processed structural and functional MNI space scans');
NSUBJECTS=349;
cwd=[basedir,filesep,'data',filesep,'ADNI'];
cd(cwd);
FUNCTIONAL_FILES=cellstr(conn_dir('4D_s4wcrADNI*.nii'));
STRUCTURAL_FILES=cellstr(conn_dir('mwADNI_*_rnu.nii'));
nsessions=1;
FUNCTIONAL_FILES=reshape(FUNCTIONAL_FILES, [NSUBJECTS, nsessions]);
STRUCTURAL_FILES={STRUCTURAL_FILES{1:NSUBJECTS}};
TR=0.607;

disp([num2str(size(FUNCTIONAL_FILES,1)),' subjects']);
disp([num2str(size(FUNCTIONAL_FILES,2)),' sessions']);

%% Prepare batch structure
clear batch;
batch.filename=[basedir,filesep,'CONN',filesep,'batch_ADNIrsfMRI_N349_MNI.mat'];

%% Parallel options
batch.parallel.N=8; % run 8 parallel jobs locally

%% Setup & Preprocessing
batch.Setup.isnew=1;
batch.Setup.nsubjects=NSUBJECTS;
batch.Setup.nsessions=nsessions;
batch.Setup.RT=TR;
batch.Setup.functionals=repmat({{}}, [NSUBJECTS,1]);
for nsub=1:NSUBJECTS
    for nses=1:nsessions
        batch.Setup.functionals{nsub}{nses}{1}=FUNCTIONAL_FILES{nsub,nses};
    end
end
batch.Setup.structurals=STRUCTURAL_FILES;
nconditions=nsessions;
batch.Setup.conditions.names={'rest'};
for ncond=1
    for nsub=1:NSUBJECTS
        for nses=1:nsessions
            batch.Setup.conditions.onsets{ncond}{nsub}{nses}=0;
            batch.Setup.conditions.durations{ncond}{nsub}{nses}=inf;
        end
    end
end

% Load ROIs
disp('Locating GM, WM, and CSF segmentation files');
GM_FILES=cellstr(conn_dir('mwc1ADNI_*_rnu.nii'));
GM_FILES={GM_FILES{1:NSUBJECTS}};
WM_FILES=cellstr(conn_dir('mwc2ADNI_*_rnu.nii'));
WM_FILES={WM_FILES{1:NSUBJECTS}};
CSF_FILES=cellstr(conn_dir('mwc3ADNI_*_rnu.nii'));
CSF_FILES={CSF_FILES{1:NSUBJECTS}};

batch.Setup.rois.names={'Grey Matter','White Matter','CSF','BN_atlas'};
batch.Setup.rois.files{1}=GM_FILES;
batch.Setup.rois.files{2}=WM_FILES;
batch.Setup.rois.files{3}=CSF_FILES;
batch.Setup.rois.files{4}=[basedir,'CONN',filesep,'MNI_ROIs',filesep,'rBNA_MPM_thr25_1.25mm.nii'];
batch.Setup.rois.multiplelabels = 1;

% Setup options
batch.Setup.analyses = [1,2]; % ROI-to-ROI and seed-to-voxel analyses
batch.Setup.voxelmask = 2; % Implicit mask (subject-specific)
batch.Setup.voxelresolution = 3; % Analysis space same as functionals
batch.Setup.analysisunits = 1; % Percent signal change units

batch.Setup.done=1;
batch.Setup.overwrite=0; % Don't overwrite existing setup

% Load covariates
disp('Locating rp motion and art outliers files');
rp_FILES=cellstr(conn_dir('rp_4D_crADNI*.txt'));
rp_FILES={rp_FILES{1:NSUBJECTS}};
art_FILES=cellstr(conn_dir('art_regression_outliers_4D*.mat'));
art_FILES={art_FILES{1:NSUBJECTS}};

batch.Setup.l1covariates.names={'motion','scrubbing'};
batch.Setup.l1covariates.files{1}=rp_FILES;
batch.Setup.l1covariates.files{2}=art_FILES;

%% Denoising
batch.Denoising.filter=[0.008, 0.1];
batch.Denoising.done=1;
batch.Denoising.overwrite=0; %Don't overwrite existing denoising

%% First level analysis
batch.Analysis.done=1;
batch.Analysis.overwrite='Yes';

%% Run batch
disp('All files located and batch prepared, running CONN analysis...')
conn_batch(batch);

