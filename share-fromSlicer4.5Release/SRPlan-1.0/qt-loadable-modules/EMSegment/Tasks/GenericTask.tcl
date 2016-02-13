package require Itcl

#########################################################
#
if {0} { ;# comment

    This function is executed by EMSegmenter

    # TODO :

}
#
#########################################################

#
# namespace procs
#

#
# This is the default processing pipeline - which does not do anything
#

namespace eval EMSegmenterPreProcessingTcl {

    #
    # Variables
    #

    ## Slicer
#    variable GUI
    variable SCENE

    ## EM GUI/MRML/LOGIC
    variable LOGIC

    variable preGUI
    variable mrmlManager
    variable workingDN


    ## Input/Output
    variable inputAtlasNode
    # Variables used for segmentation
    # Input/Output target specific scans - by default this is defined by the input scans which are aligned with each other
    variable alignedTargetNode
    # spatial priors aligned to target node
    variable outputAtlasNode

    variable ERROR_NODE_VTKID 0

    variable inputSubParcellationNode
    variable outputSubParcellationNode

    ## Task Specific GUI variables
    variable TextLabelSize 1
    variable CheckButtonSize 0
    variable VolumeMenuButtonSize 0
    variable TextEntrySize 0

    #
    # General Utility Functions
    #
    proc DeleteNode { NODE } {
        variable SCENE
        $SCENE RemoveNode $NODE
        # Note:
        #Do not need to do it as the destructor does it automatically
        #set displayNode [$NODE GetDisplayNode]
        #[$NODE GetDisplayNode]
        # if {$displayNode} { $SCENE RemoveNode $displayNode }
    }


    #------------------------------------------------------
    # returns filename when no error occurs
    proc CreateTemporaryFileNameForNode { Node {Ext ""} } {
#        variable GUI
        variable LOGIC

        set filename ""
        set NAME ""

        if { "$Ext" != "" } {
            set NAME "_[$Node GetID].$Ext"
        } elseif { [$Node GetClassName] == "vtkMRMLScalarVolumeNode" } {
            set NAME "_[$Node GetID].nrrd"
        } elseif { [$Node GetClassName] == "vtkMRMLLabelMapVolumeNode" } {
            set NAME "_[$Node GetID].nrrd"
        } elseif { [$Node GetClassName] == "vtkMRMLScene" } {
            set NAME "_[file tail [$Node GetURL]]"
        } else {
            #TODO,FIXME: need a elseif here
            # Transform node - check also for bspline
            set NAME "_[$Node GetID].h5"
        }

        if { $NAME != "" } {
            set filename [ $LOGIC mktemp_file $NAME ]
            $LOGIC PrintText "TCL: Create file: $filename"
        } else {
            PrintError "Could not create file: $basefilename$NAME"
        }

        return $filename
    }


    #
    proc CreateFileName { type } {
#        variable GUI
        variable LOGIC

        set filename ""
        set NAME ""

        if { $type == "Volume" } {
            set NAME .nrrd
        } elseif { $type == "LinearTransform"  } {
            set NAME .h5
        } elseif { $type == "BSplineTransform"  } {
            set NAME .h5
        } elseif { $type == "Text"  } {
            set NAME .txt
        } elseif { $type == "ITKDeformationField"  } {
            set NAME .mha
        }


        if { $NAME != "" } {
            set filename [ $LOGIC mktemp_file $NAME ]
            $LOGIC PrintText "TCL: Create file: $filename"
        } else {
            PrintError "Could not create file"
        }

        return $filename
    }

    #
    proc CreateDirName { type } {
        variable LOGIC

        set dirname [ $LOGIC mktemp_dir ".$type" ]
        return $dirname
    }

    proc CreateNewVolumeNodeAndAddToScene { name } {
        variable SCENE
        variable mrmlManager

        set newVolumeNode [vtkMRMLScalarVolumeNode New]
        $newVolumeNode SetName "$name"

        set newVolumeData [vtkImageData New]
        $newVolumeNode SetAndObserveImageData $newVolumeData
        $newVolumeData Delete

        set newDisplayNode [vtkMRMLScalarVolumeDisplayNode New]
        $SCENE AddNode $newDisplayNode
        set newDisplayNodeID [$newDisplayNode GetID]
        $newVolumeNode SetAndObserveDisplayNodeID $newDisplayNodeID
        $newDisplayNode Delete

        $SCENE AddNode $newVolumeNode
        set newVolumeNodeID [$newVolumeNode GetID]
        $newVolumeNode Delete
        return [$SCENE GetNodeByID $newVolumeNodeID]
    }

    proc PrintError { TEXT } {
        variable LOGIC
        $LOGIC PrintText "TCL: ERROR: EMSegmenterPreProcessingTcl::${TEXT}"
    }


    # update volumeCollectionNode with new volumes - and delete the old ones
    proc UpdateVolumeCollectionNode { volumeCollectionNode newVolumeCollectionNode } {
        variable LOGIC

        set inputNum [$volumeCollectionNode GetNumberOfVolumes]
        $LOGIC PrintText "TCL: $inputNum targetNodes detected"

        # replace each volume
        for { set i 0 } { $i < $inputNum } { incr i } {
            set newVolumeNode [lindex $newVolumeCollectionNode $i]
            if {$newVolumeNode == "" } {
                PrintError "Run: Processed target node is incomplete !"
                return 1
            }
            set oldVolumeNode [$volumeCollectionNode GetNthVolumeNode $i]

            # Set up the new ones
            $volumeCollectionNode SetNthVolumeNodeID $i [$newVolumeNode GetID]

            # Remove old volumes associated with volumeCollectionNode
            # if you delete right away then volumeCollectionNode is decrease
            DeleteNode $oldVolumeNode
        }
        return 0
    }

    # ----------------------------------------------------------------------------
    # We have to create this function so that we can run it in command line mode
    #
    proc GetCheckButtonValueFromMRML { ID } {
        return [GetEntryValueFromMRML "C" $ID]
    }

    proc GetVolumeMenuButtonValueFromMRML { ID } {
        variable mrmlManager
        set MRMLID [GetEntryValueFromMRML "V" $ID]
        if { ("$MRMLID" != "") && ("$MRMLID" != "NULL") } {
            return [$mrmlManager MapMRMLNodeIDToVTKNodeID $MRMLID]
        }
        return 0
    }

    proc GetTextEntryValueFromMRML { ID } {
        return [GetEntryValueFromMRML "E" $ID]
    }


    proc GetEntryValueFromMRML { Type ID } {
        variable mrmlManager
        variable LOGIC

        set SETTING  "[[$mrmlManager GetGlobalParametersNode] GetTaskPreProcessingSetting]"
        $LOGIC PrintText "TCL: GetEntryValueFromMRML: Input: - Type $Type - ID: $ID - Setting: $SETTING"
        set TEXT [string range [string map { ":" "\} \{" } "$SETTING"] 1 end ] 
        set TEXT "${TEXT}\}"
        $LOGIC PrintText "TCL: GetEntryValueFromMRML: Debug: $TEXT"
        set index 0
        foreach ARG $TEXT {
            if { "[string index $ARG 0]" == "$Type" } {
                if { $index == $ID } {
            set OUTPUT "[string range $ARG 1 end]" 
                    $LOGIC PrintText "TCL: GetEntryValueFromMRML: Output: $OUTPUT"
                    return "$OUTPUT"
                }
                incr index
            }
        }
        return ""
    }

    # Search for installation path 
    proc Get_Installation_Path { myfolder myfile } {
        variable LOGIC
        set REGISTRATION_PACKAGE_FOLDER ""
        # search for directories , sorted with the highest svn first
        set DIR [[$LOGIC GetSlicerCommonInterface] GetExtensionsDirectory]
       
        # Slicer Extension         
        set dirs [lsort -decreasing [glob -nocomplain -directory $DIR -type d * ] ]

        # allows user to define specific path independent from Slicer if you do not want to use extension system for pipeline but your own build
        # In Slicer 4 this directory will be ~/.config/EMSegmentCustom
        # now if you want to run a custom CMTK version just copy  the bin directory of CMTK (or create link)  to ~/.config/EMSegmentCustom/CMTK4Slicer
        set dirs "[file normalize [file join  $DIR ../EMSegmentCustom]] [file normalize [file join  $DIR ../../EMSegmentCustom]] $dirs"

        # search for directories , sorted with the highest svn first

        set folderFile [file join $myfolder $myfile ] 

        foreach dir $dirs {
            set filename [file join $dir $folderFile ] 
            if { [file exists $filename] } {
                set REGISTRATION_PACKAGE_FOLDER  [file join $dir $myfolder ] 
                $LOGIC PrintText "TCL: Found $filename"
                break
            }
        }

        if { "$REGISTRATION_PACKAGE_FOLDER" == "" } {
           $LOGIC PrintText "TCL: Warning: Could not find $folderFile in $dirs"
        }      
  
        return $REGISTRATION_PACKAGE_FOLDER
    }

