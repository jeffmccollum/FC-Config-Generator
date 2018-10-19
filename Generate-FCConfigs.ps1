<#
.SYNOPSIS

This script will generate FC configurations or reference configurations for Brocade and Cisco Switches. 
.DESCRIPTION

This script will take a Excel file that lists the specified Hosts, Array, Zoneset (zone Config) and VSAN and will create files for the configuration or as a reference configuration for A and B sides of the fabric. 
This script is opinionated in laying out the names of the aliases and zones, but the functions can be changed to suit your naming standards. 

There are some assumptions and requirements with this script. 
ImportExcel Module is installed. https://github.com/dfinke/ImportExcel
Fabrics are fully redundant and isolated
All hosts and arrays are dual attached
Zone names contain the host, the side, and the array port
All hosts connect to all array ports on their respective sides
Using Brocade or Cisco Switches

There are features that are still not in the script yet. 
Cisco reference configs
Multi target


.PARAMETER ImportFile
The Excel file to be imported

.PARAMETER SwitchType
The Type of Switch for the configs, Brocade and Cisco are supported

.PARAMETER TargetType
Single or Multi Target. Today only single is supported

.PARAMETER OutputType
Output config files that could be applied to a new switch, or output a reference config to validate proper FC zoning

.EXAMPLE
 .\Generate-FCConfigs.ps1 -ImportFile .\FCHosts.xlsx -SwitchType Cisco -TargetType Single -OutputType Config

 This will generate Cisco, Single Initiator - Single Target, config files

.EXAMPLE
 .\Generate-FCConfigs.ps1 -ImportFile .\FCHosts.xlsx -SwitchType Brocade -TargetType Single -OutputType Reference

 This will generate Brocade, Single Initiator - Single Target, reference files

#>

##############################################
#region Parameters
##############################################

Param(

    [Parameter(Position = 0,
        Mandatory = $true,
        HelpMessage = 'The config file to use')]
    [ValidateNotNullOrEmpty()]	
    [string]$ImportFile,

    [Parameter(Position = 1,
        Mandatory = $true,
        HelpMessage = 'What model of switch for the configs')]
    [ValidateSet("Cisco", "Brocade")]		
    [string]$SwitchType,

    [Parameter(Position = 2,
        Mandatory = $true,
        HelpMessage = 'Single Target or MultiTarget')]
    [ValidateSet("Single", "Multi")]		
    [string]$TargetType,
    
    [Parameter(Position = 3,
        Mandatory = $true,
        HelpMessage = 'Generate Config or Reference config')]
    [validateset("Config", "Reference")]
    [string]$OutputType
)

#endregion

##############################################
#region Functions
##############################################

function New-BrocadeAliasReference {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,

        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	

        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side
    )

    $FCAlias = @()
    foreach ($FCHost in $FChosts) {
        if ($Side -eq "A") {
            $FCAlias += "alias." + $FCHost.FCHost + "-A:" + $FCHost.AWWPN
        }
        else {
            $FCAlias += "alias." + $FCHost.FCHost + "-B:" + $FCHost.BWWPN
        }
    }

    foreach ($FCArray in $FCArray) {
        if ($Side -eq "A") {
            $FCAlias += "alias." + $FCArray.AName + ":" + $FCArray.AWWPN
        }
        else {
            $FCAlias += "alias." + $FCArray.BName + ":" + $FCArray.BWWPN
        }
    
    }
    return $FCAlias
}

function New-BrocadeZoneReference {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,
        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'Target Type')]
        [ValidateNotNullOrEmpty()]	
        $TargetType,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side
    )

    $FCZone = @()
    if ($TargetType -eq "Single") {
        foreach ($FCHost in $FCHosts) {
            foreach ($FCArray in $FCArray) {
                if ($Side -eq "A") {
                    $FCZone += "zone." + $FCHost.FCHost + "-A--" + $FCArray.AName + "`:" + $FCHost.FCHost + "-A;" + $FCArray.AName
                }
                else {
                    $FCZone += "zone." + $FCHost.FCHost + "-B--" + $FCArray.BName + "`:" + $FCHost.FCHost + "-B;" + $FCArray.BName
                }
            } 
        }
    }
    return $FCZone 
}

