% UI for creating ZPGen scripts locally.  Launch using launch_ZPGEN.m
% script.  Converted to MPM package on 04/14/2019 and it now includes ZPGen
% C++ script as a dependency.  ZPGen requires a working ZPGenPlus
% executable which can be built using the "make" command for unix machines
% running gcc C++ compiler.  This file may need to be modified to
% accommodate different setups
%
% Changelog:
% 3.2.0: exposing zone randomization
%
% 3.1.0: Adding an explicit azimuth, populated by k
%
% 3.0.0: Migrating to new Hologen ZP framework
%
% 2.16.1: Adding new obscurations
%
% 2.16.0: Adding GTX support
%
% 2.15.0: Forcing zone aberration min shape tolerance to be a multiple of
% buttress shape
%
% 2.14.0: Dose now calculated based on true area fraction rather than bias
% in WRV files, useful when the files are rounded to pixels in ways that
% contribute significantly to area fraction
%
% 2.13.0: Fixing non-circular zone jog issue
%
% 2.12.0: Adding ability for WRV to round block number
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
        cBuildName = 'ZPGen v3.2.0';
        
        dWidth  = 1500;
        dHeight =  800;
        hc      = 1240.71
        ceHeaders = {   'File name', ...
            'Build version', ...
            'Zone tolerance',...
            'lambda (nm)',...
            'P (um)',...
            'Q (um)',...
            'K-vec',...
            'Beta-1', ...
            'Beta-2', ...
            'Obscuration sigma',...
            'NA',...
            'Zernikes', ...
            'Custom mask index',...
            'Anamorphic fac', ...
            'ZPC phase (deg)',...
            'ZPC apodization',...
            'Ap function',...
            'ZPC inner rad',...
            'ZPC outer rad',...
            'Zone bias (nm)', ...
            'File format',...
            'Tone reversal',...
            'Zone start randomized', ...
            'Buttressing',...
            'Buttress width',...
            'Buttress period',...
            'Off-axis centering', ...
            'WRV blocksize',...
            'Multiple patterning N',...
            'Multiple patterning i',...
            'Layer number',...
            'WRV Block unit/NWA px size',...
            'Exec string'...
            };
        
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
            'Obscuration Only', ...
            'Sliver', ...
            'KTobs'};
    end
    
    properties
        
        % Graphical elements
        hFigure     % Main figure (not overwritable)
        
        bIgnoreFileFormatOnLoad = false
        
        uiZPPropagator
        
        hLines = {}
        hPatches = {}
        
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
        uitNz
        uitNzLabel
        
        uiePhat
        uieKhat
        uieBeta1hat
        uieBeta2hat
        uiePNorm
        
        uiePAzi
        uieKAzi
        uieBetaAzi
        
        
        uiePAngle
        uieKAngle
        uieBeta1Angle
        uieBeta2Angle
        
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
        uieBlockGrid
        uieMultiplePatN
        uieMultiplePatIdx
        uieLayerNumber
        uicbCurl
        uipCustomMask
        uipNWAPxSize
        
        
        
        hUIPanelFile
        hUIPanelOptical
        hUIPanelPattern
        hUIPanelExecute
        
        uieWRVBlockUnit
        
        uieAnamorphicFac
        uieAnamorphicAzi
        uicbCenterOffaxisZP
        uicbOffsetTiltedZP
        
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
        
        haGeom
        haXZ
        haYZ
        haPupil
        
        
        cExecStr = []
        cLogStr = ''
        arch = computer('arch')
        
        cZPGenDir = fullfile(fileparts(mfilename('fullpath')), '..');
        cOutputFileDir = fullfile(fileparts(mfilename('fullpath')), '..');
        
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
            this.uitNz                  = mic.ui.common.Text( 'cVal', '100', 'dFontSize', 14, 'cFontWeight', 'bold');
            this.uitNzLabel             = mic.ui.common.Text('cType', 'd', 'cVal', 'N Zones (parent)');
            this.uieEp                  = mic.ui.common.Edit('cLabel', 'Pht Energy (eV)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieDr                  = mic.ui.common.Edit('cLabel', 'dr (nm, On-Ax)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            
            
            this.uieAnamorphicFac       = mic.ui.common.Edit('cLabel', 'Ana. fac.', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieAnamorphicAzi       = mic.ui.common.Edit('cLabel', 'Azimuth.', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZernikes            = mic.ui.common.Edit('cLabel', 'Zernike string', 'cType', 'c', 'fhDirectCallback', @this.cb);
            this.uieAlpha               = mic.ui.common.Edit('cLabel', 'Alpha', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieZPTilt              = mic.ui.common.Edit('cLabel', 'Tilt (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            %direction cosines vectors:
            this.uiePhat                = mic.ui.common.Edit('cLabel', 'p-hat (Optical Axis)', 'cType', 'c', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieKhat                = mic.ui.common.Edit('cLabel', 'k-hat (CRA)', 'cType', 'c', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieBeta1hat            = mic.ui.common.Edit('cLabel', 'Beta 1 (ZP Basis 1)', 'cType', 'c', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieBeta2hat            = mic.ui.common.Edit('cLabel', 'Beta 2 (ZP Basis 2)', 'cType', 'c', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            
            this.uiePAngle              = mic.ui.common.Edit('cLabel', 'p-tilt  (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uiePNorm              = mic.ui.common.Edit('cLabel', 'p-norm (um)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            
            this.uieKAngle              = mic.ui.common.Edit('cLabel', 'k-tilt (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieBeta1Angle           = mic.ui.common.Edit('cLabel', 'Beta 1 tilt (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieBeta2Angle           = mic.ui.common.Edit('cLabel', 'Beta 2 tilt (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            
            
            this.uiePAzi                = mic.ui.common.Edit('cLabel', 'p-azi (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieKAzi                = mic.ui.common.Edit('cLabel', 'k-azi (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            this.uieBetaAzi             = mic.ui.common.Edit('cLabel', 'beta-azi (deg)', 'cType', 'd', 'fhDirectCallback', @this.cb, 'lNotifyOnProgrammaticSet', false);
            
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
            
            this.uipFileOutput          = mic.ui.common.Popup('cLabel', 'Output file type', 'ceOptions', {'NWA (ARC)', 'GDS', 'GDS + txt', 'WRV', 'GTX'}, ...
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
            this.uieBlockGrid           = mic.ui.common.Edit('cLabel', 'Block grid (pm)', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieNumBlocks           = mic.ui.common.Edit('cLabel', 'Block (2N + 1)^2', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uieWRVBlockUnit        = mic.ui.common.Edit('cLabel', 'Block unit (pm))', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            
            this.uieMultiplePatN        = mic.ui.common.Edit('cLabel', 'Multiple Patterning N', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieMultiplePatIdx      = mic.ui.common.Edit('cLabel', 'Multiple Patterning idx', 'cType', 'd', 'fhDirectCallback', @this.cb);
            this.uieLayerNumber         = mic.ui.common.Edit('cLabel', 'GDS layer', 'cType', 'd', 'fhDirectCallback', @this.cb);
            
            this.uicbCurl               = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Curl progress', 'fhDirectCallback', @this.cb);
            
            this.uicbComputeExternally  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Compute Externally', 'fhDirectCallback', @this.cb);
            this.uicbCompressFiles  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Compress ZP with Log', 'fhDirectCallback', @this.cb);
            
            
            this.uicbRandomizeWRVZones  = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Randomize Zones', 'fhDirectCallback', @this.cb);
            
            
            this.uicbCenterOffaxisZP    = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Center Off-axis ZP', 'fhDirectCallback', @this.cb);
            this.uicbOffsetTiltedZP    = mic.ui.common.Checkbox('lChecked', false, 'cLabel', 'Offset tilted ZP', 'fhDirectCallback', @this.cb);
            
            this.uibStageAndGenerate    = mic.ui.common.Button('cText', 'Stage and Generate', 'fhDirectCallback', @this.cb);
            
            this.uibStageZP             = mic.ui.common.Button('cText', 'Stage ZP', 'fhDirectCallback', @this.cb);
            this.uibGenerate            = mic.ui.common.Button('cText', 'Generate', 'fhDirectCallback', @this.cb);
            this.uibSave                = mic.ui.common.Button('cText', 'Save ZP', 'fhDirectCallback', @this.cb);
            this.uibLoad                = mic.ui.common.Button('cText', 'Load ZP', 'fhDirectCallback', @this.cb);
            this.uibOpenInFinder        = mic.ui.common.Button('cText', 'Open Folder', 'fhDirectCallback', @this.cb);
            
            this.uieZPName              = mic.ui.common.Edit('cLabel', 'ZP Name', 'cType',  'c', 'fhDirectCallback', @this.cb);
            
            this.uieExecStr             = mic.ui.common.Edit('cLabel', 'Exec string', 'cType', 'c', 'fhDirectCallback', @this.cb);
            
            this.uieZernikes.set('[]');
            this.uiePhat.set('[0, 0, 1]');
            this.uieKhat.set('[0, 0, 1]');
            this.uieBeta1hat.set('[1, 0, 0]');
            this.uieBeta2hat.set('[0, 1, 0]');
            this.uiePNorm.set(500);
            this.uieQ.set(1e6);
            
            
            this.uiePAzi.set(0);
            this.uieKAzi.set(0);
            this.uieBetaAzi.set(0);
            
            
            this.uipFileOutput.setSelectedIndex(uint8(2));
            this.uipCustomMask.setSelectedIndex(uint8(1));
            this.uieZPName.set('Untitled');
            
            this.uieZoneTol.set(0.01);
            this.uieAnamorphicFac.set(1);
            this.uieAnamorphicAzi.set(0);
            
            this.uieLambda.set(13.5);
            this.uieNA.set(0.08);
            
            this.uieEp.set(this.hc/13.5);
            
            
            
            
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
            
            this.uiePAngle.set(0);
            this.uieKAngle.set(0);
            this.uieBeta1Angle.set(0);
            this.uieBeta2Angle.set(0);
            
            
            
            this.uipButtressIdx.setSelectedIndex(uint8(1));
            this.uipNWAPxSize.setSelectedIndex(uint8(1));
            
            this.uieButtressW.set(0.6);
            this.uieButtressT.set(6);
            this.uieDoseBiasScaling.set(1);
            this.uieBlockSize.set(8e5);
            this.uieNumBlocks.set(1);
            this.uieBlockGrid.set(0);
            this.uieMultiplePatN.set(1);
            this.uieMultiplePatIdx.set(1);
            this.uieLayerNumber.set(1);
            
            this.uicbCenterOffaxisZP.set(true);
            this.uicbOffsetTiltedZP.set(false);
            this.uicbInfiniteConjugate.set(false);
            this.uicbRandomizeWRVZones.set(true);

            
            
            
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
                    case 'anamorphicAzi'
                        this.uieAnamorphicAzi.set(varargin{k+1});
                    case 'paramW'
                        this.uieButtressW.set(varargin{k+1});
                    case 'outputIdx'
                        this.uipFileOutput.setSelectedIndex(uint8(varargin{k+1}))
                    case 'centerZP'
                        this.uicbCenterOffaxisZP.set(varargin{k+1});
                    case 'ofsetTilted'
                        this.uicbOffsetTiltedZP.set(varargin{k+1});
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
        
        function setNz(this)
            
            dLambda = this.uieLambda.get() / 1000;
            dNA = this.uieNA.get();
            dK = eval(this.uieKhat.get());
            dP = eval(this.uiePhat.get()) * this.uiePNorm.get();
            dQ = this.uieQ.get();
            
            dBeta1 = eval(this.uieBeta1hat.get());
            dBeta2 = eval(this.uieBeta2hat.get());
            
            dn = cross(dBeta1, dBeta2);
            
            dTMin = dLambda/dNA;
            
            dTh = linspace(0, 2*pi, 101);
            dTh = dTh(1:end-1);
            
            
            
            NMax = 1;
            NMin = 1;
            
            Rs = [];
            for k = 1:length(dTh)
                th = dTh(k);
                
                fq = 1/dTMin * [cos(th), sin(th)] + dK(1:2)/dLambda;
                
                % get location of coordinate:
                r = zpgeom.freq2zpCoord(fq, dn, dP, dLambda);
                Rs(k) = norm(r - dP, 2);
                
                % compute OPD
                opd = zpgeom.xyz2OPD(r, dP, dQ, dLambda) - ...
                    zpgeom.xyz2OPD(dP, dP, dQ, dLambda);
            end
            
            NMax = max([NMax, ceil(max(opd) * 2)]);
            NMin = min([NMin, floor(min(opd) * 2)]);
            
            minR = min(Rs);
            maxR = max(Rs);
            
            Nz = NMax - NMin + 1;
            
            this.uitNz.set(sprintf('%d', Nz));
            this.uitD.set(sprintf('%0.2f', maxR * 2));
            
        end
        
        
        function updatePhat(this)
            dTh = this.uiePAngle.get();
            dPhi = this.uiePAzi.get();
            
            if dTh == 0
                this.uiePhat.set('[0, 0, 1]')
            elseif dPhi == 0
                this.uiePhat.set(sprintf('[sind(%g), 0, cosd(%g)]', dTh, dTh));
            else
                switch dPhi
                    case 90
                        this.uiePhat.set(sprintf('[0, sind(%g), cosd(%g)]', dTh, dTh));
                    case 180
                        this.uiePhat.set(sprintf('[-sind(%g), 0, cosd(%g)]', dTh, dTh));
                    case 270
                        this.uiePhat.set(sprintf('[0, -sind(%g), cosd(%g)]', dTh, dTh));
                    otherwise
                        this.uiePhat.set(sprintf('[cosd(%g)*sind(%g), sind(%g)*sind(%g), cosd(%g)]', dPhi, dTh, dPhi, dTh, dTh));
                end
            end
            this.buildOpticalTemplate();
        end
        function updateKhat(this)
            dTh = this.uieKAngle.get();
            dPhi = this.uieKAzi.get();
            
            
            if dTh == 0
                this.uieKhat.set('[0, 0, 1]')
            elseif dPhi == 0
                this.uieKhat.set(sprintf('[sind(%g), 0, cosd(%g)]', dTh, dTh));
            else
                switch dPhi
                    case 90
                        this.uieKhat.set(sprintf('[0, sind(%g), cosd(%g)]', dTh, dTh));
                    case 180
                        this.uieKhat.set(sprintf('[-sind(%g), 0, cosd(%g)]', dTh, dTh));
                    case 270
                        this.uieKhat.set(sprintf('[0, -sind(%g), cosd(%g)]', dTh, dTh));
                    otherwise
                        this.uieKhat.set(sprintf('[cosd(%g)*sind(%g), sind(%g)*sind(%g), cosd(%g)]', dPhi, dTh, dPhi, dTh, dTh));
                end
            end
            this.buildOpticalTemplate();
        end
        function updateBhat(this)
            dTh = this.uieBeta1Angle.get();
            dPhi = this.uieBetaAzi.get();
            
            
            if dTh == 0
                this.uieBeta1hat.set('[1, 0, 0]')
                this.uieBeta2hat.set(sprintf('[0, 1, 0]'));
            elseif dPhi == 0
                this.uieBeta1hat.set(sprintf('[cosd(%g), 0, -sind(%g)]', dTh, dTh));
                this.uieBeta2hat.set(sprintf('[0, 1, 0]'));
            else
                switch dPhi
                    case 90
                        this.uieBeta1hat.set(sprintf('[1, 0, 0]'));
                        this.uieBeta2hat.set(sprintf('[0, cosd(%g), -sind(%g)]', dTh, dTh));
                    case 180
                        this.uieBeta1hat.set(sprintf('[cosd(%g), 0, sind(%g)]', dTh, dTh));
                        this.uieBeta2hat.set(sprintf('[0, 1, 0]'));
                    case 270
                        this.uieBeta1hat.set(sprintf('[1, 0, 0]'));
                        this.uieBeta2hat.set(sprintf('[0, cosd(%g), sind(%g)]', dTh, dTh));
                    otherwise
                        
                end
            end
            this.buildOpticalTemplate();
        end
        
        
        
        function cb(this, src, dat)
            switch src
                case this.uiePhat
                    % Sanitize:
                    dP = eval(this.uiePhat.get());
                    dP = dP/norm(dP,2);
                    this.uiePhat.set(sprintf('[%g, %g, %g]', dP(1), dP(2), dP(3)));
                    
                    % set angle in degrees to difference between this and
                    % z-hat:
                    dTh = acosd(dP * [0;0;1]);
                    dRes = [0,0, 1] - dP;
                    dAzi = atan2(dRes(2), dRes(1));
                    
                    this.uiePAngle.setWithoutNotify(dTh);
                    this.uiePAzi.setWithoutNotify(dAzi);
                    
                    this.setNz();
                    this.buildOpticalTemplate();
                    
                case this.uiePNorm
                    
                    this.setNz();
                    this.buildOpticalTemplate();
                    
                case this.uiePAngle
                    this.updatePhat();
                case this.uiePAzi
                    this.updatePhat();
                case this.uieKhat
                    dK = eval(this.uieKhat.get());
                    
                    dK = dK/norm(dK,2);
                    this.uieKhat.set(sprintf('[%g, %g, %g]', dK(1), dK(2), dK(3)));
                    
                    
                    dTh = acosd(dK * [0;0;1]);
                    dRes = [0,0, 1] - dK;
                    dAzi = atan2(dRes(2), dRes(1));
                    
                    this.uieKAngle.setWithoutNotify(dTh);
                    this.uieKAzi.setWithoutNotify(dAzi);
                    this.uieAnamorphicAzi.setWithoutNotify(dAzi);
                    
                    this.buildOpticalTemplate();
                    
                case this.uieKAngle
                    this.updateKhat();


                case this.uieKAzi
                    this.updateKhat();
                    dAzi = this.uieKAzi.get();
                     this.uieAnamorphicAzi.setWithoutNotify(dAzi);
                    
                case this.uieBeta1hat
                    % Sanitize:
                    dB = eval(this.uieBeta1hat.get());
                    dB = dB/norm(dB,2);
                    this.uieBeta1hat.set(sprintf('[%g, %g, %g]', dB(1), dB(2), dB(3)));
                    
                    this.buildOpticalTemplate();
                    
                    
                    
                case this.uieBeta2hat
                    % Sanitize:
                    dB = eval(this.uieBeta2hat.get());
                    dB = dB/norm(dB,2);
                    this.uieBeta2hat.set(sprintf('[%g, %g, %g]', dB(1), dB(2), dB(3)));
                    
                    this.buildOpticalTemplate();
                    
                case this.uieBeta1Angle
                    this.updateBhat();
                case this.uieBetaAzi
                    this.updateBhat();
                    
                case this.uieBeta2Angle
                    
                    
                    this.buildOpticalTemplate();
                case this.uibGenerate
                    this.generate();
                    
                case this.uieCraAngle
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    this.uitTrueDr.set(sprintf('%0.3f', this.getTrueDr()));
                    this.setNz();
                    
                case this.uieP
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    this.setNz();
                case this.uieQ
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    this.setNz();
                case this.uieNA
                    this.uie4xNA.setWithoutNotify(this.uieNA.get()*4)
                    setVal = this.uieLambda.get()/this.uieNA.get()/2;
                    this.uieDr.setWithoutNotify(setVal)
                    
                    
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    this.uitTrueDr.set(sprintf('%0.3f', this.getTrueDr()));
                    this.setNz();
                    this.buildOpticalTemplate();
                case this.uie4xNA
                    this.uieNA.setWithoutNotify(this.uie4xNA.get()/4)
                    setVal = this.uieLambda.get()/this.uieNA.get()/2;
                    this.uieDr.setWithoutNotify(setVal)
                    
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    
                    this.buildPupilView();
                case this.uieDr
                    setVal = this.uieLambda.get()/this.uieDr.get()/2;
                    this.uieNA.setWithoutNotify(setVal)
                    this.uie4xNA.setWithoutNotify(setVal * 4)
                    
                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    
                    this.buildPupilView();
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
                    this.setNz();                    this.uitD.set(sprintf('%0.2f', this.getD()));
                    
                    this.cb(this.uieNA);
                    
                    this.buildPupilView();
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
                    
                case this.uieAnamorphicFac
                    this.buildPupilView();
                case this.uieAnamorphicAzi
                    this.buildPupilView();
                case this.uieObscurationSigma
                    this.buildPupilView();
                    
            end
        end
        
        function zpFilePath = stageAndGenerate(this)
            this.stageZP();
            drawnow;
            zpFilePath = this.generate();
        end
        
        
        function buildPupilView(this)
            
            for k = 1:length(this.hPatches)
                delete(this.hPatches{k})
            end
            this.hPatches = {};
            
            th = linspace(0, 2*pi, 101);
            th = th(1:end-1);
            
            Rx = this.uieNA.get();
            Ry = this.uieNA.get()/this.uieAnamorphicFac.get();
            
            azi = pi/180 * this.uieAnamorphicAzi.get() - pi/2;
            
            
            dSigma = this.uieObscurationSigma.get();

                                    
            X = Rx * cos(th);
            Y = Ry * sin(th);
            
            R = [cos(azi), -sin(azi); sin(azi), cos(azi)];
            

                        
            xy = R * [X;Y];
            X = xy(1,:);
            Y = xy(2,:);
            
            
            if isempty(this.haPupil)
                return
            end
            
            this.hPatches{end+1} = patch('Parent', this.haPupil, 'XData', X, 'YData', Y, 'FaceColor', 'g');
            this.hPatches{end+1} = patch('Parent', this.haPupil, 'XData', X * dSigma, 'YData', Y * dSigma, 'FaceColor', 'k');

            
            mn = min([X, Y]);
            mx = max([X, Y]);
            this.haPupil.XLim = [mn mx];
            this.haPupil.YLim = [mn, mx];
            
            
        end
        
        function buildOpticalTemplate(this)
            
            dP = eval(this.uiePhat.get());
            %             dPNorm = this.uiePNorm.get();% = eval(this.uiePhat.get());
            dPNorm = 8;
            
            dK = eval(this.uieKhat.get());
            dKNorm = 1/norm(dK ,2);
            
            dB1 = eval(this.uieBeta1hat.get());
            dB2 = eval(this.uieBeta2hat.get());
            dB3 = cross(dB2, dB1);
            
            % Plotting the main axes on the given axes handle this.haGeom
            
            %             hold(this.haGeom, 'on');
            
            if ~isempty(this.hLines)
                for k = 1:length(this.hLines)
                    delete(this.hLines{k});
                    
                end
                
                this.hLines = {};
                
            end
            
            
            
            % z-axis (left to right)
            this.hLines{end+1} = line(this.haGeom, [-1, 16], [0, 0], [0, 0], 'Color', 'k', 'LineStyle', ':','LineWidth', 1);
            
            
            
            % y-axis (up and down)
            this.hLines{end+1} = line(this.haGeom, [0, 0], [-1, 1], [0, 0], 'Color', 'b', 'LineWidth', 1);
            
            % x-axis (in and out of the page)
            this.hLines{end+1} = line(this.haGeom, [0, 0], [0, 0], [-1, 1], 'Color', 'b', 'LineWidth', 1);
            
            % Plotting the shifted x and y axes centered on z-axis at z = 8
            
            % shifted x-axis
            %             this.hLines{end+1} = line(this.haGeom, [8, 8], [0, 0], [-1, 1], 'Color', 'b', 'LineWidth', 1.5);
            %             this.hLines{end+1} = line(this.haGeom, [8, 8], [-1, 1], [0, 0], 'Color', 'b', 'LineWidth', 1.5);
            %
            %             % shifted x-axis
            %             this.hLines{end+1} = line(this.haGeom, [16, 16], [0, 0], [-1, 1], 'Color', 'b', 'LineWidth', 1.5);
            %             this.hLines{end+1} = line(this.haGeom, [16, 16], [-1, 1], [0, 0], 'Color', 'b', 'LineWidth', 1.5);
            
            
            % Draw k vector and P vectors
            this.hLines{end+1} = line(this.haGeom, [0, 2*dP(3)*dPNorm], [0, 2*dP(1)*dPNorm], [0, 2*dP(2)*dPNorm], 'Color', 'g', 'LineWidth', 3);
            this.hLines{end+1} = line(this.haGeom, [-dK(3)*dKNorm, 0], [-dK(1)*dKNorm, 0], [-dK(2)*dKNorm, 0], 'Color', 'r', 'LineWidth', 3);
            this.hLines{end+1} = line(this.haGeom, [0, 8* dK(3)*dKNorm], [0, 8*dK(1)*dKNorm], [0, 8*dK(2)*dKNorm], 'Color', 'r', 'LineWidth', 0.5);
            this.hLines{end+1} = line(this.haGeom, [8* dK(3)*dKNorm, 2*dP(3)*dPNorm], [8*dK(1)*dKNorm, 2*dP(1)*dPNorm], [8*dK(2)*dKNorm, 2*dP(2)*dPNorm], 'Color', 'r', 'LineWidth', 0.5);
            
            
            % Draw ZP axes
            this.hLines{end+1} = line(this.haGeom, 8* dK(3)*dKNorm*[1,1], 8*dK(1)*dKNorm*[1,1],  8*dK(2)*dKNorm + [-1, 1], 'Color', 'm', 'LineWidth', 1);
            this.hLines{end+1} = line(this.haGeom, 8* dK(3)*dKNorm*[1,1], 8*dK(1)*dKNorm + [-1, 1], [1,1] * 8*dK(2)*dKNorm, 'Color', 'm', 'LineWidth', 1);
            
            % Draw ZP normal:
            this.hLines{end+1} = line(this.haGeom, [0, dB3(3)] + 8*dK(3)*dKNorm, [0, dB3(1)] + 8*dK(1)*dKNorm,[0, dB3(2)] +  8*dK(2)*dKNorm, 'Color', [1, 0.5, 0], 'LineWidth', 3);
            
            
            % Draw OAxis axes:
            this.hLines{end+1} = line(this.haGeom,  dP(3)*dPNorm*[1,1], dP(1)*dPNorm*[1,1],  dP(2)*dPNorm + [-1, 1], 'Color', 'b', 'LineWidth', 1.5);
            this.hLines{end+1} = line(this.haGeom, dP(3)*dPNorm*[1,1], dP(1)*dPNorm + [-1, 1], [1,1] * dP(2)*dPNorm, 'Color', 'b', 'LineWidth', 1.5);
            this.hLines{end+1} = line(this.haGeom,  2*dP(3)*dPNorm*[1,1], 2*dP(1)*dPNorm*[1,1],  2*dP(2)*dPNorm + [-1, 1], 'Color', 'b', 'LineWidth', 1.5);
            this.hLines{end+1} = line(this.haGeom, 2*dP(3)*dPNorm*[1,1], 2*dP(1)*dPNorm + [-1, 1], 2*[1,1] * dP(2)*dPNorm, 'Color', 'b', 'LineWidth', 1.5);
            
            % Adjust the view
            view(this.haGeom, -20, 30);  % Adjust for the perspective where z-axis is horizontal
            
            % Set axis properties
            axis(this.haGeom, 'equal');
            grid(this.haGeom, 'on');
            xlabel(this.haGeom, 'Z');
            ylabel(this.haGeom, 'X');
            zlabel(this.haGeom, 'Y');
            
            hold(this.haXZ, 'on');
            grid(this.haXZ, 'on');
            
            this.hLines{end+1} = quiver3(this.haXZ, 0,0, 0, dPNorm/8 *dP(3), dPNorm/8 *dP(1), dPNorm/8 *dP(2), 'Color','g', 'linewidth', 2);
            this.hLines{end+1} = quiver3(this.haXZ, 0, 0, 0, dB3(3), dB3(1), dB3(2),'Color',[1, 0.5, 0],'linewidth', 2);
            this.hLines{end+1} = quiver3(this.haXZ, -dK(3), -dK(1), -dK(2), dK(3), dK(1), dK(2), 'Color','r','linewidth', 2);
            
            this.hLines{end+1} = line(this.haXZ, [-1, 1], [0,0], 'Color', 'k', 'LineStyle', ':','LineWidth', 1);
            
            view(this.haXZ, 0, 90)
            axis(this.haXZ, [-1, 1, -1, 1, -1, 1])
            xlabel(this.haXZ, 'Z');
            ylabel(this.haXZ, 'X');
            
            
            hold(this.haXZ, 'off');
            
            hold(this.haYZ, 'on');
            grid(this.haYZ, 'on');
            
            xlabel(this.haYZ, 'Z');
            ylabel(this.haYZ, 'Y');
            
            this.hLines{end+1} = quiver3(this.haYZ, 0,0, 0, dPNorm/8 *dP(3), dPNorm/8 *dP(1), dPNorm/8 *dP(2), 'Color','g', 'linewidth', 2);
            this.hLines{end+1} = quiver3(this.haYZ, 0, 0, 0, dB3(3), dB3(1), dB3(2),'Color',[1, 0.5, 0],'linewidth', 2);
            this.hLines{end+1} = quiver3(this.haYZ, -dK(3), -dK(1), -dK(2), dK(3), dK(1), dK(2), 'Color','r','linewidth', 2);
            
            this.hLines{end+1} = line(this.haYZ, [-1, 1], [0,0], 'Color', 'k', 'LineStyle', ':','LineWidth', 1);
            
            view(this.haYZ, 0, 0)
            axis(this.haYZ, [-1, 1, -1, 1, -1, 1])
            hold(this.haYZ, 'off');
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
            
            
            this.hUIPanelFile = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'File',...
                'FontWeight', 'Bold',...
                'Clipping', 'on',...
                'BorderWidth',1, ...
                'Position', mic.Utils.lt2lb([20 20 860 100], this.hFigure) ...
                );
            
            this.hUIPanelOptical = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'Optical',...
                'FontWeight', 'Bold',...
                'Clipping', 'on',...
                'BorderWidth',1, ...
                'Position', mic.Utils.lt2lb([20 140 860 620], this.hFigure) ...
                );
            
            this.hUIPanelPattern = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'Pattern',...
                'FontWeight', 'Bold',...
                'Clipping', 'on',...
                'BorderWidth',1, ...
                'Position', mic.Utils.lt2lb([890 20 600 360], this.hFigure) ...
                );
            
            this.hUIPanelExecute = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'Execute',...
                'FontWeight', 'Bold',...
                'Clipping', 'on',...
                'BorderWidth',1, ...
                'Position', mic.Utils.lt2lb([890 400 600 360], this.hFigure) ...
                );
            
            
            this.haGeom = axes('Parent', this.hUIPanelOptical, ...
                'Units', 'pixels', ...
                'Position', [0, 30, 920, 200], ...
                'XTick', [], 'YTick', []);
            
            this.haXZ = axes('Parent', this.hUIPanelOptical, ...
                'Units', 'pixels', ...
                'Position', [340, 275, 125, 125], ...
                'XTick', [], 'YTick', []);
            
            
            this.haYZ = axes('Parent', this.hUIPanelOptical, ...
                'Units', 'pixels', ...
                'Position', [510, 275, 125, 125], ...
                'XTick', [], 'YTick', []);
            
            this.haPupil = axes('Parent', this.hUIPanelOptical, ...
                'Units', 'pixels', ...
                'Position', [670   425   170   170], ...
                'XTick', [], 'YTick', []);
            this.buildOpticalTemplate();
            this.buildPupilView();
            
            
            dCol1 = 30;
            dCol2 = 130;
            dCol3 = 230;
            dCol4 = 330;
            dCol5 = 430;
            dCol6 = 530;
            
            dYWid = 45;
            
            % build ZPpropagator:
            %             this.uiZPPropagator.build(this.hFigure, 500, 20);
            
            
            row = 0.5;
            
            % File
            this.uieZPName.build(this.hUIPanelFile, dCol1, row*dYWid, 270, 30);
            this.uibSave.build(this.hUIPanelFile, dCol3 + 100, row*dYWid + 10, 75, 40);
            this.uibLoad.build(this.hUIPanelFile, dCol4 + 100, row*dYWid + 10, 75, 40);
            this.uibOpenInFinder.build(this.hUIPanelFile, dCol5 + 100, row*dYWid + 10, 100, 40);
            
            % Optical
            row = 0.5; % ====
            dW = 70;
            this.uieLambda.build(this.hUIPanelOptical, dCol1, row*dYWid, 60, 30);
            this.uieEp.build(this.hUIPanelOptical, dCol1 + 1*dW, row*dYWid, 60, 30);
            this.uieNA.build(this.hUIPanelOptical, dCol1 + 2*dW, row*dYWid, 60, 30);
            this.uie4xNA.build(this.hUIPanelOptical, dCol1 + 3*dW, row*dYWid, 60, 30);
            this.uieDr.build(this.hUIPanelOptical, dCol1 + 4*dW, row*dYWid, 60, 30);
            
            this.uitTrueDrLabel.build(this.hUIPanelOptical, dCol1 + 5.5*dW, row*dYWid, 80, 30);
            this.uitTrueDr.build(this.hUIPanelOptical,  dCol1 + 5.5*dW, row*dYWid + 20, 60, 30);
            
            this.uitDLabel.build(this.hUIPanelOptical,  dCol1 + 6.5*dW, row*dYWid, 80, 30);
            this.uitD.build(this.hUIPanelOptical, dCol1 + 6.5*dW, row*dYWid + 20, 60, 30);
            
            this.uitNzLabel.build(this.hUIPanelOptical, dCol1 + 7.5*dW, row*dYWid, 100, 30);
            this.uitNz.build(this.hUIPanelOptical,  dCol1 + 7.5*dW, row*dYWid + 20, 60, 30);
            
            
            row = row + 1.5; % ====
            
            this.uieObscurationSigma.build(this.hUIPanelOptical, dCol1, row*dYWid, 60, 30);
            this.uieAnamorphicFac.build(this.hUIPanelOptical, dCol1 + 1*dW, row*dYWid, 60, 30);
            this.uieAnamorphicAzi.build(this.hUIPanelOptical, dCol1 + 2*dW, row*dYWid, 60, 30);
            
            this.uieZernikes.build(this.hUIPanelOptical, dCol1 + 3*dW, row*dYWid, 160, 30);
            
            this.uipCustomMask.build(this.hUIPanelOptical, dCol5, row*dYWid, 200, 30);
            
            
            
            
            
            
            
            row = row + 0.5; % ====
            
            
            row = row + 1; % ====
            dCol2_5 = dCol2 + 30;
            dCol3_2 = dCol3 + 10;
            this.uiePhat.build(this.hUIPanelOptical, dCol1, row*dYWid, 120, 30);
            this.uiePAngle.build(this.hUIPanelOptical, dCol2_5 , row*dYWid, 65, 30);
            this.uiePAzi.build(this.hUIPanelOptical, dCol3_2 , row*dYWid, 65, 30);
            
            this.uiePNorm.build(this.hUIPanelOptical, dCol4, row*dYWid, 75, 30);
            this.uieQ.build(this.hUIPanelOptical, dCol5, row*dYWid, 75, 30);
            this.uicbInfiniteConjugate.build(this.hUIPanelOptical, dCol6, row*dYWid + 10, 120, 30);
            
            
            
            
            row = row + 1; % ====
            this.uieKhat.build(this.hUIPanelOptical, dCol1, row*dYWid, 120, 30);
            this.uieKAngle.build(this.hUIPanelOptical, dCol2_5, row*dYWid, 65, 30);
            this.uieKAzi.build(this.hUIPanelOptical, dCol3_2 , row*dYWid, 65, 30);
            
            
            row = row + 1; % ====
            this.uieBeta1hat.build(this.hUIPanelOptical, dCol1, row*dYWid, 120, 30);
            this.uieBeta1Angle.build(this.hUIPanelOptical, dCol2_5, row*dYWid, 65, 30);
            this.uieBetaAzi.build(this.hUIPanelOptical, dCol3_2 , row*dYWid, 65, 30);
            
            row = row + 1; % ====
            this.uieBeta2hat.build(this.hUIPanelOptical, dCol1, row*dYWid, 120, 30);
            %             this.uieBeta2Angle.build(this.hUIPanelOptical, dCol2_5, row*dYWid, 65, 30);
            
            
            
            
            
            
            row = row + 1.5; % ====
            
            
            %             row = row + 1; % ====
            %             this.uieZPCR1.build(this.hUIPanelOptical, dCol2, row*dYWid, 75, 30);
            %             this.uieZPCR2.build(this.hUIPanelOptical, dCol3, row*dYWid, 75, 30);
            %             this.uieZPPhase.build(this.hUIPanelOptical, dCol4, row*dYWid, 75, 30);
            %
            
            % Pattern
            row = 0.5; % ====
            this.uieZoneTol.build(this.hUIPanelPattern, dCol1, row*dYWid, 75, 30);
            this.uieZoneBias.build(this.hUIPanelPattern, dCol2, row*dYWid, 75, 30);
            
            
            row = row + 1; % ====
            this.uipButtressIdx.build(this.hUIPanelPattern, dCol1, row*dYWid, 150, 30);
            this.uieButtressW.build(this.hUIPanelPattern, dCol3, row*dYWid, 75, 30);
            this.uieButtressT.build(this.hUIPanelPattern, dCol4, row*dYWid, 75, 30);
            
            
            row = row + 1; % ====
            this.uicbReverseTone.build(this.hUIPanelPattern, dCol1, row*dYWid + 10, 120, 30);
            
%             row = row + 1; % ====
%             this.uieBlockSize.build(this.hUIPanelPattern, dCol1, row*dYWid, 80, 30);
%             this.uieNumBlocks.build(this.hUIPanelPattern, dCol2, row*dYWid, 80, 30);
%             this.uieBlockGrid.build(this.hUIPanelPattern, dCol3, row*dYWid, 80, 30);
%             this.uieWRVBlockUnit.build(this.hUIPanelPattern, dCol4, row*dYWid, 80, 30);
            this.uicbRandomizeWRVZones.build(this.hUIPanelPattern, dCol2, row*dYWid + 10, 150, 30);
            
            row = row + 1; % ====
            this.uicbCenterOffaxisZP.build(this.hUIPanelPattern, dCol5, row*dYWid -5, 115, 30);
            
%             row = row + 1; % ====
            this.uieLayerNumber.build(this.hUIPanelPattern, dCol1, row*dYWid, 75, 30);
%             this.uipNWAPxSize.build(this.hUIPanelPattern, dCol2, row*dYWid + 10, 150, 30);
%             this.uicbOffsetTiltedZP.build(this.hUIPanelPattern, dCol5, row*dYWid -5, 115, 30);
            
            
            
            
            % Execute
            
            row = 1;
            this.uibStageAndGenerate.build(this.hUIPanelExecute, dCol1 , dYWid + 10 , 120, 40);
%             this.uipFileOutput.build(this.hUIPanelExecute, dCol1, dYWid, 200, 30);
%             this.uicbCompressFiles.build(this.hUIPanelExecute, dCol3 + 20, dYWid + 10, 180, 30);
%             this.uicbComputeExternally.build(this.hUIPanelExecute, dCol3 + 20, dYWid + 33, 180, 30);
%             
            
            row = row + 1; %====
            this.uibStageZP.build(this.hUIPanelExecute, dCol1 , row*dYWid + 10 , 100, 30);
            this.uibGenerate.build(this.hUIPanelExecute, dCol2, row*dYWid + 10 , 100, 30);
            
            row = row + 1; %====
            this.uieExecStr.build(this.hUIPanelExecute, dCol1, row*dYWid, 500, 160);
            
            row = row + 1; %====
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
        
        function out = makeArStr(this, str)
            d = eval(str);
            out = [];
            
            for k = 1:length(d)
                out = [out, sprintf('%0.6f ', d(k))];
            end
            
        end
        
        function out = makePString(this)
            d = eval(this.uiePhat.get()) * this.uiePNorm.get();
            out = [];
            
            for k = 1:length(d)
                out = [out, sprintf('%0.6f ', d(k))];
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
            sFileName = fullfile(this.cOutputFileDir, 'logs', sprintf('ZPLog_%s.csv', datestr(now, 29)));
            % check if file exists:
            if isempty(dir(sFileName)) % doesn't exist
                zpgen.writeLog(sFileName, this.ceHeaders, true);
            end
            zpgen.writeLog(sFileName, this.cLogStr, false, 'a');
            
            
            % Create a single log in ZPFiles
            sSingleLogFileName = fullfile(this.cOutputFileDir, 'ZPFiles', sprintf('ZPLog_%s_%s.csv', this.uieZPName.get(), datestr(now, 29)));
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
                sFilePath = fullfile(this.cOutputFileDir, 'ZPFiles', regexprep(this.uieZPName.get(), '\s', '_'));
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
                sPrefix =  fullfile(this.cZPGenDir, 'bin', 'ZPGenHolo');
                
                if isempty(this.cOutputFileDir)
                    sFilePath = fullfile(this.cZPGenDir, 'ZPFiles', regexprep(this.uieZPName.get(), '\s', '_'));
                else
                    sFilePath = fullfile(this.cOutputFileDir, 'ZPFiles', regexprep(this.uieZPName.get(), '\s', '_'));
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
            sParams = [sParams sprintf(' %s ', this.makePString())];
            
            % q (um)
            sParams = [sParams sprintf(' %0.4f ', this.uieQ.get())];
            
            % k
            sParams = [sParams sprintf(' %s ', this.makeArStr(this.uieKhat.get()))];
            
            % bx
            sParams = [sParams sprintf(' %s ', this.makeArStr(this.uieBeta1hat.get()))];
            
            % by
            sParams = [sParams sprintf(' %s ', this.makeArStr(this.uieBeta2hat.get()))];
            
            
            
            % obscuration sigma
            sParams = [sParams sprintf(' %0.4f ', this.uieObscurationSigma.get())];
            
            % NA
            sParams = [sParams sprintf(' %0.4f ', this.uieNA.get())];
            
            % zernike string
            sParams = [sParams this.makeZrnStr()];
            
            % custom Mask
            sParams = [sParams sprintf(' %d ', this.uipCustomMask.getSelectedIndex() - 1)];
            
            % Anamorphic factor
            sParams = [sParams sprintf(' %0.4f ', this.uieAnamorphicFac.get())];
            % Anamorphic Azimuth (deg)
            sParams = [sParams sprintf(' %0.4f ', -this.uieAnamorphicAzi.get()* pi/180)];
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
            % Randomize zones ([0]: no, 1:yes)
            sParams = [sParams sprintf(' %d ', this.uicbRandomizeWRVZones.get())];
            % Buttress idx (0: none, 1: gapped zones, 2: gaps)
            sParams = [sParams sprintf(' %d ', this.uipButtressIdx.getSelectedIndex() - 1)];
            % Buttress W (width in dr)
            sParams = [sParams sprintf(' %0.4f ', this.uieButtressW.get())];
            % Buttress T (period in dr)
            sParams = [sParams sprintf(' %0.4f ', this.uieButtressT.get())];
            %             % Center offaxis zone plate
            %             if (this.uicbCenterOffaxisZP.get())
            %                 sParams = [sParams sprintf(' %d ', 1)];
            %             elseif (this.uicbOffsetTiltedZP.get())
            %                 sParams = [sParams sprintf(' %d ', 2)];
            %             else
            %                 sParams = [sParams sprintf(' %d ', 0)];
            %             end
            % Blocksize [1e6]
            sParams = [sParams sprintf(' %d ', this.uieBlockSize.get())];
            % Multiple patterning, number of parts
            sParams = [sParams sprintf(' %d ', round(this.uieMultiplePatN.get()))];
            % Multiple patterning, index of parts
            sParams = [sParams sprintf(' %d ', round(this.uieMultiplePatIdx.get()))];
            
            % WRV Block grid (shapes will round to the grid specified here)
            sParams = [sParams sprintf(' %d ', round(this.uieBlockGrid.get()))];
            
            % Layer number OR num blocks on side (WRV multifield)
            if this.uipFileOutput.getSelectedIndex() == uint8(4)
                dVal = round(sqrt(this.uieNumBlocks.get()));
            else
                dVal = round(this.uieLayerNumber.get());
            end
            sParams = [sParams sprintf(' %d ', dVal)];
            
            
            % NWA pixel size or WRV pixel size
            if this.uipFileOutput.getSelectedIndex() == uint8(4) || this.uipFileOutput.getSelectedIndex() == uint8(5)
                sParams = [sParams sprintf(' %d ', this.uieWRVBlockUnit.get())];
            else
                sParams = [sParams sprintf(' %d ', this.uipNWAPxSize.getSelectedIndex() - 1)];
            end
            
            
            
            this.cExecStr = [sPrefix, sParams, sFilePath];
            if strcmp(this.arch, 'win64')
                this.cExecStr = [sPrefix, sParams, sFilePath]; %, ' & move ' sFilePath '.* src\ZPFiles'];
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