    #
    # Preprocessing Functions
    #
    proc InitVariables { {initLOGIC ""} {initManager ""} {initPreGUI "" } } {
#        variable GUI
        variable preGUI
        variable LOGIC

        variable SCENE
        variable mrmlManager
        variable workingDN
        variable alignedTargetNode
        variable inputAtlasNode
        variable outputAtlasNode
        variable inputSubParcellationNode
        variable outputSubParcellationNode
        variable preferredRegistrationPackage
        variable selectedRegistrationPackage
        variable REGISTRATION_PACKAGE_FOLDER


        if {$initLOGIC == ""} {
            PrintError "ERROR: Logic not defined!"
            return 1
        } else {
            set LOGIC $initLOGIC
        }

#        set GUI $::slicer3::Application
#        if { $GUI == "" } {
#            puts stderr "ERROR: GenericTask: InitVariables: GUI not defined"
#            return 1
#        }
#
#        if { $initLOGIC == "" } {
#            set MOD [$GUI GetModuleGUIByName "EMSegmenter"]
#            if {$MOD == ""} {
#                puts stderr "ERROR: GenericTask: InitVariables: EMSegmenter not defined"
#                return 1
#            }
#            set LOGIC [$MOD GetLogic]
#            if { $LOGIC == "" } {
#                puts stderr "ERROR: GenericTask: InitVariables: LOGIC not defined"
#                return 1
#            }
#        } else {
#            set LOGIC $initLOGIC
#        }

        # Do not move it before bc LOGIC is not defined until here

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Init Variables"
        $LOGIC PrintText "TCL: =========================================="



        if { $initManager == "" } {
#            set MOD [$::slicer3::Application GetModuleGUIByName "EMSegmenter"]
#            if {$MOD == ""} {
#                PrintError "InitVariables: EMSegmenter not defined"
#                return 1
#            }
#
#           set mrmlManager [$MOD GetMRMLManager]

            set mrmlManager [$LOGIC GetMRMLManager]
            if { $mrmlManager == "" } {
                PrintError "InitVariables: mrmManager not defined"
                return 1
            }
        } else {
            set mrmlManager $initManager

        }

        set SCENE [$mrmlManager GetMRMLScene]
        if { $SCENE == "" } {
            PrintError "InitVariables: SCENE not defined"
            return 1
        }

        set workingDN [$mrmlManager GetWorkingDataNode]
        if { $workingDN == "" } {
            $LOGIC PrintText "TCL: EMSegmenterPreProcessingTcl::InitVariables: WorkingData not defined"
            return 1
        }

        if {$initPreGUI == "" } {
#            set MOD [$::slicer3::Application GetModuleGUIByName "EMSegmenter"]
#            if {$MOD == ""} {
#                PrintError "InitVariables: EMSegmenter not defined"
#                return 1
#            }
#
#            set preStep [$MOD GetPreProcessingStep]
#            if { $preStep == "" } {
#                PrintError "InitVariables: PreProcessingStep not defined"
#                return 1
#            }
#
#            set preGUI [$preStep GetCheckListFrame]
#            if { $preGUI == "" } {
#                PrintError "InitVariables:  CheckListFrame not defined"
#                return 1
#            }

             set preGUI [[$LOGIC GetSlicerCommonInterface] GetAdvancedDynamicFrame]

        } else {
            set preGUI $initPreGUI
        }

        if { [$mrmlManager GetRegistrationPackageType] == [$mrmlManager GetPackageTypeFromString CMTK] } {
            set preferredRegistrationPackage CMTK
            $LOGIC PrintText "TCL: User selected CMTK"
        } elseif { [$mrmlManager GetRegistrationPackageType] == [$mrmlManager GetPackageTypeFromString BRAINS] } {
            set preferredRegistrationPackage BRAINS
            $LOGIC PrintText "TCL: User selected BRAINS"
        } elseif { [$mrmlManager GetRegistrationPackageType] == [$mrmlManager GetPackageTypeFromString PLASTIMATCH] } {
            set preferredRegistrationPackage PLASTIMATCH
            $LOGIC PrintText "TCL: User selected PLASTIMATCH"
        } elseif { [$mrmlManager GetRegistrationPackageType] == [$mrmlManager GetPackageTypeFromString DEMONS] } {
            set preferredRegistrationPackage DEMONS
            $LOGIC PrintText "TCL: User selected DEMONS"
        } elseif { [$mrmlManager GetRegistrationPackageType] == [$mrmlManager GetPackageTypeFromString DRAMMS] } {
            set preferredRegistrationPackage DRAMMS
            $LOGIC PrintText "TCL: User selected DRAMMS"
        } elseif { [$mrmlManager GetRegistrationPackageType] == [$mrmlManager GetPackageTypeFromString ANTS] } {
            set preferredRegistrationPackage ANTS
            $LOGIC PrintText "TCL: User selected ANTS"
        } else {
            PrintError "InitVariables: RegistrationPackage [$mrmlManager GetRegistrationPackageType] not defined"
            return 1
        }

        #  This does not work under Slicer 4 $LOGIC SourceFileInTaskDirectory Registration_BRAINS.tcl
        source "[$LOGIC DefineTclFullPathName Registration_BRAINS.tcl]" 
       
        set selectedRegistrationPackage ""
        switch -exact "$preferredRegistrationPackage" {
            "BRAINS" {
                set selectedRegistrationPackage "BRAINS"
            }
            "CMTK" {
                source "[$LOGIC DefineTclFullPathName Registration_CMTK.tcl]"
                set REGISTRATION_PACKAGE_FOLDER [Get_CMTK_Installation_Path]
                if { $REGISTRATION_PACKAGE_FOLDER != "" } {
                    $LOGIC PrintText "TCL: Found CMTK in $REGISTRATION_PACKAGE_FOLDER"
                    set selectedRegistrationPackage "CMTK"
                } else {
                    $LOGIC PrintText "TCL: WARNING: Could not find CMTK, switch back to BRAINSTools"
                    set selectedRegistrationPackage "BRAINS"
                    # $LOGIC PrintText "enter something"
                    # gets stdin blub
                }
            }
            "PLASTIMATCH" {
                source "[$LOGIC DefineTclFullPathName Registration_plastimatch.tcl]"
                set REGISTRATION_PACKAGE_FOLDER [Get_Installation_Path "plastimatch-slicer" "plastimatch_slicer_bspline"]
                if { $REGISTRATION_PACKAGE_FOLDER != "" } {
                    $LOGIC PrintText "TCL: Found PLASTIMATCH in $REGISTRATION_PACKAGE_FOLDER"
                    set selectedRegistrationPackage "PLASTIMATCH"
                } else {
                    $LOGIC PrintText "TCL: WARNING: Could not find PLASTIMATCH, switch back to BRAINSTools"
                    set selectedRegistrationPackage "BRAINS"
                }
            }
            "DEMONS" {
                source "[$LOGIC DefineTclFullPathName Registration_DEMONS.tcl]"
                set REGISTRATION_PACKAGE_FOLDER [Get_DEMONS_Installation_Path]
                if { $REGISTRATION_PACKAGE_FOLDER != "" } {
                    $LOGIC PrintText "TCL: Found DEMONS in $REGISTRATION_PACKAGE_FOLDER"
                    set selectedRegistrationPackage "DEMONS"
                } else {
                    $LOGIC PrintText "TCL: WARNING: Couldn't find DEMONS, switch back to BRAINSTools"
                    set selectedRegistrationPackage "BRAINS"
                }
            }
            "DRAMMS" {
                source "[$LOGIC DefineTclFullPathName Registration_DRAMMS.tcl]"
                set REGISTRATION_PACKAGE_FOLDER [Get_DRAMMS_Installation_Path]
                if { $REGISTRATION_PACKAGE_FOLDER != "" } {
                    $LOGIC PrintText "TCL: Found DRAMMS in $REGISTRATION_PACKAGE_FOLDER"
                    set selectedRegistrationPackage "DRAMMS"
                } else {
                    $LOGIC PrintText "TCL: WARNING: Couldn't find DRAMMSS, switch back to BRAINSTools"
                    set selectedRegistrationPackage "BRAINS"
                }
            }
            "ANTS" {
        source "[$LOGIC DefineTclFullPathName Registration_ANTS.tcl]"
                set REGISTRATION_PACKAGE_FOLDER [Get_ANTS_Installation_Path]
                if { $REGISTRATION_PACKAGE_FOLDER != "" } {
                    $LOGIC PrintText "TCL: Found ANTS in $REGISTRATION_PACKAGE_FOLDER"
                    set selectedRegistrationPackage "ANTS"
                } else {
                    $LOGIC PrintText "TCL: WARNING: Couldn't find ANTS, switch back to BRAINSTools"
                    set selectedRegistrationPackage "BRAINS"
                }
            }
            default {
                PrintError "registration package not known"
                set selectedRegistrationPackage "BRAINS"
                return 1
            }
        }

        # All other Variables are defined when running the pipeline as they are the volumes
        # Define alignedTargetNode when initializing pipeline
        set alignedTargetNode ""
        set inputAtlasNode ""
        set outputAtlasNode ""
        set inputSubParcellationNode ""
        set outputSubParcellationNode ""

        return 0
    }



    #------------------------------------------------------
    # return 0 when no error occurs
    proc ShowUserInterface { {LOGIC ""} } {
        variable preGUI

        if { [InitVariables $LOGIC] } {
            puts stderr "ERROR: GenericTask.tcl: ShowUserInterface: Not all variables are correctly defined!"
            return 1
        }

        $LOGIC PrintText "TCL: Preprocessing GenericTask"

        # -------------------------------------
        # Define Interface Parameters
        # -------------------------------------
        $preGUI DefineTextLabel "No preprocessing defined for this task!" 0
    }

    # ----------------------------------------------------------------
    # Make Sure that input volumes all have the same resolution
    # from StartPreprocessingTargetToTargetRegistration
    # ----------------------------------------------------------------
    proc RegisterInputImages { inputTargetNode fixedTargetImageIndex } {
        variable workingDN
        variable mrmlManager
        variable LOGIC
        variable SCENE

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Register Input Images --"
        $LOGIC PrintText "TCL: =========================================="
        # ----------------------------------------------------------------
        # set up rigid registration
        set alignedTargetNode [$workingDN GetAlignedTargetNode]
        if { $alignedTargetNode == "" } {
            # input scan does not have to be aligned
            set alignedTargetNode [$mrmlManager CloneTargetNode $inputTargetNode "Aligned"]
            $workingDN SetReferenceAlignedTargetNodeID [$alignedTargetNode GetID]
        } else {
            $mrmlManager SynchronizeTargetNode $inputTargetNode $alignedTargetNode "Aligned"
        }

        for { set i 0 } { $i < [$alignedTargetNode GetNumberOfVolumes] } {incr i} {
            set intputVolumeNode($i) [$inputTargetNode GetNthVolumeNode $i]
            if { $intputVolumeNode($i) == "" } {
                PrintError "RegisterInputImages: the ${i}th input node is not defined!"
                return 1
            }

            set intputVolumeData($i) [$intputVolumeNode($i) GetImageData]
            if { $intputVolumeData($i) == "" } {
                PrintError "RegisterInputImages: the ${i}the input node has no image data defined !"
                return 1
            }

            set outputVolumeNode($i) [$alignedTargetNode GetNthVolumeNode $i]
            if { $outputVolumeNode($i) == "" } {
                PrintError "RegisterInputImages: the ${i}th aligned input node is not defined!"
                return 1
            }

            set outputVolumeData($i) [$outputVolumeNode($i) GetImageData]
            if { $outputVolumeData($i) == "" } {
                PrintError "RegisterInputImages: the ${i}the output node has no image data defined !"
                return 1
            }
        }
        set fixedVolumeNode $outputVolumeNode($fixedTargetImageIndex)
        set fixedImageData $outputVolumeData($fixedTargetImageIndex)


        # ----------------------------------------------------------------
        # perfom "rigid registration" or "resample and cast only"
        if {[$mrmlManager GetEnableTargetToTargetRegistration] } {

            $LOGIC PrintText "TCL: ===> Register Target To Target "

            for { set i 0 } {$i < [$alignedTargetNode GetNumberOfVolumes] } { incr i } {
                if { $i == $fixedTargetImageIndex } {
                    continue;
                }

                set movingVolumeNode $intputVolumeNode($i)
                set outVolumeNode $outputVolumeNode($i)
                set backgroundLevel [$LOGIC GuessRegistrationBackgroundLevel $movingVolumeNode]

                # Using BRAINS suite, TODO: is affine=off here?
                set tmpAffineType 2
                set tmpDeformableType 0
                set transformNode [BRAINSRegistration $fixedVolumeNode $movingVolumeNode $outVolumeNode $backgroundLevel $tmpAffineType $tmpDeformableType]
                if { $transformNode == "" } {
                    PrintError "Transform node is null"
                    return 1
                }
                # Not longer needed 
                DeleteNode $transformNode
            }
        } else {

            $LOGIC PrintText "TCL: ===> Skipping Registration of Target To Target "

            for { set i 0 } {$i < [$alignedTargetNode GetNumberOfVolumes] } { incr i } {
                if { $i == $fixedTargetImageIndex } {
                    continue;
                }

                set movingVolumeNode $intputVolumeNode($i)
                set outVolumeNode $outputVolumeNode($i)

                # Just creates output with same dimension as fixed volume
                $LOGIC StartPreprocessingResampleAndCastToTarget $movingVolumeNode $fixedVolumeNode $outVolumeNode
            }
        }

        # Clean up
        $workingDN SetAlignedTargetNodeIsValid 1

        return 0
    }