function New-BrocadeZoneSetReference {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,
        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'Target Type')]
        [ValidateNotNullOrEmpty()]	
        $TargetType,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side,
        [Parameter(Position = 4,
            Mandatory = $true,
            HelpMessage = 'ZoneSet Info')]
        [ValidateNotNullOrEmpty()]
        $ZoneSet

    )

    $FCZoneSet = @()
    if ($TargetType -eq "Single") {
        if ($Side -eq "A") {
            $FCZoneSet = "cfg." + $ZoneSet.AName + ":"
            
            foreach ($FCHost in $FCHosts) {
                foreach ($FCArray in $FCArray) {
                    $FCZoneSet += $FCHost.FCHost + "-A--" + $FCArray.AName + ";"
                } 
            } 
        }
        else {

            $FCZoneSet = "cfg." + $ZoneSet.BName + ":"
            
            foreach ($FCHost in $FCHosts) {
                foreach ($FCArray in $FCArray) {
                    $FCZoneSet += $FCHost.FCHost + "-A--" + $FCArray.AName + ";"
                } 
            } 

        }
        
    }
    else {
        
    }

    return $FCZoneSet 
}

function New-BrocadeAliasConfig {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,

        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side	
    )

    $FCAlias = @()
    foreach ($FCHost in $FChosts) {
        if ($Side -eq "A") {
            $FCAlias += "alicreate " + $FCHost.FCHost + "-A," + $FCHost.AWWPN
        } 
        else {
            $FCAlias += "alicreate " + $FCHost.FCHost + "-B," + $FCHost.BWWPN
        }
        
        
    }

    foreach ($FCArray in $FCArray) {
        if ($Side -eq "A") {
            $FCAlias += "alicreate " + $FCArray.AName + "," + $FCArray.AWWPN
        }
        else {
            $FCAlias += "alicreate " + $FCArray.BName + "," + $FCArray.BWWPN
        }
    }
    return $FCAlias
}

function New-BrocadeZoneConfig {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,
        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'Target Type')]
        [ValidateNotNullOrEmpty()]	
        $TargetType,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side	
    )

    $FCZone = @()
    if ($TargetType -eq "Single") {
        foreach ($FCHost in $FCHosts) {
            foreach ($FCArray in $FCArray) {
                if ($Side -eq "A") {
                    $FCZone += "zonecreate " + $FCHost.FCHost + "-A--" + $FCArray.AName + ",`"" + $FCHost.FCHost + "-A;" + $FCArray.AName + "`""
                }
                else {
                    $FCZone += "zonecreate " + $FCHost.FCHost + "-B--" + $FCArray.BName + ",`"" + $FCHost.FCHost + "-B;" + $FCArray.BName + "`""
                }
            } 
        }
    }

    return $FCZone 
}

function New-BrocadeZoneSetConfig {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,
        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'Target Type')]
        [ValidateNotNullOrEmpty()]	
        $TargetType,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side,
        [Parameter(Position = 4,
            Mandatory = $true,
            HelpMessage = 'ZoneSet Info')]
        [ValidateNotNullOrEmpty()]
        $ZoneSet

    )

    $FCZoneSet = @()
    if ($TargetType -eq "Single") {
        if ($Side -eq "A") {
            $FCZoneSet = "cfgcreate " + '"' + $ZoneSet.AName + '"' + "," + '"'
            
            foreach ($FCHost in $FCHosts) {
                foreach ($FCArray in $FCArray) {
                    $FCZoneSet += $FCHost.FCHost + "-A--" + $FCArray.AName + ";"
                } 
            } 
        }
        else {

            $FCZoneSet = "cfgcreate " + '"' + $ZoneSet.BName + '"' + "," + '"'
            
            foreach ($FCHost in $FCHosts) {
                foreach ($FCArray in $FCArray) {
                    $FCZoneSet += $FCHost.FCHost + "-B--" + $FCArray.BName + ";"
                } 
            } 
        }
        
    }
    else {
        
    }

    $FCZoneSet += '"'

    return $FCZoneSet 
}

