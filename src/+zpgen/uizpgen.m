% UI for creating ZPGen scripts locally.  Launch using launch_ZPGEN.m
% script.  Converted to MPM package on 04/14/2019 and it now includes ZPGen
% C++ script as a dependency.  ZPGen requires a working ZPGenPlus
% executable which can be built using the "make" command for unix machines
% running gcc C++ compiler.  This file may need to be modified to
% accommodate different setups
%
% Changelog:
%
% 2.11.0: Adding ability to compress files, logs all zps locally, removes
% intermediate files
%
% 2.10.2: Resolving interaction between randomized and multifield
%
% 2.10.1: Adding ability to change WRV block unit size
%
% 2.10.0: Adding infinite conjugate, 4xNA and D (zone plate diameter)
%
% 2.9.2: Adding dr and photon energy
%
% 2.9.1: Fixing bug with aperture boundaries 
%
% 2.9.0: Refactoring pupil coordinate computation and allowing for filled
% obscurations
%
% 2.8.2: Adding spiral phase option
%
% 2.8.1: Turning on ZPC phase and adding options for horizontal and
% vertical strip zone plates
%
% 2.8.0: adding block partitioning for NWA files
%
% 2.7: getting on to current MIC framework
%
% 2.6: Added NWA pixel size
%
% 2.5: implemented CSV logging
%
% 2.4: added NWA support and support for centering of off-axis zone plates.
% Also added support for central obscurations for anamorphic zone plates
% and a new custom square aperture as per Ken's request.
% 
%
%