    # Create Voronoi diagram with correct scalar type from aligned subparcellation
    proc GeneratedVoronoi { input } {
        variable LOGIC
        $LOGIC PrintText "=== GeneratedVoronoi Start == " 

        set output [vtkImageData New]
        $output DeepCopy $input

        set voronoi [vtkImageLabelPropagation New]
        if {[$LOGIC GetVTKVersion] <= 5  } {
            $voronoi SetInput $output
        } else {
            $voronoi SetInputData $output
        }
        $voronoi Update
        set voronoiCast [vtkImageCast New]
        if {[$LOGIC GetVTKVersion] <= 5  } {
           $voronoiCast SetInput [$voronoi GetPropagatedMap]
        } else {
           $voronoiCast SetInputData [$voronoi GetPropagatedMap]
        }
        $voronoiCast SetOutputScalarType  [$output GetScalarType]
        $voronoiCast Update

        $input DeepCopy [$voronoiCast GetOutput]

        $voronoiCast Delete
        $voronoi Delete
        $output Delete

        $LOGIC PrintText "=== GeneratedVoronoi End == " 
    }

    #------------------------------------------------------
    # from StartPreprocessingTargetToTargetRegistration
    #------------------------------------------------------
    proc SkipAtlasRegistration { } {
        variable workingDN
        variable mrmlManager
        variable LOGIC
        variable alignedTargetNode
        variable inputAtlasNode
        variable outputAtlasNode
        variable inputSubParcellationNode
        variable outputSubParcellationNode
        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Skip Atlas Registration"
        $LOGIC PrintText "TCL: =========================================="

        # This function makes sure that the "output atlas" is identically to the "input atlas".
        # Each volume of the "output atlas" will then be resampled to the resolution of the "fixed target volume"
        # The "output atlas will be having the same ScalarType as the "fixed target volume'". There is no additionally cast necessary.

        set fixedTargetChannel 0

        # ----------------------------------------------------------------
        #  makes sure that the "output atlas" is identically to the "input atlas"
        # ----------------------------------------------------------------
        if { $outputAtlasNode == "" } {
            $LOGIC PrintText "TCL: Atlas was empty"
            #  $LOGIC PrintText "set outputAtlasNode \[$mrmlManager CloneAtlasNode $inputAtlasNode \"AlignedAtlas\"\] "
            set outputAtlasNode [$mrmlManager CloneAtlasNode $inputAtlasNode "Aligned"]
            $workingDN SetReferenceAlignedAtlasNodeID [$outputAtlasNode GetID]
        } else {
            $LOGIC PrintText "TCL: Atlas was just synchronized"
            $mrmlManager SynchronizeAtlasNode $inputAtlasNode $outputAtlasNode AlignedAtlas
        }

        if { $outputSubParcellationNode == "" } {
            $LOGIC PrintText "TCL: SubParcellation was empty"
            #  $LOGIC PrintText "set outputSubParcellationNode \[$mrmlManager CloneSubParcellationNode $inputSubParcellationNode \"AlignedSubParcellation\"\] "
            set outputSubParcellationNode [$mrmlManager CloneSubParcellationNode $inputSubParcellationNode "Aligned"]
            $workingDN SetReferenceAlignedSubParcellationNodeID [$outputSubParcellationNode GetID]
        } else {
            $LOGIC PrintText "TCL: SubParcellation was just synchronized"
            $mrmlManager SynchronizeSubParcellationNode $inputSubParcellationNode $outputSubParcellationNode AlignedSubParcellation
        }


        # ----------------------------------------------------------------
        # set the fixed target volume
        # ----------------------------------------------------------------
        set fixedTargetVolumeNode [$alignedTargetNode GetNthVolumeNode $fixedTargetChannel]
        if { [$fixedTargetVolumeNode GetImageData] == "" } {
            PrintError "SkipAtlasRegistration: Fixed image is null, skipping resampling"
            return 1;
        }


        # ----------------------------------------------------------------
        # Make Sure that atlas volumes all have the same resolution as input
        # ----------------------------------------------------------------
        for { set i 0 } {$i < [$outputAtlasNode GetNumberOfVolumes] } { incr i } {
            set movingVolumeNode [$inputAtlasNode GetNthVolumeNode $i]
            set outputVolumeNode [$outputAtlasNode GetNthVolumeNode $i]
            $LOGIC StartPreprocessingResampleAndCastToTarget $movingVolumeNode $fixedTargetVolumeNode $outputVolumeNode
        }

        for { set i 0 } {$i < [$outputSubParcellationNode GetNumberOfVolumes] } { incr i } {
            set movingVolumeNode [$inputSubParcellationNode GetNthVolumeNode $i]
            set outputVolumeNode [$outputSubParcellationNode GetNthVolumeNode $i]
            $LOGIC StartPreprocessingResampleAndCastToTarget $movingVolumeNode $fixedTargetVolumeNode $outputVolumeNode
            GeneratedVoronoi [$outputVolumeNode GetImageData]

        }


        $LOGIC PrintText "TCL: EMSEG: Atlas-to-target resampling complete."
        $workingDN SetAlignedAtlasNodeIsValid 1
        return 0
    }



    # -----------------------------------------------------------
    # sets up all variables
    # Define the three volume relates Input nodes to the pipeline
    # - alignedTargetNode
    # - inputAtlasNode
    # - outputAtasNode
    # -----------------------------------------------------------
    proc InitPreProcessing { } {
        variable mrmlManager
        variable LOGIC
        variable workingDN
        variable alignedTargetNode
        variable inputAtlasNode
        variable outputAtlasNode
        variable inputSubParcellationNode
        variable outputSubParcellationNode
        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == InitPreprocessing"
        $LOGIC PrintText "TCL: =========================================="

        # -----------------------------------------------------------
        # Check and set valid variables
        if { [$mrmlManager GetGlobalParametersNode] == 0 } {
            PrintError "InitPreProcessing: Global parameters node is null, aborting!"
            return 1
        }

        $LOGIC StartPreprocessingInitializeInputData


        # -----------------------------------------------------------
        # Define Target Node
        # this should be the first step for any preprocessing
        # from StartPreprocessingTargetToTargetRegistration
        # -----------------------------------------------------------

        set inputTargetNode [$workingDN GetInputTargetNode]
        if {$inputTargetNode == "" } {
            PrintError "InitPreProcessing: InputTargetNode not defined"
            return 1
        }

        set inputTargetPositiveCollectionNode [RemoveNegativeValues $inputTargetNode]
        if { $inputTargetPositiveCollectionNode == "" } {
            PrintError "Run: RemoveNegativeValues failed !"
            return 1
        }

        if { [UpdateVolumeCollectionNode $inputTargetNode "$inputTargetPositiveCollectionNode"] } {
            PrintError "UpdateVolumeCollectionNode failed !"
            return 1
        }


        if {[RegisterInputImages $inputTargetNode 0] } {
            PrintError "InitPreProcessing: Target-to-Target failed!"
            return 1
        }

        set alignedTargetNode [$workingDN GetAlignedTargetNode]
        if {$alignedTargetNode == "" } {
            PrintError "InitPreProcessing: cannot retrieve Aligned Target Node !"
            return 1
        }

        # -----------------------------------------------------------
        # Define Atlas
        # -----------------------------------------------------------
        set inputAtlasNode [$mrmlManager GetAtlasInputNode]
        if {$inputAtlasNode == "" } {
            PrintError "InitPreProcessing: InputAtlas not defined"
            return 1
        }

        set outputAtlasNode [$workingDN GetAlignedAtlasNode]

        set inputSubParcellationNode [$mrmlManager GetSubParcellationInputNode]
        if {$inputSubParcellationNode == "" } {
            PrintError "InitPreProcessing: InputSubParcellation not defined"
            return 1
        }

        set outputSubParcellationNode [$workingDN GetAlignedSubParcellationNode]



        return 0
    }



    proc calcDFVolumeNode { inputVolumeNode referenceVolumeNode transformationNode }   {
        variable LOGIC
        variable mrmlManager

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Create deformation field"
        $LOGIC PrintText "TCL: =========================================="

        # create a deformation field

        if { $transformationNode == "" } {
            PrintError "calcDFVolumeNode: transformation node not correctly defined"
            return ""
        }
        set tmpTransformFileName [WriteDataToTemporaryDir $transformationNode Transform]
        if { $tmpTransformFileName == "" } { return "" }

        # set tmpInputVolumeFileName [WriteImageDataToTemporaryDir $inputVolumeNode]
        # if { $tmpInputVolumeFileName == "" } { return "" }

        set tmpReferenceVolumeFileName [WriteImageDataToTemporaryDir $referenceVolumeNode]
        if { $tmpReferenceVolumeFileName == "" } { return "" }

        set DFNode [$mrmlManager CreateVolumeScalarNode $referenceVolumeNode "deformVolume"]
        set deformationFieldFilename [ CreateTemporaryFileNameForNode $DFNode vtk ]

        # Did not work 
        set CMDdeform "\"[$LOGIC GetPluginWithFullPath BRAINSTransformConvert]\""
        set CMDdeform "$CMDdeform --referenceVolume  \"$tmpReferenceVolumeFileName\""
        set CMDdeform "$CMDdeform --inputTransform  \"$tmpTransformFileName\""
        set CMDdeform "$CMDdeform --outputTransformType DisplacementField"  
        set CMDdeform "$CMDdeform --displacementVolume \"$deformationFieldFilename\""
       
        # Old STyle does not work anymore
        # set CMDdeform "\"[$LOGIC GetPluginWithFullPath BSplineToDeformationField]\""
        # set CMDdeform "$CMDdeform --refImage \"$tmpReferenceVolumeFileName\""
        # set CMDdeform "$CMDdeform --tfm \"$tmpTransformFileName\""
        # set CMDdeform "$CMDdeform --defImage \"$deformationFieldFilename\""

        $LOGIC PrintText "TCL: Executing $CMDdeform"
        if { [catch { eval exec $CMDdeform } errmsg] } {
           $LOGIC PrintText "TCL: ---- $errmsg ----"
           $LOGIC PrintText "Information about it: $::errorInfo"
           return ""
        }

        # clean up
        # file delete -force $tmpTransformFileName
        # file delete -force $tmpInputVolumeFileName
        # file delete -force $tmpReferenceVolumeFileName

        return $deformationFieldFilename
    }