function New-CiscoAliasConfig {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,

        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side	
    )

    $FCAlias = @()
    foreach ($FCHost in $FChosts) {
        if ($Side -eq "A") {
            $FCAlias += "device-alias name " + $FCHost.FCHost + "-A pwwn " + $FCHost.AWWPN
        } 
        else {
            $FCAlias += "device-alias name " + $FCHost.FCHost + "-B pwwn " + $FCHost.BWWPN
        }
        
        
    }

    foreach ($FCArray in $FCArray) {
        if ($Side -eq "A") {
            $FCAlias += "device-alias name " + $FCArray.AName + " pwwn " + $FCArray.AWWPN
        }
        else {
            $FCAlias += "device-alias name " + $FCArray.BName + " pwwn " + $FCArray.BWWPN
        }
    }
    return $FCAlias
}

function New-CiscoZoneConfig {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,
        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'Target Type')]
        [ValidateNotNullOrEmpty()]	
        $TargetType,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'The VSAN for the zone')]
        [ValidateNotNullOrEmpty()]
        $VSAN	
    )
    
    $FCZone = @()
    if ($TargetType -eq "Single") {
        foreach ($FCHost in $FCHosts) {
            foreach ($FCArray in $FCArray) {
                if ($Side -eq "A") {
                    $FCZone += "zone name " + $FCHost.FCHost + "-A--" + $FCArray.AName + " vsan " + $VSAN.AVSAN
                    $FCZone += "member device-alias " + $FCHost.FCHost + "-A"
                    $FCZone += "member device-alias " + $FCArray.AName
                }
                else {
                    $FCZone += "zone name " + $FCHost.FCHost + "-B--" + $FCArray.AName + " vsan " + $VSAN.BVSAN
                    $FCZone += "member device-alias " + $FCHost.FCHost + "-B"
                    $FCZone += "member device-alias " + $FCArray.BName
                }
            } 
        }
    }

    return $FCZone 
}

function New-CiscoZoneSetConfig {
    param
    (
        [Parameter(Position = 0,
            Mandatory = $true,
            HelpMessage = 'Hosts')]
        [ValidateNotNullOrEmpty()]	
        $FChosts,
        [Parameter(Position = 1,
            Mandatory = $true,
            HelpMessage = 'Array')]
        [ValidateNotNullOrEmpty()]	
        $FCArray,	
        [Parameter(Position = 2,
            Mandatory = $true,
            HelpMessage = 'Target Type')]
        [ValidateNotNullOrEmpty()]	
        $TargetType,
        [Parameter(Position = 3,
            Mandatory = $true,
            HelpMessage = 'A or B')]
        [ValidateSet("A", "B")]
        $Side,
        [Parameter(Position = 4,
            Mandatory = $true,
            HelpMessage = 'ZoneSet Info')]
        [ValidateNotNullOrEmpty()]
        $ZoneSet,
        [Parameter(Position = 5,
            Mandatory = $true,
            HelpMessage = 'The VSAN for the zone')]
        [ValidateNotNullOrEmpty()]
        $VSAN	
    )
    
    $FCZoneSet = @()
    if ($TargetType -eq "Single") {
        if ($Side -eq "A") {
            
            $FCZoneSet = "zoneset name " + $VSAN.AName + " vsan " + $VSAN.AVSAN + "`r`n"
            
            foreach ($FCHost in $FCHosts) {
                foreach ($FCArray in $FCArray) {
                    $FCZoneSet += "member " + $FCHost.FCHost + "-A--" + $FCArray.AName + "`r`n"
                } 
            } 
        }
        else {

            $FCZoneSet = "zoneset name " + $VSAN.BName + " vsan " + $VSAN.BVSAN + "`r`n"
            
            foreach ($FCHost in $FCHosts) {
                foreach ($FCArray in $FCArray) {
                    $FCZoneSet += "member " + $FCHost.FCHost + "-B--" + $FCArray.BName + "`r`n"
                } 
            } 
        }
        
    }
    else {
        
    }

    return $FCZoneSet 
}


