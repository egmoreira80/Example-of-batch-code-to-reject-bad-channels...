%% Example of batch code to reject bad channels...
% 
% author: Eduardo Gonzalez-Moreira
% date: Oct-2020

%%
clear all;
clc;
close all;

%% Step 1: Select eeg data format.
typerawdata = 'set'
rawDataFiles = dir(['*.',typerawdata]);
subjID = 1
loadName = rawDataFiles(subjID).name;
dataName = loadName(1:end-4);
verbosity = 1;

%% Step2: Import data.
switch typerawdata
    case 'set'
        EEG = pop_loadset(loadName);
    case 'mat'
        load(loadName);
    case 'dat'
        EEG = pop_loadBCI2000(loadName);
    case 'PLG'
        EEG = pop_load_plg([rawDataFiles.folder,'\',loadName]);
end
EEG.setname = dataName;

%% Step 3: Visualization.
if verbosity
    eegplot(EEG.data)
end

%% Step 4: Downsample the data.
if EEG.srate > 300
    EEG = pop_resample(EEG, 200);
end

%% Step 5: Filtering the data at 0Hz and 45 Hz.
EEG = pop_eegfiltnew(EEG, 'locutoff', 0, 'hicutoff',45, 'filtorder', 3300);

%% Step 6: Import channel info.
EEG = pop_chanedit(EEG, 'lookup','C:\QUERETARO\TOOLS\eeglab2020_0\plugins\dipfit\standard_BEM\elec\standard_1005.elc','eval','chans = pop_chancenter( chans, [],[]);');
if verbosity
    figure;
    [spectra,freqs] = spectopo(EEG.data,0,EEG.srate,'limits',[0 30 NaN NaN -10 10],'chanlocs',EEG.chanlocs,'chaninfo',EEG.chaninfo,'freq',[1 6 10 18]);
end

%% Step 7: Apply clean_rawdata() to reject bad channels and correct continuous data using Artifact Subspace Reconstruction (ASR).
EEG_cleaned = clean_artifacts(EEG);
if verbosity
    vis_artifacts(EEG_cleaned,EEG);
end

%% Step 8: Interpolate all the removed channels.
EEG_interp = pop_interp(EEG_cleaned, EEG.chanlocs, 'spherical');
if verbosity
    eegplot(EEG_interp.data)
    figure;
    [spectra,freqs] = spectopo(EEG_interp.data,0,EEG_interp.srate,'limits',[0 30 NaN NaN -10 10],'chanlocs',EEG_interp.chanlocs,'chaninfo',EEG_interp.chaninfo,'freq',[1 6 10 18]);
end
EEG = EEG_interp;

%% Step 9: Saving cleaned EEG
save([rawDataFiles(subjID).folder,'\',dataName,'_cleaned.mat'],'EEG');