    # ----------------------------------------------------------------------------
    # Precondition: All the inputchannels are already aligned
    #
    # This function registers the atlas to the input (both are non-skull stripped)
    # The transformation will then be applied to the known atlas ICC mask
    # The transformed mask will then be applied to the input
    #
    # The function returns a node with stripped input volumes
    proc SkullStripper { alignedInputNode tmpNonStrippedAtlasFileName atlas_mask_FileName } {
        variable SCENE
        variable LOGIC
        variable REGISTRATION_PACKAGE_FOLDER
        variable mrmlManager
        variable selectedRegistrationPackage

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == SkullStripper"
        $LOGIC PrintText "TCL: Type: $selectedRegistrationPackage"

        
        # initialize
        set alignedInputNode_SkullStripped ""

        # run the algorithm only on the first volume (index = 0)

        # This is the non-skull stripped input
        set inputVolumeNode [$alignedInputNode GetNthVolumeNode 0]
        set inputVolumeData [$inputVolumeNode GetImageData]
        if { $inputVolumeData == "" } {
            PrintError "SkullStripper: the 0th volume node has no input data defined!"
            return ""
        }
        set inputVolumeFileName [WriteDataToTemporaryDir $inputVolumeNode Volume]
        set RemoveFiles "\"$inputVolumeFileName\""
        if { $inputVolumeFileName == "" } {
            return ""
        }

        set deformed_atlas_mask_FileName [CreateFileName "Volume"]
        if { $deformed_atlas_mask_FileName == "" } {
            PrintError "it is empty"
        }

        set fixedVolumeFileName \"$inputVolumeFileName\"
        set movingVolumeFileName \"$tmpNonStrippedAtlasFileName\"

        set linearOutputVolumeFileName [CreateFileName "Volume"]
        if { $linearOutputVolumeFileName == "" } {
            PrintError "it is empty"
        }



        switch -exact "$selectedRegistrationPackage" {
            "CMTK" {

                set affineType 1

                ## CMTK specific arguments

                set CMD "$REGISTRATION_PACKAGE_FOLDER/registration"

                if { $affineType == [$mrmlManager GetRegistrationTypeFromString RegistrationTest] } {
                    set CMD "$CMD --dofs 0"
                } elseif { $affineType == [$mrmlManager GetRegistrationTypeFromString RegistrationFast] } {
                    set CMD "$CMD --accuracy 0.5 --initxlate --exploration 8.0 --dofs 6 --dofs 9"
                } elseif { $affineType == [$mrmlManager GetRegistrationTypeFromString RegistrationSlow] } {
                    set CMD "$CMD --accuracy 0.1 --initxlate --exploration 8.0 --dofs 6 --dofs 9"
                } else {
                    PrintError "SkullStripper: Unknown affineType: $affineType"
                    return ""
                }


                # affine
                set outLinearTransformDirName [CreateDirName "xform"]
                set outTransformDirName $outLinearTransformDirName

                set outVolumeFileName $linearOutputVolumeFileName

                set CMD "$CMD -o $outLinearTransformDirName"
                set CMD "$CMD --write-reformatted $outVolumeFileName"
                set CMD "$CMD $fixedVolumeFileName"
                set CMD "$CMD $movingVolumeFileName"


                ## execute affine registration

                $LOGIC PrintText "TCL: Executing $CMD"
                catch { eval exec $CMD } errmsg
                $LOGIC PrintText "TCL: $errmsg"

                #Resample

                set CMD "$REGISTRATION_PACKAGE_FOLDER/reformatx"

                set backgroundLevel 0
                set CMD "$CMD --pad-out $backgroundLevel"
                set CMD "$CMD --outfile $deformed_atlas_mask_FileName"
                set CMD "$CMD --floating $atlas_mask_FileName"

                # set the right scalar type
                set CMD "$CMD [CMTKGetPixelTypeFromVolumeNode $inputVolumeNode]"

                set CMD "$CMD $fixedVolumeFileName"
                set CMD "$CMD $outTransformDirName"

                $LOGIC PrintText "TCL: Executing $CMD"
                catch { eval exec $CMD } errmsg
                $LOGIC PrintText "TCL: $errmsg"

            }
            "BRAINS" {

                # LINEAR REGISTRATION


                set linearTransformFileName [CreateFileName "LinearTransform"]
                if { $linearTransformFileName == "" } {
                    PrintError "it is empty"
                }

                set CMD "\"[$LOGIC GetPluginWithFullPath BRAINSFit]\""
                set CMD "$CMD --fixedVolume $fixedVolumeFileName"
                set CMD "$CMD --movingVolume $movingVolumeFileName"
                set CMD "$CMD --outputVolume $linearOutputVolumeFileName"
                set CMD "$CMD --outputTransform $linearTransformFileName"
                set CMD "$CMD --initializeTransformMode useCenterOfHeadAlign"

                set deformableType [ $mrmlManager GetRegistrationDeformableType ]
                if { $deformableType == [$mrmlManager GetRegistrationTypeFromString RegistrationTest] } {
                      set CMD "$CMD --useRigid --numberOfIterations 3    --numberOfSamples 100"
                } elseif { $deformableType == [$mrmlManager GetRegistrationTypeFromString RegistrationFast] } {
                      set CMD "$CMD --useRigid --useScaleSkewVersor3D --useAffine"
                      set CMD "$CMD --numberOfIterations 500  --numberOfSamples 30000"
                } elseif { $deformableType == [$mrmlManager GetRegistrationTypeFromString RegistrationSlow] } {
                      set CMD "$CMD --useRigid --useScaleSkewVersor3D --useAffine"
                      set CMD "$CMD --numberOfIterations 1500 --numberOfSamples 300000"
                } elseif { $deformableType } {
                     # if it is 0 then equals off 
                     PrintError "BRAINSRegistration: Unknown deformableType: $deformableType"
                     return ""
                }

                # set CMD "$CMD --numberOfIterations 1500"
                # set CMD "$CMD --numberOfSamples 300000"
                set CMD "$CMD --minimumStepLength 0.005"
                set CMD "$CMD --translationScale 1000"
                set CMD "$CMD --reproportionScale 1"
                set CMD "$CMD --skewScale 1"
                set CMD "$CMD --maskProcessingMode NOMASK"
                set CMD "$CMD --numberOfHistogramBins 40"
                set CMD "$CMD --numberOfMatchPoints 10"
                set CMD "$CMD --costMetric MMI"


                $LOGIC PrintText "TCL: Executing $CMD"
                catch { eval exec $CMD } errmsg
                $LOGIC PrintText "TCL: $errmsg"



                # NON-LINEAR REGISTRATION

                set deformationfield [CreateFileName "Volume"]
                if { $deformationfield == "" } {
                    PrintError "it is empty"
                }

                set nonlinearOutputVolumeFileName [CreateFileName "Volume"]
                if { $nonlinearOutputVolumeFileName == "" } {
                    PrintError "it is empty"
                }


                set CMD "\"[$LOGIC GetPluginWithFullPath BRAINSDemonWarp]\""
                set CMD "$CMD -f $fixedVolumeFileName"
                set CMD "$CMD -m $movingVolumeFileName"
                set CMD "$CMD --initializeWithTransform $linearTransformFileName"
                set CMD "$CMD --outputVolume $nonlinearOutputVolumeFileName"
                set CMD "$CMD --outputDeformationFieldVolume $deformationfield"

                if { $deformableType == [$mrmlManager GetRegistrationTypeFromString RegistrationTest] } {
                   set CMD "$CMD -i 40,20,10,5,2"
        } else {
                   set CMD "$CMD -i 500,250,125,60,30"
        }
                set CMD "$CMD -n 5 -e --numberOfMatchPoints 16 --numberOfHistogramBins 1024"

                $LOGIC PrintText "TCL: Executing $CMD"
                catch { eval exec $CMD } errmsg
                $LOGIC PrintText "TCL: $errmsg"

                # WARP(=Resample) our mask

                set backgroundLevel 0
                set CMD "\"[$LOGIC GetPluginWithFullPath BRAINSResample]\""
                set CMD "$CMD --inputVolume $atlas_mask_FileName"
                set CMD "$CMD --referenceVolume $fixedVolumeFileName"
                set CMD "$CMD --deformationVolume $deformationfield"
                set CMD "$CMD --outputVolume $deformed_atlas_mask_FileName"
                set CMD "$CMD --defaultValue $backgroundLevel"
                set CMD "$CMD --pixelType [BRAINSGetPixelTypeFromVolumeNode $inputVolumeNode]"
                set CMD "$CMD --interpolationMode Linear"

                $LOGIC PrintText "TCL: Executing $CMD"
                catch { eval exec $CMD } errmsg
                $LOGIC PrintText "TCL: $errmsg"
            }
            default {
                PrintError "SkullStripper: registration package not known"
                return 1
            }
        }
        ##########

        # The input mask is now transformed, apply this transformed mask to the input.

        # Run the algorithm on each input volume
        for { set i 0 } { $i < [$alignedInputNode GetNumberOfVolumes] } { incr i } {


            # MASK input volume

            # This is the non-skull stripped input
            set inputVolumeNode [$alignedInputNode GetNthVolumeNode $i]
            set inputVolumeData [$inputVolumeNode GetImageData]
            if { $inputVolumeData == "" } {
                PrintError "SkullStripper: Cannot mask: the ${i}th volume node has no input data defined!"
                return ""
            }
            set inputVolumeFileName [WriteDataToTemporaryDir $inputVolumeNode Volume]
            set RemoveFiles "\"$inputVolumeFileName\""
            if { $inputVolumeFileName == "" } {
                return ""
            }

            set outputVolumeFileName [CreateFileName "Volume"]
            if { $outputVolumeFileName == "" } {
                PrintError "it is empty"
                return ""
            }

          if {[$LOGIC GetSlicerVersion] == 3  } {
              set CMD "\"[$LOGIC GetPluginWithFullPath Mask]\""
          } else {
              set CMD "\"[$LOGIC GetPluginWithFullPath MaskScalarVolume]\""
          }
            set CMD "$CMD --label 1 --replace 0 $inputVolumeFileName $deformed_atlas_mask_FileName $outputVolumeFileName"

            $LOGIC PrintText "TCL: Executing $CMD"
            catch { eval exec $CMD } errmsg
            $LOGIC PrintText "TCL: $errmsg"



            # create a new volume node for our output-list (function is adding the node to the scene)
            set outputVolumeNode [$mrmlManager CreateVolumeScalarNode $inputVolumeNode "[$inputVolumeNode GetName]_stripped"]

            # Read results back
            ReadDataFromDisk $outputVolumeNode $outputVolumeFileName Volume
            # file delete -force $outputVolumeFileName

            # still in for loop, create a list of Volumes
            set inputNode_SkullStripped "$alignedInputNode_SkullStripped $outputVolumeNode"
            $LOGIC PrintText "TCL: List of volume nodes: $inputNode_SkullStripped"
        }
        return "$inputNode_SkullStripped"
    }