classdef uizpgen < mic.Base

    
    properties (Constant)
        cBuildName = 'ZPGen v2.11.0';
        
        dWidth  = 1200;
        dHeight =  900;
        hc      = 1240.71
        ceHeaders = {'File name', 'Build version', 'Zone tolerance', 'lambda (nm)', 'P (um)', 'Q (um)', 'Obscuration sigma', 'NA', 'Zernikes', ...
                'Custom mask index', 'ZP tilt (deg)', 'Azimuthal (deg)', 'CRA (deg)', 'Anamorphic fac', ...
                'ZPC phase (deg)', 'ZPC apodization', 'Ap function', 'ZPC inner rad', 'ZPC outer rad', 'Zone bias (nm)', ...
                'File format', 'Tone reversal', 'Buttressing', 'Buttress width', 'Buttress period', 'Off-axis centering', ...
                'WRV blocksize', 'Multiple patterning N', 'Multiple patterning i', 'Layer number', 'WRV Block unit/NWA px size', 'Exec string'};
            
        ceCustomMaskOptions = { 'None', ...
                                'Intel MET AIS Tripole', ...
                                'TDS Config ZP2', ...
                                'TDS Config ZP3', ...
                                'TDS Config ZP4', ...
                                '5-Square', ...
                                '5-Square 45', ...
                                'Flip align', ... 
                                'Octopole', ...
                                'Concentric rings', ...
                                'Octal Rays', ...
                                'Square', ...
                                'Horizontal Strip', ...
                                'Vertical Strip', ...
                                'Spiral phase', ...
                                'Black ring 0.95', ...
                                'Obscuration Only'};
    end
    
    properties
        
        % Graphical elements
        hFigure     % Main figure (not overwritable)
        
        bIgnoreFileFormatOnLoad = false
        
        uiZPPropagator
        
        cDirThis
        
        uieZoneTol
        uieLambda
        uieP
        uieQ
        uieObscurationSigma
        uieNA
        uie4xNA
        uitD
        uitDLabel
        uitTrueDr
        uitTrueDrLabel
        uieEp
        uieDr
        uieZernikes
        uieAlpha
        uieZPTilt
        uieCraAz
        uieCraAngle
        uieZPPhase
        uieApodMag
        uipApodFn
        uieZPCR1
        uieZPCR2
        uieZoneBias
        uipFileOutput
        uicbReverseTone
        uipButtressIdx
        uieButtressW
        uieButtressT
        uieDoseBiasScaling
        uieBlockSize
        uieNumBlocks
        uieMultiplePatN
        uieMultiplePatIdx
        uieLayerNumber
        uicbCurl
        uipCustomMask
        uipNWAPxSize
        
        uieWRVBlockUnit
        
        uieAnamorphicFac
        uicbCenterOffaxisZP
        
        uieExecStr
        uicbComputeExternally
        uicbCompressFiles
        
        
        uibOpenInFinder
        
        uicbRandomizeWRVZones
        uicbInfiniteConjugate

        uibStageAndGenerate
        uibGenerate
        uibStageZP
        uibSave
        uibLoad
        uieZPName
        
        cExecStr = []
        cLogStr = ''
        arch = computer('arch')
        
        cZPGenDir = fullfile(fileparts(mfilename('fullpath')), '..');
        cOutputFileDir = '';
        
        bPreserveUncompressedFiles = false
    end
    
    properties (SetAccess = private)
        
    end
    
    methods
        function this = uizpgen(varargin)
            
            for k = 1:2:length(varargin)
                prop = varargin{k};
                value = varargin{k+1};
                if isprop(this,prop)
                    this.(prop) = value;
                end
                
            end
            this.init()
        end
        
        function init(this)
            [this.cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));
           
            this.uiZPPropagator         = GDS.ui.GDS_Propagation;

            this.uieZoneTol             = mic.ui.common.Edit('cLabel', 'Zone Tol', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieLambda              = mic.ui.common.Edit('cLabel', 'Lambda (nm)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            
            this.uieP                   = mic.ui.common.Edit('cLabel', 'p (um)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieQ                   = mic.ui.common.Edit('cLabel', 'q (um)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uicbInfiniteConjugate  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Infinite conjugate', 'fhDirectCallback', @this.cb);

            this.uieObscurationSigma    = mic.ui.common.Edit('cLabel', 'Obscuration Sigma', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieNA                  = mic.ui.common.Edit('cLabel', 'NA', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uie4xNA                = mic.ui.common.Edit('cLabel', '4xNA', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uitDLabel              = mic.ui.common.Text('cType', 'd', 'cVal', 'D (um)');
            this.uitD                   = mic.ui.common.Text( 'cVal', '100', 'dFontSize', 14, 'cFontWeight', 'bold');
            this.uitTrueDrLabel         = mic.ui.common.Text('cType', 'd', 'cVal', 'True dr (nm)');
            this.uitTrueDr              = mic.ui.common.Text( 'cVal', '100', 'dFontSize', 14, 'cFontWeight', 'bold');

            
            this.uieEp                  = mic.ui.common.Edit('cLabel', 'Pht Energy (eV)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieDr                  = mic.ui.common.Edit('cLabel', 'dr (nm, On-Ax)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);

            
            this.uieAnamorphicFac       = mic.ui.common.Edit('cLabel', 'Anamorphic factor', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZernikes            = mic.ui.common.Edit('cLabel', 'Zernike string', 'cType', 'c', 'fhDirectCallback', @this.cb);
            this.uieAlpha               = mic.ui.common.Edit('cLabel', 'Alpha', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZPTilt              = mic.ui.common.Edit('cLabel', 'Tilt (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uieCraAz               = mic.ui.common.Edit('cLabel', 'CRA Az (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieCraAngle            = mic.ui.common.Edit('cLabel', 'CRA (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZPPhase             = mic.ui.common.Edit('cLabel', 'ZPC Ph. (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieApodMag             = mic.ui.common.Edit('cLabel', 'Apodization Mag', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uipApodFn              = mic.ui.common.Popup('cLabel', 'Apodization fn', 'ceOptions', {'None', 'Hamming', 'Gaussian'}, ...
                                                                'fhDirectCallback', @this.cb);
            
            this.uieZPCR1               = mic.ui.common.Edit('cLabel', 'ZPC R1 (sigma)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZPCR2               = mic.ui.common.Edit('cLabel', 'ZPC R2 (sigma)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZoneBias            = mic.ui.common.Edit('cLabel', 'Zone Bias (nm)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uipNWAPxSize           = mic.ui.common.Popup('cLabel', 'NWA px size', 'ceOptions', {'N/A', '1.75 nm', '2 nm', '2.5 nm', '4 nm', '5 nm', '6 nm', '7 nm', '8 nm'}, ...
                                                                'fhDirectCallback', @this.cb);
                                                            
            this.uipFileOutput          = mic.ui.common.Popup('cLabel', 'Output file type', 'ceOptions', {'NWA (ARC)', 'GDS', 'GDS + txt', 'WRV'}, ...
                                                                'fhDirectCallback', @this.cb);
                                                                                 
                                                            
            this.uipCustomMask          = mic.ui.common.Popup('cLabel', 'Custom mask', 'ceOptions',this.ceCustomMaskOptions, ...
                                                                'fhDirectCallback', @this.cb);
                                                            
                                                        
            this.uicbReverseTone        = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Reverse Tone', 'fhDirectCallback', @this.cb);
            
            this.uipButtressIdx         = mic.ui.common.Popup('cLabel', 'Buttressing', 'ceOptions', {'None', 'Gapped zones (PT)', 'Zones + gaps (NT)'}, ...
                                                                'fhDirectCallback', @this.cb);
                                                            
            
            this.uieButtressW           = mic.ui.common.Edit('cLabel', 'Buttress width param', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieButtressT           = mic.ui.common.Edit('cLabel', 'Buttress period param', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uieDoseBiasScaling     = mic.ui.common.Edit('cLabel', 'Dose Bias Scaling', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieBlockSize           = mic.ui.common.Edit('cLabel', 'WRV Block N px', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieNumBlocks           = mic.ui.common.Edit('cLabel', 'Block N^2 (odd sq.)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uieWRVBlockUnit        = mic.ui.common.Edit('cLabel', 'Block unit (pm))', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            
            this.uieMultiplePatN        = mic.ui.common.Edit('cLabel', 'Multiple Patterning N', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieMultiplePatIdx      = mic.ui.common.Edit('cLabel', 'Multiple Patterning idx', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieLayerNumber         = mic.ui.common.Edit('cLabel', 'GDS layer', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uicbCurl               = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Curl progress', 'fhDirectCallback', @this.cb);
            
            this.uicbComputeExternally  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Compute Externally', 'fhDirectCallback', @this.cb);
            this.uicbCompressFiles  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Compress ZP with Log', 'fhDirectCallback', @this.cb);

            
            this.uicbRandomizeWRVZones  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Randomize WRV Zones', 'fhDirectCallback', @this.cb);
            
            
            this.uicbCenterOffaxisZP    = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Center Off-axis ZP', 'fhDirectCallback', @this.cb);
            
            
            this.uibStageAndGenerate    = mic.ui.common.Button('cText', 'Stage and Generate', 'fhDirectCallback', @this.cb);
            
            this.uibStageZP             = mic.ui.common.Button('cText', 'Stage ZP', 'fhDirectCallback', @this.cb);
            this.uibGenerate            = mic.ui.common.Button('cText', 'Generate', 'fhDirectCallback', @this.cb);
            this.uibSave                = mic.ui.common.Button('cText', 'Save ZP', 'fhDirectCallback', @this.cb);
            this.uibLoad                = mic.ui.common.Button('cText', 'Load ZP', 'fhDirectCallback', @this.cb);
            this.uibOpenInFinder        = mic.ui.common.Button('cText', 'Open Folder', 'fhDirectCallback', @this.cb);
            
            this.uieZPName              = mic.ui.common.Edit('cLabel', 'ZP Name', 'cType',  'c', 'fhDirectCallback', @this.cb);
            
            this.uieExecStr             = mic.ui.common.Edit('cLabel', 'Exec string', 'cType', 'c', 'fhDirectCallback', @this.cb);
            
            this.uipFileOutput.setSelectedIndex(uint8(2));
            this.uipCustomMask.setSelectedIndex(uint8(1));
            this.uieZPName.set('Untitled');
            
            this.uieZoneTol.set(0.01);
            this.uieAnamorphicFac.set(1);

            this.uieLambda.set(13.5);
            this.uieNA.set(0.08);
            this.cb(this.uieNA);

            this.uieEp.set(this.hc/13.5);
            this.uieP.set(500);
            this.uieQ.set(1e10);
            
            this.uieZernikes.set('[]');
            this.uieObscurationSigma.set(0);
            
            this.uieAlpha.set(0);
            this.uieZPTilt.set(0);
            this.uieCraAz.set(0);
            this.uieCraAngle.set(0);
            this.uieZPPhase.set(0);
            this.uieApodMag.set(1);
            this.uipApodFn.setSelectedIndex(uint8(1));
            this.uieZPCR1.set(0);
            this.uieZPCR2.set(0);
            this.uieZoneBias.set(10);
            this.uieWRVBlockUnit.set(500);
            
            
            this.uipButtressIdx.setSelectedIndex(uint8(1));
            this.uipNWAPxSize.setSelectedIndex(uint8(1));
            
            this.uieButtressW.set(0.6);
            this.uieButtressT.set(6);
            this.uieDoseBiasScaling.set(1);
            this.uieBlockSize.set(8e5);
            this.uieNumBlocks.set(1);
            this.uieMultiplePatN.set(1);
            this.uieMultiplePatIdx.set(1);
            this.uieLayerNumber.set(1);
                
            this.uicbCenterOffaxisZP.set(true);
            this.uicbInfiniteConjugate.set(false);
            
            
        end
        
        function setVals(this, varargin)
            for k = 1:2:length(varargin)
                switch varargin{k}
                    case 'NA'
                        this.uieNA.set(varargin{k+1});
                    case 'lambda'
                        this.uieLambda.set(varargin{k+1});
                    case 'P'
                        this.uieP.set(varargin{k+1});
                    case 'Q'
                        this.uieQ.set(varargin{k+1});
                    case 'dr'
                        this.uieDr.set(varargin{k+1});
                    case 'Ep'
                        this.uieEp.set(varargin{k+1});
                    case 'CRA'
                        this.uieCraAngle.set(varargin{k+1});
                    case 'zernikes'
                        this.uieZernikes.set(varargin{k+1});
                    case 'customMask'
                        this.uipCustomMask.setSelectedIndex(uint8(varargin{k+1}))
                    case 'CRAAz'
                        this.uieCraAz.set(varargin{k+1});
                    case 'zoneBias'
                        this.uieZoneBias.set(varargin{k+1});
                    case 'obscuration'
                        this.uieObscurationSigma.set(varargin{k+1});
                    case 'zpcR1'
                        this.uieZPCR1.set(varargin{k+1});
                    case 'zpcR2'
                        this.uieZPCR2.set(varargin{k+1});
                    case 'zpcPhase'
                        this.uieZPPhase.set(varargin{k+1});
                    case 'name'
                        this.uieZPName.set(varargin{k+1});
                    case 'zTol'
                        this.uieZoneTol.set(varargin{k+1});
                    case 'anamorphicFac'
                        this.uieAnamorphicFac.set(varargin{k+1});
                    case 'paramW'
                        this.uieButtressW.set(varargin{k+1});
                    case 'outputIdx'
                        this.uipFileOutput.setSelectedIndex(uint8(varargin{k+1}))
                    case 'centerZP'
                        this.uicbCenterOffaxisZP.set(varargin{k+1});
                    case 'randomizeZones'
                        this.uicbRandomizeWRVZones.set(varargin{k+1});
                    case 'buttressing'
                        this.uipButtressIdx.setSelectedIndex(uint8(varargin{k+1}))
                    case 'reverseTone'
                        this.uicbReverseTone.set(varargin{k+1})
                    case 'blockUnit'
                        this.uieWRVBlockUnit.set(varargin{k+1})
                    case 'compress'
                        this.uicbCompressFiles.set(varargin{k+1});
                end
            end
                
        end
        
        function D = getD(this)
            cra = this.uieCraAngle.get();
            p = this.uieP.get();
            q = this.uieQ.get();
            
            pqmin = min(p,q);
            na = this.uieNA.get();
            naL = sind(cra) - na;
            naH = sind(cra) + na;
            
            D = pqmin*(tan(asin(naH)) - tan(asin(naL)));

        end
        
        function dr = getTrueDr(this)
            cra = this.uieCraAngle.get();
            na = this.uieNA.get();
            naP = sind(cra) + na;
            dr = this.uieLambda.get()/naP/2;
            
        end
     
        function cb(this, src, dat)
            switch src
                case this.uibGenerate
                    this.generate();
                    
                case this.uieCraAngle
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    this.uitTrueDr.set(sprintf('%0.3f', this.getTrueDr()));
                case this.uieP
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                case this.uieQ
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                case this.uieNA
                    this.uie4xNA.setWithoutNotify(this.uieNA.get()*4)
                    setVal = this.uieLambda.get()/this.uieNA.get()/2;
                    this.uieDr.setWithoutNotify(setVal)
                    
                    
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    this.uitTrueDr.set(sprintf('%0.3f', this.getTrueDr()));
                case this.uie4xNA
                    this.uieNA.setWithoutNotify(this.uie4xNA.get()/4)
                    setVal = this.uieLambda.get()/this.uieNA.get()/2;
                    this.uieDr.setWithoutNotify(setVal)
                    
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                case this.uieDr
                    setVal = this.uieLambda.get()/this.uieDr.get()/2;
                    this.uieNA.setWithoutNotify(setVal)
                    this.uie4xNA.setWithoutNotify(setVal * 4)
                    
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                case this.uicbInfiniteConjugate
                    
                    if (this.uicbInfiniteConjugate.get())
                        this.uieQ.setWithoutNotify(1e15);   
                    end
                    
                case this.uieEp
                    setVal = this.hc/this.uieEp.get();
                    
                    this.uieLambda.setWithoutNotify(setVal)
                    
                    % Call NA callback to reset Dr
                    this.cb(this.uieNA);
                case this.uieLambda
                    setVal = this.hc/this.uieLambda.get();
                    this.uieEp.setWithoutNotify(setVal)
                    
                    this.uitTrueDr.set(sprintf('%0.3f', this.getTrueDr()));
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    
                    this.cb(this.uieNA);
                case this.uibLoad
                    this.load();
                    this.stageZP();
                case this.uibSave
                    this.save();
                case this.uibStageZP
                    this.stageZP();
                case this.uibStageAndGenerate
                    this.stageAndGenerate();
                
                case this.uibOpenInFinder
                    if strcmp(this.arch, 'win64')
                        system(sprintf('explorer %s', fullfile(this.cOutputFileDir)));
                    else
                        system(sprintf('open %s', fullfile(this.cOutputFileDir)));

                    end
                case this.uipFileOutput 
                    if this.uipFileOutput.getSelectedIndex() == uint8(1)
                        this.uipNWAPxSize.setSelectedIndex(uint8(5));
                    else
                        this.uipNWAPxSize.setSelectedIndex(uint8(1));
                    end
                case this.uipNWAPxSize 
                    if this.uipFileOutput.getSelectedIndex() == uint8(1) && this.uipNWAPxSize.getSelectedIndex() == uint8(1)
                        this.uipNWAPxSize.setSelectedIndex(uint8(5));
                    end
                case this.uieNumBlocks
                    dVal = this.uieNumBlocks.get();
                    if round(sqrt(dVal))^2 ~= dVal || mod(sqrt(dVal), 2) ~= 1
                        dVal = round(  ((sqrt(this.uieNumBlocks.get()) + 1)/2  ))*2 - 1;
                        this.uieNumBlocks.set(dVal^2);
                    end
                    if dVal > 1
                       % set blocksize to 800k
                       this.uieBlockSize.set(800000);
                    end
                    
            
            end
        end
        
        function zpFilePath = stageAndGenerate(this)
            this.stageZP();
            drawnow;
            zpFilePath = this.generate();
        end
        
        function build(this)
            
            % build the main window
            if nargin<=1
                this.hFigure = figure(...
                    'name', this.cBuildName,...
                    'Units', 'pixels',...
                    'Position', [100 100 this.dWidth this.dHeight],...
                    'handlevisibility','off',... %out of reach gcf
                    'numberTitle','off',...
                    'Toolbar','none',...
                    'Menubar','none');
                
            end
            
            dCol1 = 30;
            dCol2 = 130;
            dCol3 = 230;
            dCol4 = 330;
            dCol5 = 430;
            
            dYWid = 45;
            
            % build ZPpropagator:
%             this.uiZPPropagator.build(this.hFigure, 500, 20);
            
                        
            this.uieZPName.build(this.hFigure, dCol1, dYWid, 200, 30);
            this.uibSave.build(this.hFigure, dCol3 + 20, dYWid + 10, 75, 40);
            this.uibLoad.build(this.hFigure, dCol4 + 20, dYWid + 10, 75, 40);
            this.uibStageAndGenerate.build(this.hFigure, dCol5 + 20, dYWid + 10 , 100, 40);
            this.uibOpenInFinder.build(this.hFigure, dCol5 + 20, dYWid*2 + 10, 100, 40);

            this.uipFileOutput.build(this.hFigure, dCol1, 2*dYWid, 200, 30);
            this.uicbCompressFiles.build(this.hFigure, dCol3 + 20, 2*dYWid + 10, 180, 30);
            this.uicbComputeExternally.build(this.hFigure, dCol3 + 20, 2*dYWid + 33, 180, 30);
            
            this.uieZoneTol.build(this.hFigure, dCol1, 3*dYWid, 75, 30);
            this.uieZoneBias.build(this.hFigure, dCol2, 3*dYWid, 75, 30);

            this.uieLambda.build(this.hFigure, dCol1, 4*dYWid, 75, 30);
            this.uieEp.build(this.hFigure, dCol2, 4*dYWid, 75, 30);
            
            this.uieNA.build(this.hFigure, dCol1, 5*dYWid, 75, 30);
            this.uie4xNA.build(this.hFigure, dCol2, 5*dYWid, 75, 30);

            this.uieDr.build(this.hFigure, dCol3, 5*dYWid, 75, 30);
            
            this.uitDLabel.build(this.hFigure, dCol5, 5*dYWid, 75, 30);
            this.uitD.build(this.hFigure, dCol5, 5*dYWid + 20, 75, 30);
            
            this.uitTrueDrLabel.build(this.hFigure, dCol4, 5*dYWid, 75, 30);
            this.uitTrueDr.build(this.hFigure, dCol4, 5*dYWid + 20, 75, 30);

            this.uieP.build(this.hFigure, dCol1, 6*dYWid, 75, 30);
            this.uieQ.build(this.hFigure, dCol2, 6*dYWid, 75, 30);
            this.uicbInfiniteConjugate.build(this.hFigure, dCol3, 6*dYWid + 10, 120, 30);
            
            this.uieCraAngle.build(this.hFigure, dCol1, 7*dYWid, 75, 30);
            this.uieCraAz.build(this.hFigure, dCol2, 7*dYWid, 75, 30);
            this.uieZPTilt.build(this.hFigure, dCol3, 7*dYWid, 75, 30);
            
            
            this.uipButtressIdx.build(this.hFigure, dCol1, 9*dYWid, 150, 30);
            this.uieButtressW.build(this.hFigure, dCol3, 9*dYWid, 75, 30);
            this.uieButtressT.build(this.hFigure, dCol4, 9*dYWid, 75, 30);
            this.uicbReverseTone.build(this.hFigure, dCol1, 10*dYWid + 10, 120, 30);
            
            
            this.uieZernikes.build(this.hFigure, dCol1, 11*dYWid, 300, 30);

            this.uipCustomMask.build(this.hFigure, dCol1, 12*dYWid, 250, 30);
                        
            this.uieObscurationSigma.build(this.hFigure, dCol1, 13*dYWid, 75, 30);
            this.uieZPCR1.build(this.hFigure, dCol2, 14*dYWid, 75, 30);
            this.uieZPCR2.build(this.hFigure, dCol3, 14*dYWid, 75, 30);
            this.uieZPPhase.build(this.hFigure, dCol4, 14*dYWid, 75, 30);
            this.uieAnamorphicFac.build(this.hFigure, dCol2, 13*dYWid, 90, 30);
            
%             this.uieApodMag.build(this.hFigure, dCol1, 14*dYWid, 75, 30);
%             
%             this.uipApodFn.build(this.hFigure, dCol2, 14*dYWid, 150, 30);

            
%             this.uieDoseBiasScaling.build(this.hFigure, dCol1, 15*dYWid, 75, 30);
%             this.uieMultiplePatN.build(this.hFigure, dCol2, 15*dYWid, 75, 30);
%             this.uieMultiplePatIdx.build(this.hFigure, dCol3, 15*dYWid, 75, 30);
            this.uieBlockSize.build(this.hFigure, dCol1, 15*dYWid, 80, 30);
            this.uieNumBlocks.build(this.hFigure, dCol2, 15*dYWid, 120, 30);
            this.uieWRVBlockUnit.build(this.hFigure, dCol4, 15*dYWid, 80, 30);
            this.uicbRandomizeWRVZones.build(this.hFigure, dCol5, 15*dYWid + 10, 150, 30);
            this.uicbCenterOffaxisZP.build(this.hFigure, dCol5, 16*dYWid -5, 115, 30);

            
            this.uieLayerNumber.build(this.hFigure, dCol1, 16*dYWid, 75, 30);
            %this.uicbCurl.build(this.hFigure, dCol2, 16*dYWid + 10, 75, 30);
            this.uipNWAPxSize.build(this.hFigure, dCol2, 16*dYWid + 10, 150, 30);
            this.uibStageZP.build(this.hFigure, dCol1 , 17*dYWid + 10 , 100, 30);
            this.uibGenerate.build(this.hFigure, dCol2, 17*dYWid + 10 , 100, 30);
            this.uieExecStr.build(this.hFigure, dCol1, 18*dYWid, 500, 60);
            this.uieExecStr.makeMax();
            
        end
        
        function str = makeZrnStr(this)
            dZterms = eval(this.uieZernikes.get());
            
            if isempty(dZterms)
                str = ' 0 ';
            elseif mod(length(dZterms), 2) ~= 0
                error('Zernike string array must have an even number of elements');
                    
            else
                str = sprintf(' %d', length(dZterms)/2);
                for k = 1:2:length(dZterms)
                    str = sprintf('%s %d %0.4f ', str, dZterms(k), dZterms(k+1));
                end
            end
        end
            
        
        
        function load(this, path)
            if (nargin == 1)
                cPath = fullfile(this.cZPGenDir, 'recipes', '*.mat');
                [d, p] = uigetfile(cPath);
                
                if isempty(d)
                    return
                end
                
                load([p, d]);
            else
                load(path);
            end
            ceProps = fieldnames(sSaveStruct);
            
            % Set some default params:
            this.uicbInfiniteConjugate.set(false);
           
            
            for k = 1:length(ceProps)
                 % process exceptions:
                if (this.bIgnoreFileFormatOnLoad && strcmp(ceProps{k}, 'uipFileOutput'))
                    continue;
                end
            
                if (length(ceProps{k}) > 2)
                    try
                        switch ceProps{k}(1:3)
                            case 'uie'
                                this.(ceProps{k}).set(sSaveStruct.(ceProps{k}));
                            case 'uic'
                                this.(ceProps{k}).set(sSaveStruct.(ceProps{k}));
                            case 'uip'
                                this.(ceProps{k}).setSelectedIndex(sSaveStruct.(ceProps{k}));
                                
                        end
                    end
                end
            end
            
            % Set lambda and NA to force compute dr and Ep
            this.cb(this.uieLambda);
            this.cb(this.uieNA);
           
            
            
        end
        
        function save(this)
            % Get ui properties:
            ceProps = properties(this);
            sSaveStruct = struct;
            try
            for k = 1:length(ceProps)
                if (length(ceProps{k}) > 2)
                    switch ceProps{k}(1:3)
                        case 'uie'
                            sSaveStruct.(ceProps{k}) = this.(ceProps{k}).get();
                        case 'uic'
                            sSaveStruct.(ceProps{k}) = this.(ceProps{k}).get();
                        case 'uip'
                            sSaveStruct.(ceProps{k}) = this.(ceProps{k}).getSelectedIndex();
                    end
                end
            end
            catch me
            1    
            end
            
            cPath = fullfile(this.cZPGenDir, 'recipes', [regexprep(this.uieZPName.get(), '\s', '_') '.mat']);
            save(cPath, 'sSaveStruct');
        end
        

        
        function sFilePath = generate(this)
            tic
            
            cExecSt = this.uieExecStr.get();
            
            if (this.uicbComputeExternally.get()) && this.uipFileOutput.getSelectedIndex() ~= uint8(4) % can't compute WRV externally if we need to run perl scripts
                system([cExecSt, '&']);
            else
               % tic
                system(cExecSt);
                %fprintf('\nGeneration took %s\n', s2f(toc));
            end
            
            % log item to ZPLog:
            sFileName = fullfile(this.cZPGenDir, 'logs', sprintf('ZPLog_%s.csv', datestr(now, 29)));
            % check if file exists:
            if isempty(dir(sFileName)) % doesn't exist
                zpgen.writeLog(sFileName, this.ceHeaders, true);
            end
            zpgen.writeLog(sFileName, this.cLogStr, false, 'a');
            
            
             % Create a single log in ZPFiles
            sSingleLogFileName = fullfile(this.cOutputFileDir, sprintf('ZPLog_%s_%s.csv', this.uieZPName.get(), datestr(now, 29)));
            % check if file exists:
            zpgen.writeLog(sSingleLogFileName, this.ceHeaders, true, 'w');
            zpgen.writeLog(sSingleLogFileName,  this.cLogStr, false, 'a');
            
            
            
            
            if strcmp(this.arch, 'win64')
                if ~isempty(dir('C:\Perl64\bin\perl.exe'))
                    
                    % this is a hard code to perl dir, so use this
                    cPerlStr = 'C:\Perl64\bin\perl.exe';
                else
                    % assume perl is in path:
                    cPerlStr = 'perl';
                end
                
            else
                cPerlStr = 'perl';
            end
            
            
            % Execute optional PERL scripts for WRV/NWA processing 
            dNBlocks = round(sqrt(this.uieNumBlocks.get()));
            
            if isempty(this.cOutputFileDir)
                sFilePath = fullfile(this.cZPGenDir, 'ZPFiles', regexprep(this.uieZPName.get(), '\s', '_'));
            else
                sFilePath = fullfile(this.cOutputFileDir, regexprep(this.uieZPName.get(), '\s', '_'));
            end
            
            
            if this.uipFileOutput.getSelectedIndex() == uint8(4)
                
                % Zone randomization:
                if this.uicbRandomizeWRVZones.get()
                    fprintf('Randomizing zones...\n\n');
                    
                    cExStr = sprintf('%s %s %s.wrv %s_randomized.wrv', ...
                        cPerlStr, ...
                        fullfile(this.cDirThis, '..', 'bin', 'randomizeWRV.pl'), ... 
                        sFilePath, sFilePath);
                    
                    fprintf('Exec perl command: \n\t%s\n\n', cExStr);
                    system(cExStr);
                    fprintf('Zone randomization complete...\n\n');
                    
                    sFilePath = [sFilePath '_randomized'];
                end
                
                % Splitting into multiple fields:
               
                if dNBlocks > 1
                    
                    fprintf('Splitting WRV into fields...\n\n');
                    cExStr = sprintf('%s %s %s.wrv %d %d %s_multifield.wrv', ...
                        cPerlStr, ...
                        fullfile(this.cDirThis, '..', 'bin', 'splitWRVtoFieldsByFile.pl'), ... 
                        sFilePath, dNBlocks, this.uieBlockSize.get(), sFilePath);
                    system(cExStr);
                    fprintf('Exec perl command: \n\t%s\n\n', cExStr);
                    fprintf('Field splitting complete...\n\n');
                    
                     % Combine files
                     
                    fprintf('Combining WRVs...\n\n');
                    cExStr = sprintf('%s %s %s.wrv %d %d %s_multifield.wrv', ...
                        cPerlStr, ...
                        fullfile(this.cDirThis, '..', 'bin', 'combineFiles.pl'), ... 
                        sFilePath, dNBlocks, this.uieBlockSize.get(), sFilePath);
                    system(cExStr);
                    fprintf('Exec perl command: \n\t%s\n\n', cExStr);
                    fprintf('Field splitting complete...\n\n');
                    
                    sFilePath = [sFilePath '_multifield'];
                end
                
            end
            
            if this.uipFileOutput.getSelectedIndex() == uint8(1) && dNBlocks > 1
                fprintf('Splitting NWA into fields...\n\n');
                    cExStr = sprintf('%s %s %s.nwa %d %d %s_multifield.nwa', ...
                        cPerlStr, ...
                        fullfile(this.cDirThis, '..', 'bin', 'splitNWAtoFieldsByFile.pl'), ... 
                        sFilePath, dNBlocks, this.uieBlockSize.get(), sFilePath);
                    system(cExStr);
                    fprintf('Exec perl command: \n\t%s\n\n', cExStr);
                    fprintf('Field splitting complete...\n\n');
                    
                     % Combine files
                    fprintf('Combining NWAs...\n\n');
                    cExStr = sprintf('%s %s %s_multifield.nwa %d %d %s_multifield.nwa', ...
                        cPerlStr, ...
                        fullfile(this.cDirThis, '..', 'bin', 'combineFilesNWA.pl'), ... 
                        sFilePath, dNBlocks, this.uieBlockSize.get(), sFilePath);
                    system(cExStr);
                    fprintf('Exec perl command: \n\t%s\n\n', cExStr);
                    fprintf('Field splitting complete...\n\n');
                    
                    sFilePath = [sFilePath '_multifield'];
                
            end
            
            
            ext = '';
            switch(this.uipFileOutput.getSelectedIndex())
                case uint8(1)
                    ext = '.nwa';
                case uint8(2)
                    ext = '.gds';
                case uint8(4)
                    ext = '.wrv';
            end
            
            % Add extension:
            sZipFileName = [sFilePath, '.zip'];
            sFilePath = [sFilePath ext];
            
            % Zip file
            if (this.uicbCompressFiles.get())
                fprintf('Compressing file and log %s, %s\n', sFilePath, sSingleLogFileName);
                zip(sZipFileName,{sFilePath, sSingleLogFileName});
                
                if (~this.bPreserveUncompressedFiles)
                    delete(sFilePath);
                end
            end
            
            
            fprintf('Zone plate %s finished in %s \n', sFilePath, s2f(toc));
            
           
            
        end
        
        function stageZP(this)
            
            % Do some checks:
%             if this.uieNumBlocks.get() > 1 && this.uieBlockSize.get() > 800000
%                 warndlg('WRV Blocksize must be 800,000 or less to prevent overrun.  Aborting stage');
%                 return
%             end
            
            if strcmp(this.arch, 'win64')
                sPrefix = [cd '\src\bin\ZPGen.exe '];
                sFilePath = regexprep(this.uieZPName.get(), '\s', '_');
            else
                sPrefix =  fullfile(this.cZPGenDir, 'bin', 'ZPGen');
                
                if isempty(this.cOutputFileDir)
                    sFilePath = fullfile(this.cZPGenDir, 'ZPFiles', regexprep(this.uieZPName.get(), '\s', '_'));
                else
                    sFilePath = fullfile(this.cOutputFileDir, regexprep(this.uieZPName.get(), '\s', '_'));
                end
                
            end
            
            
           
            sParams = '';
            sTimestamp = datestr(now, 30);
            
           
            
   
            
            % ------- Generate sParams ------------%
            % Zone tolerance
            sParams = [sParams sprintf(' %0.4f ', this.uieZoneTol.get())];
            % lambda (nm)
            sParams = [sParams sprintf(' %0.4f ', this.uieLambda.get())];
            % p (um)
            sParams = [sParams sprintf(' %0.4f ', this.uieP.get())];
            % q (um)
            sParams = [sParams sprintf(' %0.4f ', this.uieQ.get())];
            % obscuration sigma
            sParams = [sParams sprintf(' %0.4f ', this.uieObscurationSigma.get())];
            % NA
            sParams = [sParams sprintf(' %0.4f ', this.uieNA.get())];
            % zernike string
            sParams = [sParams this.makeZrnStr()];
            % custom Mask
            sParams = [sParams sprintf(' %d ', this.uipCustomMask.getSelectedIndex() - 1)];
            % Tilted zp plane (about x-axis) (deg)
            sParams = [sParams sprintf(' %0.4f ', this.uieZPTilt.get() * pi/180)];
            % CRA azimuthal (degrees)
            sParams = [sParams sprintf(' %0.4f ', this.uieCraAz.get())];
            % CRA angle (degree)
            sParams = [sParams sprintf(' %0.4f ', this.uieCraAngle.get())];
            % Anamorphic factor
            sParams = [sParams sprintf(' %0.4f ', this.uieAnamorphicFac.get())];
            % Phase of zernike region (deg)
            sParams = [sParams sprintf(' %0.4f ', this.uieZPPhase.get() * pi/180 )];
            % Apodization of central reg [1]
            sParams = [sParams sprintf(' %0.4f ', this.uieApodMag.get())];
            % Apd Fn (1=ham, 2=gaus)
            sParams = [sParams sprintf(' %d ', this.uipApodFn.getSelectedIndex() - 1)];
            % ZPC inner radius (PC)
            sParams = [sParams sprintf(' %0.4f ', this.uieZPCR1.get())];
            % ZPC outer radius (PC)
            sParams = [sParams sprintf(' %0.4f ', this.uieZPCR2.get())];
            % zone bias (nm) (can be negative, e.g. for gaps)
            sParams = [sParams sprintf(' %0.4f ', this.uieZoneBias.get())];
            % File output (0:arc, 1:GDS, 2:GDS+txt, 3:WRV)
            sParams = [sParams sprintf(' %d ', this.uipFileOutput.getSelectedIndex() - 1)];
            % Reverse tone ([0]: no, 1:yes)
            sParams = [sParams sprintf(' %d ', this.uicbReverseTone.get())];
            % Buttress idx (0: none, 1: gapped zones, 2: gaps)
            sParams = [sParams sprintf(' %d ', this.uipButtressIdx.getSelectedIndex() - 1)];
            % Buttress W (width in dr)
            sParams = [sParams sprintf(' %0.4f ', this.uieButtressW.get())];
            % Buttress T (period in dr)
            sParams = [sParams sprintf(' %0.4f ', this.uieButtressT.get())];
            % Center offaxis zone plate
            sParams = [sParams sprintf(' %d ', this.uicbCenterOffaxisZP.get())];
            % Blocksize [1e6]
            sParams = [sParams sprintf(' %d ', this.uieBlockSize.get())];
            % Multiple patterning, number of parts
            sParams = [sParams sprintf(' %d ', round(this.uieMultiplePatN.get()))];
            % Multiple patterning, index of parts
            sParams = [sParams sprintf(' %d ', round(this.uieMultiplePatIdx.get()))];
            
            % Layer number OR num blocks on side
            if this.uipFileOutput.getSelectedIndex() == uint8(4)
                dVal = round(sqrt(this.uieNumBlocks.get()));
            else
                dVal = round(this.uieLayerNumber.get());
            end
            sParams = [sParams sprintf(' %d ', dVal)];
            
            
            % NWA pixel size or WRV pixel size 
            if this.uipFileOutput.getSelectedIndex() == uint8(4)
                sParams = [sParams sprintf(' %d ', this.uieWRVBlockUnit.get())];
            else
                sParams = [sParams sprintf(' %d ', this.uipNWAPxSize.getSelectedIndex() - 1)];
            end
            
            
            
            this.cExecStr = [sPrefix, sParams, sFilePath];
            if strcmp(this.arch, 'win64')
                 this.cExecStr = [sPrefix, sParams, sFilePath, ' & move ' sFilePath '.* src\ZPFiles'];
            else
                 this.cExecStr = [sPrefix, sParams, sFilePath];
            end
            
            
            
            this.uieExecStr.set(this.cExecStr);
            
            logItem = [ this.uieZPName.get(), ',', this.cBuildName, ',', regexprep(sParams, '\s\s', ','), ',', this.cExecStr];
            this.cLogStr = logItem; 
            
            % Echo string arguments to console for use in vscode argument
            % array:
            
            ceParamArray = split(sParams, ' ');
            sParamQt = '[';
            for k = 1:length(ceParamArray)
                if (length(ceParamArray{k}) > 0)
                    sParamQt = [sParamQt '"' ceParamArray{k} '", '];
                end
            end
            sParamQt = [sParamQt '"out"]'];
            
            fprintf('Param argument array:\n%s\n\n', sParamQt);
            
            
            
           
            
        end
      
        
        
    end
    
   
    
    
end

