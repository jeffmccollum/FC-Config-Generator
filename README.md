# FC-Config-Generator

SYNOPSIS

This script will generate FC configurations or reference configurations for Brocade and Cisco Switches. 

DESCRIPTION

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