    # comment: This function is using the fixed mode, is the dynamic mode possible?
    # Input:  target, directories(manual segmentation + original volumes)
    # Output: new probability atlas for each label already registered on template=target in outputDir
    proc AtlasCreator { _segmentationsDir _imagesDir _outputDir _labels _schedulerCommand targetNode } {
        variable SCENE
        variable LOGIC
        variable outputAtlasNode
        variable mrmlManager
        variable workingDN
        variable ERROR_NODE_VTKID

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == AtlasCreator"
        $LOGIC PrintText "TCL: =========================================="

        #variable SCENE
        #set SCENE [$::slicer3::Application GetMRMLScene]

        # Use only the first volume for the registration
        set targetVolumeNode [$targetNode GetNthVolumeNode 0]
        set targetVolumeFileName [WriteDataToTemporaryDir $targetVolumeNode Volume]
        if { $targetVolumeFileName == "" } { return 1 }

        set template         $targetVolumeFileName
        set outputDir        $_outputDir
        set segmentationsDir $_segmentationsDir
        set imagesDir        $_imagesDir
        set labels           $_labels
        set schedulerCommand $_schedulerCommand


        set skipRegistration 0
        set debug 0
        set dryrun 0

        if { $schedulerCommand == "" } {
            set cluster 0
        } else {
            set cluster 1
        }
        set transformsDir ""
        set existingTemplate ""
        set useCMTK 1
        set fixed 1
        set nonRigid 0

        set writeTransforms 0
        set keepAligned 1
        set normalize 0
        set normalizeTo 100
        set pca 0

        set referenceVolume [$targetVolumeNode GetImageData]
        set scalarType [$referenceVolume GetScalarTypeAsString]
        set outputCast $scalarType

        # we create a new vtkMRMLAtlasCreatorNode and configure it..
        set node [vtkMRMLAtlasCreatorNode New]
        $node InitializeByDefault

        #for more options look into Modules/AtlasCreator/Cxx/vtkMRMLAtlasCreatorNode.h

        # ignore the template per default
        $node SetIgnoreTemplateSegmentation 1

        if { $debug || $dryrun } {
            $node SetDebugMode 1
        }

        if { $dryrun } {
            $node SetDryrunMode 1
        }

        # set special settings if clusterMode or skipRegistrationMode is requested
        if { $cluster } {
            # cluster Mode
            $node SetUseCluster 1
            $node SetSchedulerCommand $schedulerCommand
        } elseif { $skipRegistration } {
            # skipRegistration Mode
            $node SetSkipRegistration 1
            $node SetTransformsDirectory $transformsDir
            $node SetExistingTemplate $existingTemplate
        }

        # now the configuration options which are valid for all
        if { $imagesDir != "" } {
        if  { [  catch {  set pathList [ glob -directory $imagesDir * ] } ] }  {
                $LOGIC PrintText "TCL: Warning : there were no files listed in '${imagesDir}' " 
        } else {
                $node SetOriginalImagesFilePathList  "$pathList"
        }
        }

        if { $segmentationsDir != "" } {
            if { [ catch { set pathList [ glob -directory $segmentationsDir * ]  } ] } {
                $LOGIC PrintText "TCL: Warning : there were no files listed in '${segmentationsDir}' " 
         } else {  
                $node SetSegmentationsFilePathList "$pathList"  
        }
         }

        if { $outputDir != "" } {
            $node SetOutputDirectory $outputDir
        }

        if { $useCMTK } {
            $node SetToolkit "CMTK"
        } else {
            $node SetToolkit "BRAINSFit"
        }
        $node SetUseDRAMMS 0


        if { $fixed } {
            $node SetTemplateType "fixed"
            $node SetFixedTemplateDefaultCaseFilePath $template
        } else {
            $node SetTemplateType "dynamic"
            $node SetDynamicTemplateIterations $meanIterations
        }

        $node SetLabelsList $labels

        if { $nonRigid } {
            $node SetRegistrationType "Non-Rigid"
        } else {
            $node SetRegistrationType "Affine"
        }

        if { $writeTransforms } {
            $node SetSaveTransforms 1
        } else {
            $node SetSaveTransforms 0
        }

        if { $keepAligned } {
            $node SetDeleteAlignedImages 0
            $node SetDeleteAlignedSegmentations 0
        } else {
            $node SetDeleteAlignedImages 1
            $node SetDeleteAlignedSegmentations 1
        }

        if { $normalize } {
            $node SetNormalizeAtlases 1
            $node SetNormalizeTo $normalizeTo
        } else {
            $node SetNormalizeAtlases 0
            $node SetNormalizeTo -1
        }

        if { $pca } {
            $node SetPCAAnalysis 1
        } else {
            $node SetPCAAnalysis 0
        }

        $node SetOutputCast $outputCast

        $LOGIC PrintText "TCL: == AtlasCreator Launch"

        # add the new node to the MRML scene
        #$SCENE AddNode $node
        #$node Launch
        $LOGIC RunAtlasCreator $node
        #the terminal will contain stdout output
        $node Print
        $node Delete
        $LOGIC PrintText "TCL: == AtlasCreator Finished"

        # Atlas creator returns a directory ($outputdir) with priors
        # create a empty atlasNode

        set inputAtlasNode [$mrmlManager GetAtlasInputNode]
        if { $inputAtlasNode == "" } {
            PrintError "AtlasCreator: No AtlasInput Node defined"
            return
        }
        $inputAtlasNode SetNumberOfTrainingSamples $normalizeTo

        set alignedAtlasNode [$mrmlManager GetAtlasAlignedNode]
        if { $alignedAtlasNode == "" } {
            set alignedAtlasNode [$mrmlManager CloneAtlasNode $inputAtlasNode "AtlasCreatorOutput"]
            $alignedAtlasNode SetNumberOfTrainingSamples $normalizeTo
            $workingDN SetReferenceAlignedAtlasNodeID [$alignedAtlasNode GetID]
        }

        $alignedAtlasNode RemoveAllNodes

        # loop through the $outputdir directory and add volume nodes to the scene
        # for each leaf in the tree set/replace the atlasnode by the ac atlas node
        # how to find the right atlas volume?
        return 0
    }


    proc UpdateAtlas { outputDir targetNode postfix } {
        variable SCENE
        variable LOGIC
        variable outputAtlasNode
        variable mrmlManager
        variable workingDN
        variable ERROR_NODE_VTKID

        set targetVolumeNode [$targetNode GetNthVolumeNode 0]
        set alignedAtlasNode [$mrmlManager GetAtlasAlignedNode]

        # Read a volume for each label
        foreach leafVTKID [GetAllLeafNodeIDsInTree] {

            set tmpIntensityLabel [$mrmlManager GetTreeNodeIntensityLabel $leafVTKID]
            set tmpName [$mrmlManager GetTreeNodeName $leafVTKID]
            set tmpNode [$mrmlManager GetTreeNode $leafVTKID]

            $LOGIC PrintText "TCL: $tmpName ($leafVTKID) has label $tmpIntensityLabel"

            # Check if node is defined - if not create a place holder
            set tmpSpatialPriorVTKID [$mrmlManager GetTreeNodeSpatialPriorVolumeID $leafVTKID]
            $LOGIC PrintText "TCL: tmpSpatialPriorVTKID: $tmpSpatialPriorVTKID"
            if { $tmpSpatialPriorVTKID == $ERROR_NODE_VTKID } {
                $LOGIC PrintText "TCL: Prior doesn't exists, create a place holder..."
                set tmpSpatialPriorVTKID [$mrmlManager CreateVolumeScalarNodeVolumeID $targetVolumeNode "atlas${tmpName}_Place Holder"]
                $mrmlManager SetTreeNodeSpatialPriorVolumeID $leafVTKID $tmpSpatialPriorVTKID
                $LOGIC PrintText "TCL: ...DONE"
            }

            # Always create atlas node
            $LOGIC PrintText "TCL: CreateVolumeScalarNodeVolumeID $targetVolumeNode atlas${tmpName}_AC"
            set alignedAtlasVolumeVTKID [$mrmlManager CreateVolumeScalarNodeVolumeID $targetVolumeNode "atlas${tmpName}_AC"]

            $LOGIC PrintText "TCL: SetAlignedSpatialPrior $leafVTKID $alignedAtlasVolumeVTKID"
            $mrmlManager SetAlignedSpatialPrior $leafVTKID $alignedAtlasVolumeVTKID

            $LOGIC PrintText "TCL: GetAlignedSpatialPriorFromTreeNodeID $leafVTKID"
            set alignedAtlasVolumeNode [$mrmlManager GetAlignedSpatialPriorFromTreeNodeID $leafVTKID]

            # for this particular label search for the corressponding atlas file
            $LOGIC PrintText "TCL: read in atlas file $outputDir/atlas$tmpIntensityLabel.nrrd"
            set alignedAtlasVolumeFileName $outputDir/atlas$tmpIntensityLabel$postfix.nrrd
            ReadDataFromDisk $alignedAtlasVolumeNode $alignedAtlasVolumeFileName Volume
            #file delete -force $alignedAtlasVolumeFileName

            $LOGIC PrintText "TCL: leafVTKID: $leafVTKID, atlasVolumeNodeID [$alignedAtlasVolumeNode GetID], atlasVolumeVTKID $alignedAtlasVolumeVTKID"
        }
        $LOGIC PrintText "DEBUG: $alignedAtlasNode [$SCENE GetNodeByID [$alignedAtlasNode GetID]] [$alignedAtlasNode GetID]"
        $LOGIC PrintText "TCL: GetInputTargetNode:  [[$mrmlManager GetWorkingDataNode] GetInputTargetNode]"
        $LOGIC PrintText "TCL: GetAlignedAtlasNode: [[$mrmlManager GetWorkingDataNode] GetAlignedAtlasNode]"
        $workingDN SetAlignedAtlasNodeIsValid 1

        return 0
    }



    proc WaitForDataToBeRead { } {
        variable LOGIC
        $LOGIC PrintText "TCL: Size of ReadDataQueue: $::slicer3::ApplicationLogic GetReadDataQueueSize [$::slicer3::ApplicationLogic GetReadDataQueueSize]"
        set i 20
        while { [$::slicer3::ApplicationLogic GetReadDataQueueSize] && $i} {
            $LOGIC PrintText "Waiting for data to be read... [$::slicer3::ApplicationLogic GetReadDataQueueSize]"
            incr i -1
            update
            after 1000
        }
        if { $i <= 0 } {
            $LOGIC PrintText "Error: timeout waiting for data to be read"
        }
    }

    proc DeleteCommandLine {clmNode } {
        variable LOGIC
        # Wait for jobs to finish
        set waiting 1
        set needToWait { "Idle" "Scheduled" "Running" }

        while {$waiting} {
            $LOGIC PrintText "TCL: Waiting for task..."
            set waiting 0
            set status [$clmNode GetStatusString]
            $LOGIC PrintText "[$clmNode GetName] $status"
            if { [lsearch $needToWait $status] != -1 } {
                set waiting 1
                after 250
            }
        }

        WaitForDataToBeRead
        $clmNode Delete
    }

    proc Run { } {
        variable LOGIC
        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Preprocess Data"
        $LOGIC PrintText "TCL: =========================================="
        if {[InitPreProcessing]} { return 1}
        # Simply sets the given atlas (inputAtlasNode) to the output atlas (outputAtlasNode)
        SkipAtlasRegistration
        # Remove Transformations
        variable LOGIC
        return 0
    }

    proc WriteDataToTemporaryDir { Node Type } {
        variable SCENE
        variable LOGIC


        set tmpName [CreateTemporaryFileNameForNode $Node]
        if { $tmpName == "" } { return "" }

        if { "$Type" == "Volume" } {
            set out [vtkMRMLVolumeArchetypeStorageNode New]
        } elseif { "$Type" == "Transform" } {
            set out [vtkMRMLTransformStorageNode New]
        } else {
            PrintError "WriteDataToTemporaryDir: Unkown type $Type"
            return ""
        }

        $out SetScene $SCENE
        $out SetFileName $tmpName
        if { [file exists $tmpName] && [file size $tmpName] == 0 } {
            # remove empty file immediately before we write into it.
            # file delete $tmpName
        } else {
            PrintError "tried to overwrite a non-empty existing file"
            return ""
        }
        set FLAG [$out WriteData $Node]
        $out Delete
        if { $FLAG == 0 } {
            PrintError "WriteDataToTemporaryDir: could not write file $tmpName"
            return ""
        }
        # $LOGIC PrintText "TCL: Write to temp directory:  $tmpName"

        return "$tmpName"
    }