#endregion

##############################################
#region Script
##############################################
#Requires –Modules ImportExcel

$Sheets = Get-ExcelSheetInfo -Path $ImportFile
	
foreach ($Sheet in $Sheets) {
    New-Variable -Name ("FCData" + $($Sheet.name)) -Value (Import-Excel -Path $ImportFile -WorkSheetname $($Sheet.name))
}


if ($SwitchType -eq "Brocade") { 

    if ($OutputType -eq "Config") {
        New-BrocadeAliasConfig -FChosts $FCDataHosts -FCArray $FCDataArray -Side A | out-file -FilePath "Output\Brocade FC Alias Config A.txt"
        New-BrocadeAliasConfig -FChosts $FCDataHosts -FCArray $FCDataArray -Side B | out-file -FilePath "Output\Brocade FC Alias Config B.txt"

        New-BrocadeZoneConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -Side A | out-file -FilePath "Output\Brocade FC Zone Config A.txt"
        New-BrocadeZoneConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -Side B | out-file -FilePath "Output\Brocade FC Zone Config B.txt"

        New-BrocadeZoneSetConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -ZoneSet $FCDataZoneSet -Side A | Out-File -FilePath "Output\Brocade FC Zone Set Config A.txt"
        New-BrocadeZoneSetConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -ZoneSet $FCDataZoneSet -Side B | Out-File -FilePath "Output\Brocade FC Zone Set Config B.txt"


    }
    else {

        New-BrocadeAliasReference -FChosts $FCDataHosts -FCArray $FCDataArray -Side A | out-file -FilePath "Output\Brocade FC Alias Reference A.txt"
        New-BrocadeAliasReference -FChosts $FCDataHosts -FCArray $FCDataArray -Side B | out-file -FilePath "Output\Brocade FC Alias Reference B.txt"
    
        New-BrocadeZoneReference -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -Side A | out-file -FilePath "Output\Brocade FC Zone Reference A.txt"
        New-BrocadeZoneReference -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -Side B | out-file -FilePath "Output\Brocade FC Zone Reference B.txt"
    
        New-BrocadeZoneSetReference -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -ZoneSet $FCDataZoneSet -Side A | Out-File -FilePath "Output\Brocade FC Zone Set Reference A.txt"
        New-BrocadeZoneSetReference -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -ZoneSet $FCDataZoneSet -Side B | Out-File -FilePath "Output\Brocade FC Zone Set Reference B.txt"

    }

}
else {

    if ($OutputType -eq "Config") {

        New-CiscoAliasConfig -FChosts $FCDataHosts -FCArray $FCDataArray -Side A | out-file -FilePath "Output\Cisco FC Alias Config A.txt"
        New-CiscoAliasConfig -FChosts $FCDataHosts -FCArray $FCDataArray -Side B | out-file -FilePath "Output\Cisco FC Alias Config B.txt"

        New-CiscoZoneConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -Side A -VSAN $FCdataVSAN | out-file -FilePath "Output\Cisco FC Zone Config A.txt"
        New-CiscoZoneConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -Side B -VSAN $FCdataVSAN | out-file -FilePath "Output\Cisco FC Zone Config B.txt"

        New-CiscoZoneSetConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -ZoneSet $FCDataZoneSet -VSAN $FCdataVSAN -Side A | Out-File -FilePath "Output\Cisco FC Zone Set Config A.txt"
        New-CiscoZoneSetConfig -FChosts $FCDataHosts -FCArray $FCDataArray -TargetType $TargetType -ZoneSet $FCDataZoneSet -VSAN $FCdataVSAN -Side B | Out-File -FilePath "Output\Cisco FC Zone Set Config B.txt"

    }
    else {
    
    }
}



Write-Output "configs have been generated."

##############################################
#endregion
##############################################
#end of script