    proc WriteImageDataToTemporaryDir { Node } {
        if { $Node == "" || [$Node GetImageData] == "" } {
            PrintError "WriteImageDataToTemporaryDir: volume node to be warped is not correctly defined"
            return ""
        }
        return  [WriteDataToTemporaryDir $Node Volume]
    }

    # Note that there is also 
    # vtkMRMLScalarVolumeNode*
    # vtkEMSegmentLogic::AddArchetypeScalarVolume(const char* filename, const char* volname, vtkSlicerApplicationLogic* appLogic, vtkMRMLScene* mrmlScene, bool centered) 
    # However - we can only use that if the nodes are not already created - which is not the case for us 
    proc ReadDataFromDisk { Node FileName Type } {
        variable SCENE
        variable LOGIC

        $LOGIC PrintText "TCL: ReadDataFromDisk: Try to read $FileName"
        if { [file exists $FileName] == 0 } {
            PrintError "ReadDataFromDisk: $FileName does not exist"
            return 0
        }
        $LOGIC PrintText "TCL: ReadDataFromDisk: File exists"  

        # Load a scalar or vector volume node
        # Need to maintain the original coordinate frame established by
        # the images sent to the execution model
        if { "$Type" == "Volume" } {
            set dataReader [vtkMRMLVolumeArchetypeStorageNode New]
            $dataReader SetCenterImage 0
        } elseif { "$Type" == "Transform" } {
            set dataReader [vtkMRMLTransformStorageNode New]
        } else {
            PrintError "ReadDataFromDisk: Unkown type $Type"
            return 0
        }

        $dataReader SetScene $SCENE
        $dataReader SetFileName "$FileName"

        set FLAG [$dataReader ReadData $Node]
        $dataReader Delete

        if { $FLAG == 0 } {
            PrintError "ReadDataFromDisk : could not read file $FileName"
            return 0
        }
        return 1
    }

   # This is how it should be done 
   proc ReadScalarVolumeFromDisk { Node FileName } { 
       variable LOGIC
       variable SCENE

       # not sure if this works for command line
       set readNode [$::slicer3::VolumesLogic AddArchetypeScalarVolume $FileName [$Node GetName]  0]
       # Could not make this work bc of link to scene 
       # set readNode[$LOGIC AddArchetypeScalarVolume $FileName [$Node GetName]  $::slicer3::ApplicationLogic $SCENE]

       if  { $readNode != "" } {
         $Node Copy $readNode
         # puts "uuuuu [$readNode GetName] [[$readNode GetImageData] GetScalarType]"
         DeleteNode $readNode
         return 1
       }

       PrintError "ReadScalarVolumeFromDisk: could not read file $FileName"
       return 0
   }


    proc CheckAndCorrectClassCovarianceMatrix {parentNodeID } {
        variable mrmlManager
        variable LOGIC
        set n [$mrmlManager GetTreeNodeNumberOfChildren $parentNodeID ]
        set failedList ""
        for {set i 0 } { $i < $n  } { incr i } {
            set id [ $mrmlManager GetTreeNodeChildNodeID $parentNodeID $i ]
            if { [ $mrmlManager GetTreeNodeIsLeaf $id ] } {
                if { [$mrmlManager IsTreeNodeDistributionLogCovarianceWithCorrectionInvertableAndSemiDefinite $id ] == 0 } {
                    # set the off diagonal to zeo
                    $LOGIC PrintText "TCL:CheckAndCorrectClassCovarianceMatrix: Set off diagonal of the LogCovariance of [ $mrmlManager GetTreeNodeName $id] to zero - otherwise matrix not convertable and semidefinite"
                    $mrmlManager SetTreeNodeDistributionLogCovarianceOffDiagonal $id  0
                    # if it still fails then add to list
                    if { [$mrmlManager IsTreeNodeDistributionLogCovarianceWithCorrectionInvertableAndSemiDefinite $id ] == 0 } {
                        set failedList "${failedList}$id "
                    }
                }
            } else {
                set failedList "${failedList}[CheckAndCorrectClassCovarianceMatrix $id]"
            }
        }
        return "$failedList"
    }


    proc CheckAndCorrectTreeCovarianceMatrix { } {
        variable mrmlManager
        set rootID [$mrmlManager GetTreeRootNodeID]
        return "[CheckAndCorrectClassCovarianceMatrix $rootID]"
    }

    proc Progress {args} {
        variable LOGIC
        $LOGIC PrintTextNoNewLine "."
    }

    proc wget { url  fileName } {
        package require http
        variable LOGIC
        $LOGIC  PrintTextNoNewLine "Loading $url "
        if { [ catch { set r [http::geturl $url -binary 1 -progress ::EMSegmenterPreProcessingTcl::Progress ] } errmsg ] }  {
            $LOGIC  PrintText " "
            PrintError "Could not download $url: $errmsg"
            return 1
        }

        set fo [open $fileName w]
        fconfigure $fo -translation binary
        puts -nonewline $fo [http::data $r]
        close $fo
        $LOGIC PrintText "\nSaving to $fileName\n"
        ::http::cleanup $r

        return 0
    }

    # returns 1 if error occured
    proc DownloadFileIfNeededAndSetURIToNULL { node origMRMLFileName forceFlag } {
        variable GUI
        variable LOGIC
        variable SCENE

        if { [$node GetClassName] != "vtkMRMLVolumeArchetypeStorageNode" } {
            PrintError "DownloadFileIfNeededAndSetURIToNULL: Wrong node type"
            return 1
        }

        # ONLY WORKS FOR AB
        set URI "[$node GetURI ]"
        $node SetURI ""

        if {$forceFlag == 0 } {
            set oldFileName [$node GetFileName]
            if { "$oldFileName" != "" } {
                # Turn it into absolute file if it is not already
                if { "[ file pathtype oldFileName ]" != "absolute" } {
                    set oldFileName "[file dirname $origMRMLFileName ]$oldFileName"
                }

                if { [file exists $oldFileName ] && [file isfile $oldFileName ] } {
                    # Must set it again bc path of scene might have changed so set it to absolute first
                    $node SetFileName $oldFileName
                    return 0
                }
            }
        }

        if {$URI == ""} {
            PrintError "DownloadFileIfNeededAndSetURIToNULL: File does not exist and URI is NULL"
            return 1
        }

        # Need to download file to temp directory

        set NAME "_[file tail $URI]"
        set filename [ $LOGIC mktemp_file $NAME]
   
        $LOGIC PrintText "DEBUG: Created file: $filename"


        if { [wget $URI $fileName] } {
            return 1
        }


        $node SetFileName $fileName
        return 0
    }

    proc ReplaceInSceneURINameWithFileName { mrmlFileName } {
        variable GUI
        variable LOGIC
        variable SCENE

        # Important so that it will write out all the nodes we are interested
        set mrmlScene [vtkMRMLScene New]
        set num [$SCENE GetNumberOfRegisteredNodeClasses]
        for { set i 0 } { $i < $num } { incr i } {
            set node [$SCENE GetNthRegisteredNodeClass $i]
            if { ($node != "" ) } {
                set name [$node GetClassName ]
                $mrmlScene RegisterNodeClass $node
            }
        }

        set parser [vtkMRMLParser New]
        $parser SetMRMLScene $mrmlScene
        $parser SetFileName $mrmlFileName

        if { [$parser Parse] } {
            set errorFlag 0
        } else {
            set errorFlag 1
        }
        $parser Delete

        if {$errorFlag == 0 } {
            # Download all the files if needed
            set TYPE "vtkMRMLVolumeArchetypeStorageNode"
            set n [$mrmlScene GetNumberOfNodesByClass $TYPE]

            for { set i 0 } { $i < $n } { incr i } {
                if { [DownloadFileIfNeededAndSetURIToNULL [$mrmlScene GetNthNodeByClass $i $TYPE] $mrmlFileName 0 ] } {
                    set errorFlag 1
                }
            }

            if { $errorFlag == 0 } {
                # Set the new path of mrmlScene - by first setting scene to old path so that the function afterwards cen extract the file name
                $mrmlScene SetURL $mrmlFileName
                set tmpFileName [CreateTemporaryFileNameForNode  $mrmlScene]
                $mrmlScene SetURL $tmpFileName
                $mrmlScene SetRootDirectory [file dirname $tmpFileName ]
                $mrmlScene Commit $tmpFileName
            }
        }
        $mrmlScene Delete

        if { $errorFlag } {
            return ""
        }

        $LOGIC PrintText "TCL: Wrote modified $mrmlFileName to $tmpFileName"

        return $tmpFileName
    }

    # -------------------------------------
    # Generate ICC Mask for input image
    # if succesfull returns ICC Mask Node
    # otherwise returns nothing
    # -------------------------------------
    proc GenerateICCMask { inputAtlasVolumeNode inputAtlasICCMaskNode targetVolumeNode } {
        variable LOGIC
        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Generate ICC MASK (not yet implemented)"
        $LOGIC PrintText "TCL: =========================================="
        

        # set CMD "DemonsRegistration --fixed_image $Scan2Image --moving_image $Scan1Image --output_image $Scan1ToScan2Image --output_field $Scan1ToScan2Deformation --num_levels 3 --num_iterations 20,20,20 --def_field_sigma 1 --use_histogram_matching --verbose"

        set CMD "\"[$LOGIC GetPluginWithFullPath DemonsRegistration]\" --fixed_image $Scan2Image --moving_image $Scan1Image --output_image $Scan1ToScan2Image --output_field $Scan1ToScan2Deformation --num_levels 3 --num_iterations 20,20,20 --def_field_sigma 1 --use_histogram_matching --verbose"

        return 1
    }

    proc RemoveNegativeValues { targetNode } {
        variable LOGIC
        variable SCENE
        variable mrmlManager

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Remove Negative Values "
        $LOGIC PrintText "TCL: =========================================="

        # initialize
        set result ""

        # Run the algorithm on each target image
        for { set i 0 } {$i < [$targetNode GetNumberOfVolumes] } { incr i } {
            # Define input
            set inputNode [$targetNode GetNthVolumeNode $i]
            if { $inputNode == "" } {
                PrintError "RemoveNegativeValues: the ${i}th target node is not defined!"
                foreach NODE $result { DeleteNode $NODE }
                return ""
            }

            if {[$LOGIC GetVTKVersion] <= 5  } {
                set input [$inputNode GetImageData]
            } else {
                set input [$inputNode GetImageDataConnection]
            }
            if { $input == "" } {
                PrintError "RemoveNegativeValues: the ${i}th target node has no input data defined!"
                foreach NODE $result { DeleteNode $NODE }
                return ""
            }

            $LOGIC PrintText "TCL: Start thresholding target image - start"

            # Define output
            set outputNode [$mrmlManager CreateVolumeScalarNode $inputNode "[$inputNode GetName]_pos"]

            # Thresholding
            set thresh [vtkImageThreshold New]
            if {[$LOGIC GetVTKVersion] <= 5  } {
                $thresh SetInput $input
            } else {
                $thresh SetInputConnection $input
            }

            # replace negative values
            $thresh ThresholdByLower 0
            $thresh SetReplaceIn 1
            $thresh SetInValue 0

            # keep positive values
            $thresh SetOutValue 0
            $thresh SetReplaceOut 0

            $thresh Update
            if {[$LOGIC GetVTKVersion] <= 5  } {
                set outputVolume [$outputNode GetImageData]
                $outputVolume DeepCopy [$thresh GetOutput]
            } else {
                set outputConnection [$thresh GetOutputPort]
                $outputNode SetImageDataConnection $outputConnection
            }
            $thresh Delete

            $LOGIC PrintText "TCL: Start thresholding target image - stop"

            # still in for loop, create a list of outputNodes
            set result "${result}$outputNode "
        }
        return $result
    }

    # -------------------------------------
    # Perform intensity correction
    # if succesfull returns a list of intensity corrected volume nodes
    # otherwise returns nothing
    #     ./Slicer3 --launch N4ITKBiasFieldCorrection --inputimage ../Slicer3/Testing/Data/Input/MRMeningioma0.nrrd --maskimage /projects/birn/fedorov/Meningioma_anonymized/Cases/Case02/Case02_Scan1ICC.nrrd corrected_image.nrrd recovered_bias_field.nrrd
    # -------------------------------------
    # targetICCMaskNode is currently ignored 
    proc PerformIntensityCorrection { inputNode targetICCMaskNode } {
        variable LOGIC
        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Intensity Correction "
        $LOGIC PrintText "TCL: =========================================="
 
        # initialize
        set correctedVolumeNodeList ""
        # Run the algorithm on each volume
        for { set i 0 } { $i < [$inputNode GetNumberOfVolumes] } { incr i } {
           set outputVolumeNode [$LOGIC PreprocessingBiasFieldCorrection [$inputNode GetNthVolumeNode $i] 0 ]
           set correctedVolumeNodeList "${correctedVolumeNodeList}$outputVolumeNode "
        }

        return "$correctedVolumeNodeList"
    }

    # -------------------------------------
    # Compute intensity distribution through auto sampling
    # if succesfull returns 0
    # otherwise returns 1
    # -------------------------------------
    proc ComputeIntensityDistributions { } {
        variable LOGIC

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Update Intensity Distribution "
        $LOGIC PrintText "TCL: =========================================="

        # return [$mrmlManager ComputeIntensityDistributionsFromSpatialPrior [$LOGIC GetModuleShareDirectory] [$preGUI GetApplication]]
        if { [$LOGIC ComputeIntensityDistributionsFromSpatialPrior ] } {
            return 1
        }
        return 0
    }



    # -------------------------------------
    # Register Atlas to Target
    # This function is changing/updating some nodes
    #
    # if succesfull returns 0
    # otherwise returns 1
    # -------------------------------------
    proc RegisterAtlas { alignFlag } {
        variable workingDN
        variable mrmlManager
        variable LOGIC
        variable alignedTargetNode
        variable inputAtlasNode
        variable outputAtlasNode
        variable inputSubParcellationNode
        variable outputSubParcellationNode
        variable selectedRegistrationPackage

        $LOGIC PrintText "TCL: =========================================="
        $LOGIC PrintText "TCL: == Register Atlas"
        $LOGIC PrintText "TCL: =========================================="


        set affineFlag [expr ([$mrmlManager GetRegistrationAffineType] != [$mrmlManager GetRegistrationTypeFromString RegistrationOff])]
        set bSplineFlag [expr ([$mrmlManager GetRegistrationDeformableType] != [$mrmlManager GetRegistrationTypeFromString RegistrationOff])]

        if {($alignFlag == 0) || (( $affineFlag == 0 ) && ( $bSplineFlag == 0 )) } {
            return [SkipAtlasRegistration]
        }

        $LOGIC PrintText "TCL: == ($affineFlag / $bSplineFlag) "
        $LOGIC PrintText "TCL: =========================================="


        # ----------------------------------------------------------------
        # Setup
        # ----------------------------------------------------------------
        if { $outputAtlasNode == "" } {
            $LOGIC PrintText "TCL: Aligned Atlas was empty"
            #  $LOGIC PrintText "TCL: set outputAtlasNode \[ $mrmlManager CloneAtlasNode $inputAtlasNode \"AlignedAtlas\"\] "
            set outputAtlasNode [ $mrmlManager CloneAtlasNode $inputAtlasNode "Aligned"]
            $workingDN SetReferenceAlignedAtlasNodeID [$outputAtlasNode GetID]
        } else {
            $LOGIC PrintText "TCL: Atlas was just synchronized"
            $mrmlManager SynchronizeAtlasNode $inputAtlasNode $outputAtlasNode "Aligned"
        }

        if { $outputSubParcellationNode == "" } {
            $LOGIC PrintText "TCL: Aligned SubParcellation was empty"
            #  $LOGIC PrintText "TCL: set outputSubParcellationNode \[ $mrmlManager CloneSubParcellationNode $inputSubParcellationNode \"AlignedSubParcellation\"\] "
            set outputSubParcellationNode [ $mrmlManager CloneSubParcellationNode $inputSubParcellationNode "Aligned"]
            $workingDN SetReferenceAlignedSubParcellationNodeID [$outputSubParcellationNode GetID]
        } else {
            $LOGIC PrintText "TCL: SubParcellation was just synchronized"
            $mrmlManager SynchronizeSubParcellationNode $inputSubParcellationNode $outputSubParcellationNode "Aligned"
        }

        # TODO, don't activate it per default
        set stripped 1

        if { $stripped == 0 } {
            set alignedTargetNode_SkullStripped [SkullStripperCLI $alignedTargetNode]
            UpdateVolumeCollectionNode "$alignedTargetNode" "$alignedTargetNode_SkullStripped"
        }


        set fixedTargetChannel 0
        set fixedTargetVolumeNode [$alignedTargetNode GetNthVolumeNode $fixedTargetChannel]

        if { [$fixedTargetVolumeNode GetImageData] == "" } {
            PrintError "RegisterAtlas: Fixed image is null, skipping registration"
            return 1
        }

        set atlasRegistrationVolumeIndex -1;
        if {[[$mrmlManager GetGlobalParametersNode] GetRegistrationAtlasVolumeKey] != "" } {
            set atlasRegistrationVolumeKey [[$mrmlManager GetGlobalParametersNode] GetRegistrationAtlasVolumeKey]
            set atlasRegistrationVolumeIndex [$inputAtlasNode GetIndexByKey $atlasRegistrationVolumeKey]
        }

        if {$atlasRegistrationVolumeIndex < 0 } {
            PrintError "RegisterAtlas: Attempt to register atlas image but no atlas image selected!"
            return 1
        }

        set movingAtlasVolumeNode [$inputAtlasNode GetNthVolumeNode $atlasRegistrationVolumeIndex]
        set movingAtlasImageData [$movingAtlasVolumeNode GetImageData]

        set outputAtlasVolumeNode [$outputAtlasNode GetNthVolumeNode $atlasRegistrationVolumeIndex]
        set outAtlasImageData [$outputAtlasVolumeNode GetImageData]

        if { $movingAtlasImageData == "" } {
            PrintError "RegisterAtlas: Moving image is null, skipping"
            return 1
        }

        if {$outAtlasImageData == "" } {
            PrintError "RegisterAtlas: Registration output is null, skipping"
            return 1
        }

        set affineType [ $mrmlManager GetRegistrationAffineType ]
        set deformableType [ $mrmlManager GetRegistrationDeformableType ]
        set interpolationType [ $mrmlManager GetRegistrationInterpolationType ]

        if { 0 } {
            set fixedRASToMovingRASTransformAffine [ vtkTransform New]
            set fixedRASToMovingRASTransformDeformable ""
        }

        $LOGIC PrintText "TCL: ========== Info ========="
        $LOGIC PrintText "TCL: = Fixed:   [$fixedTargetVolumeNode GetName] "
        $LOGIC PrintText "TCL: = Moving:  [$movingAtlasVolumeNode GetName] "
        $LOGIC PrintText "TCL: = Affine:  $affineType"
        $LOGIC PrintText "TCL: = BSpline: $deformableType"
        $LOGIC PrintText "TCL: = Interp:  $interpolationType"
        $LOGIC PrintText "TCL: ========================="

        # ----------------------------------------------------------------
        # registration
        # ----------------------------------------------------------------


        set backgroundLevel [$LOGIC GuessRegistrationBackgroundLevel $movingAtlasVolumeNode]
        set transformDirName ""
        set transformNode ""
        set BRAINStransformNode ""
        set transformNodeType ""



        switch -exact "$selectedRegistrationPackage" {
            "CMTK" {
                set transformDirName [CMTKRegistration $fixedTargetVolumeNode $movingAtlasVolumeNode $outputAtlasVolumeNode $backgroundLevel $deformableType $affineType]
                if { $transformDirName == "" } {
                    PrintError "RegisterAtlas: Transform node is null"
                    return 1
                }
                set transformNodeType "CMTKTransform"

                $LOGIC PrintText "TCL: Resampling atlas template in CMTKRegistration ..."
                # transformNode is not needed, it's value is ""
                if { [Resample $movingAtlasVolumeNode $fixedTargetVolumeNode $transformNode $transformDirName $transformNodeType Linear $backgroundLevel $outputAtlasVolumeNode] } {
                    PrintError "RegisterAtlas: Could not resample(reformatx) atlas template volume"
                    return 1
                }
            }
            "PLASTIMATCH" {
                set transformDirName [PLASTIMATCHRegistration $fixedTargetVolumeNode $movingAtlasVolumeNode $outputAtlasVolumeNode $backgroundLevel $deformableType $affineType]
                if { $transformDirName == "" } {
                    PrintError "ResgisterAtlas: Transform node is null"
                    return 1
                }
                set transformNodeType "PLASTIMATCHTransform"

                $LOGIC PrintText "TCL: Resampling atlas template in PLASTIMATCHRegistration ..."
                # transformNode is not needed, it's value is ""
                if { [Resample $movingAtlasVolumeNode $fixedTargetVolumeNode $transformNode $transformDirName $transformNodeType Linear $backgroundLevel $outputAtlasVolumeNode] } {
                    PrintError "RegisterAtlas: Could not resample atlas template volume"
                    return 1
                }
            }
            "DEMONS" {
                set transformDirName [DEMONSRegistration $fixedTargetVolumeNode $movingAtlasVolumeNode $outputAtlasVolumeNode $backgroundLevel $deformableType $affineType]
                if { $transformDirName == "" } {
                    PrintError "ResgisterAtlas: Transform node is null"
                    return 1
                }
                set transformNodeType "DEMONSTransform"

                $LOGIC PrintText "TCL: Resampling atlas template in DEMONSRegistration ..."
                # transformNode is not needed, it's value is ""
                if { [Resample $movingAtlasVolumeNode $fixedTargetVolumeNode $transformNode $transformDirName $transformNodeType Linear $backgroundLevel $outputAtlasVolumeNode] } {
                    PrintError "RegisterAtlas: Could not resample atlas template volume"
                    return 1
                }
            }
            "DRAMMS" {
                set transformDirName [DRAMMSRegistration $fixedTargetVolumeNode $movingAtlasVolumeNode $outputAtlasVolumeNode $backgroundLevel $deformableType $affineType]
                if { $transformDirName == "" } {
                    PrintError "ResgisterAtlas: Transform node is null"
                    return 1
                }
                set transformNodeType "DRAMMSTransform"

                $LOGIC PrintText "TCL: Resampling atlas template in DRAMMSRegistration ..."
                # transformNode is not needed, it's value is ""
                if { [Resample $movingAtlasVolumeNode $fixedTargetVolumeNode $transformNode $transformDirName $transformNodeType Linear $backgroundLevel $outputAtlasVolumeNode] } {
                    PrintError "RegisterAtlas: Could not resample atlas template volume"
                    return 1
                }
            }
            "ANTS" {
                set transformDirName [ANTSRegistration $fixedTargetVolumeNode $movingAtlasVolumeNode $outputAtlasVolumeNode $backgroundLevel $deformableType $affineType]
                if { $transformDirName == "" } {
                    PrintError "ResgisterAtlas: Transform node is null"
                    return 1
                }
                set transformNodeType "ANTSTransform"

                $LOGIC PrintText "TCL: Resampling atlas template in ANTSRegistration ..."
                # transformNode is not needed, it's value is ""
                if { [Resample $movingAtlasVolumeNode $fixedTargetVolumeNode $transformNode $transformDirName $transformNodeType Linear $backgroundLevel $outputAtlasVolumeNode] } {
                    PrintError "RegisterAtlas: Could not resample atlas template volume"
                    return 1
                }
            }
            "BRAINS" {
                # return value is a affine or bspline transformation node
                set BRAINStransformNode [BRAINSRegistration $fixedTargetVolumeNode $movingAtlasVolumeNode $outputAtlasVolumeNode $backgroundLevel $affineType $deformableType]
                if { $BRAINStransformNode == "" } {
                    PrintError "RegisterAtlas: BRAINStransformNode is null"
                    return 1
                }
                $LOGIC PrintText "TCL: RegisterAtlas: calcDFVolumeNode START"

                # calcDFVolumeNode does not work 
                #if { ($deformableType != 0) && ($affineType != 0) } {
                #   # BRAINStransformNode is a BSplineNode - here returns the location of a file 
                #   set transformNode [calcDFVolumeNode $movingAtlasVolumeNode $fixedTargetVolumeNode $BRAINStransformNode]
                #   set transformNodeType "DeformVolumeTransform"
                #} else {
                    # use slow method - transformNode is still a node ! 
                    set transformNode $BRAINStransformNode
                    set transformNodeType "BSplineTransform"
                #}
                $LOGIC PrintText "TCL: RegisterAtlas: calcDFVolumeNode DONE"
                if { $transformNode == "" } {
                    PrintError "RegisterAtlas: Deformation Field Transform node is null"
                    return 1
                }
            }
            default {
                PrintError "registration package not known"
                return 1
            }
        }


        # ----------------------------------------------------------------
        # resample
        # ----------------------------------------------------------------

        # Spatial prior
        for { set i 0 } { $i < [$outputAtlasNode GetNumberOfVolumes] } { incr i } {
            if { $i == $atlasRegistrationVolumeIndex} { continue }
            $LOGIC PrintText "TCL: Resampling atlas image $i ..."
            set movingVolumeNode [$inputAtlasNode GetNthVolumeNode $i]
            set outputVolumeNode [$outputAtlasNode GetNthVolumeNode $i]
            set backgroundLevel [$LOGIC GuessRegistrationBackgroundLevel $movingVolumeNode]
            $LOGIC PrintText "TCL: Guessed background level: $backgroundLevel"

            if { [Resample $movingVolumeNode $fixedTargetVolumeNode $transformNode $transformDirName $transformNodeType Linear $backgroundLevel $outputVolumeNode] } {
                return 1
            }
        }

        # Sub parcelation
        for { set i 0 } { $i < [$outputSubParcellationNode GetNumberOfVolumes] } { incr i } {
            $LOGIC PrintText "TCL: Resampling subparcallation map  $i ..."
            set movingVolumeNode [$inputSubParcellationNode GetNthVolumeNode $i]
            set outputVolumeNode [$outputSubParcellationNode GetNthVolumeNode $i]
            if { [Resample $movingVolumeNode  $fixedTargetVolumeNode  $transformNode "$transformDirName" $transformNodeType "NearestNeighbor" 0 $outputVolumeNode] } {
                return 1
            }

            # Create Voronoi diagram with correct scalar type from aligned subparcellation
            $LOGIC PrintText "TCL:  ============= [$movingVolumeNode GetName]"
            set tmpFileName [WriteImageDataToTemporaryDir $outputVolumeNode]
            $LOGIC PrintText "TCL:  Aligned Segmentation before voronoi $tmpFileName"
            # file rename $tmpFileName  ${tmpFileName}_before

            GeneratedVoronoi [$outputVolumeNode GetImageData]

            set blub [WriteImageDataToTemporaryDir $movingVolumeNode]
            $LOGIC PrintText "TCL:  Aligned Segmentation before voronoi $blub"
            set blub [WriteImageDataToTemporaryDir $outputVolumeNode]
            $LOGIC PrintText "TCL:  Aligned Segmentation after voronoi $blub"
        }

        # Remove TransformNode from scene as it is not needed anymore
        if { $BRAINStransformNode != "" } {
                DeleteNode $BRAINStransformNode
        }

        $LOGIC PrintText "TCL: Atlas-to-target registration complete."
        $workingDN SetAlignedAtlasNodeIsValid 1
        return 0
    }


    # output: outputVolumeNode
    # no side effects
    # interpolationType : NearestNeighbor|Linear|BSpline|WindowedSinc
    # in Addition for CMTK: PartialVolume, SincHamming
    proc Resample { inputVolumeNode referenceVolumeNode transformation_Node_or_FileName transformDirName transformType interpolationType backgroundLevel outputVolumeNode } {

        variable LOGIC
        if {[$inputVolumeNode GetImageData] == ""} {
            PrintError "Resample: Input image is null, skipping: $inputVolumeNode"
            return 1
        }
        if {[$outputVolumeNode GetImageData] == ""} {
            PrintError "Resample: Registration output is null, skipping: $outputVolumeNode"
            return 1
        }

        $LOGIC PrintText "TCL: Resampling image ..."

        switch $transformType {
            "CMTKTransform" {
                $LOGIC PrintText "TCL: with CMTKResampleCLI..."
                if { [CMTKResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformDirName $interpolationType $backgroundLevel] } {
                    return 1
                }
            }
            "PLASTIMATCHTransform" {
                $LOGIC PrintText "TCL: with PLASTIMATCHResampleCLI..."
                if { [PLASTIMATCHResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformDirName $interpolationType $backgroundLevel] } {
                    return 1
                }
            }
            "DRAMMSTransform" {
                $LOGIC PrintText "TCL: with DRAMMSResampleCLI..."
                if { [DRAMMSResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformDirName $interpolationType $backgroundLevel] } {
                    return 1
                }
            }
            "ANTSTransform" {
                $LOGIC PrintText "TCL: with ANTSResampleCLI..."
                if { [ANTSResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformDirName $interpolationType $backgroundLevel] } {
                    return 1
                }
            }
            "DEMONSTransform" {
                $LOGIC PrintText "TCL: with BRAINSResample using the Deformation Field"
                set BRAINSBSpline 0
                if { [BRAINSResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformDirName $backgroundLevel $interpolationType $BRAINSBSpline] } {
                    return 1
                }
            }
            "BSplineTransform" {
                $LOGIC PrintText "TCL: with BRAINSResample using the BSpline"
                set BRAINSBSpline 1
                if { [BRAINSResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformation_Node_or_FileName $backgroundLevel $interpolationType $BRAINSBSpline] } {
                    return 1
                }
            }
            "DeformVolumeTransform" {
                $LOGIC PrintText "TCL: with BRAINSResample using the Deformation Field"
                set BRAINSBSpline 0
                if { [BRAINSResampleCLI $inputVolumeNode $referenceVolumeNode $outputVolumeNode $transformation_Node_or_FileName $backgroundLevel $interpolationType $BRAINSBSpline] } {
                    return 1
                }
            }
            default {
                PrintError "Unknown transformType $transformType"
                return 1
            }
        }
        return 0
    }



    # Print error messages
    proc PrintError { TEXT } {
        variable LOGIC
        $LOGIC PrintText "TCL: ERROR: EMSegmenterPreProcessingTcl::${TEXT}"
    }

    proc GetAllLeafNodeIDsInTree { } {
        variable mrmlManager
        set rootID [$mrmlManager GetTreeRootNodeID]
        return "[GetAllLeafNodeIDs $rootID]"
    }

    proc GetAllLeafNodeIDs  {  parentNodeID } {
        variable mrmlManager
        set n [$mrmlManager GetTreeNodeNumberOfChildren $parentNodeID ]
        set LeafList ""
        for {set i 0 } { $i < $n  } { incr i } {
            set id [ $mrmlManager GetTreeNodeChildNodeID $parentNodeID $i ]
            if { [ $mrmlManager GetTreeNodeIsLeaf $id ] } {
                set LeafList "${LeafList} $id"
            } else {
                set LeafList "${LeafList} [GetAllLeafNodeIDs $id]"
            }
        }
        return "$LeafList"
    }
}

namespace eval EMSegmenterSimpleTcl {

    variable inputChannelGUI
    variable mrmlManager
    variable LOGIC

    proc InitVariables { {LOGIC ""} } {
        variable inputChannelGUI
        variable mrmlManager
#        if {$GUI == "" } {
#            set GUI [$::slicer3::Application GetModuleGUIByName EMSegmenter]
#        }
#        if { $GUI == "" } {
#            PrintError "InitVariables: GUI not defined"
#            return 1
#        }
#        set mrmlManager [$GUI GetMRMLManager]
#        if { $mrmlManager == "" } {
#            PrintError "InitVariables: mrmManager not defined"
#            return 1
#        }
#
#        set inputChannelStep [$GUI GetInputChannelStep]
#        if { $inputChannelStep == "" } {
#            PrintError "InitVariables: InputChannelStep not defined"
#            return 1
#        }
#        set inputChannelGUI [$inputChannelStep GetCheckListFrame]

        if {$LOGIC == ""} {
            PrintError "InitVariables: Logic not defined!"
            return 1
        }

        set mrmlManager [$LOGIC GetMRMLManager]
        if {$mrmlManager == "" } {
            PrintError "InitVariables: mrmlManager not defined!"
            return 1
        }
        
        set inputChannelGUI [[$LOGIC GetSlicerCommonInterface] GetSimpleDynamicFrame]        
        
        if { $inputChannelGUI == "" } {
            PrintError "InitVariables: Could not get dynamic frame"
            return 1
        }
        return 0
    }

    proc PrintError { TEXT } {
        puts stderr "TCL: ERROR:EMSegmenterSimpleTcl::${TEXT}"
    }

    # 0 = Do not create a check list for the simple user interface
    # simply remove
    # 1 = Create one - then also define ShowCheckList and
    #     ValidateCheckList where results of checklist are transfered to Preprocessing
    proc CreateCheckList { } { return 0 }
    proc ShowCheckList { } { return 0 }
    proc ValidateCheckList { } { return 0 }
}
