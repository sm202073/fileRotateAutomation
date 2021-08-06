<#
.SYNOPSIS
Maps the target sharepoint site where files need to be archived into a local mapped drive. 
.DESCRIPTION
Map-SharepointDrive is a function in the rotate files module that takes a Sharepoint directory or site and maps it locally into 
the current in-use computer so the files in the Sharepoint directory can be accessed by the other module functions.  
.EXAMPLE
Map-SharepointDrive -mapPath -"\\sp.com\sites\Shared Documents"
#>
function Map-SharepointDrive { 
    [CmdletBinding()] 
    param(
        [Parameter(Mandatory, HelpMessage="Sharepoint Directory")][String]$mapPath
    )
    net use R: $mapPath
    Set-Location R:\ #cds into the location of the R drive that mapped Sharepoint directory
}

<#
.SYNOPSIS
Calculates the highest possible file age that be archived from the directory or site given a cutoff year. 
.DESCRIPTION
Get-YearToCompare is a function in the rotate files module that takes in a cutoff year and computes the 
largest possible age of files that should archived (the current date and time on the cutoff year passed in as a parameter), 
acting as a cutoff date for archival and rotation.  
.EXAMPLE
Get-YearToCompare -intervalYear -2020
(returns today's date and time in 2020 which is a cutoff for files that need to be archived with a cutoff year of 2020)
#>
function Get-YearToCompare {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="Cutoff year/time interval for rotation")][int]$intervalYear
    )

    # throw an exception for invalid cutoff year, negative year
    if ( $intervalYear -lt 0 ) {
        # throw "negative year is not allowed"
        throw [System.ArgumentException]::New('year provided is invalid')
    }

    $Today = Get-Date
    $Year = $intervalYear
    $differenceYear = (Get-Date).year - $Year
    $maxAge = $Today.AddYears(-1*$differenceYear)
    return $maxAge

}
    
<#
.SYNOPSIS
Groups all files less than the maximum age for archival by year of creation.
.DESCRIPTION
Group-FilesByYear is a function in the file rotate module that groups files into 
group object categorized by year of creation given the maximum age the files can be to be grouped and
archived and the original source directory link and/or path. 
.EXAMPLE
Group-FilesByYear -RootDir -"C:\Users\username\Desktop\RootFiles" -maxAge "Monday, July 13, 2020 11:18:23 AM"
.EXAMPLE
Group-FilesByYear -RootDir -"\\sp.ameren.com\sites\InfraAutomation\Shared Documents" -maxAge "Monday, July 13, 2020 11:18:23 AM"
#>
function Group-FilesByYear {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="Original folder from which files need to be archived, Sharepoint Drive")][String]$RootDir,
        [Parameter(Mandatory, HelpMessage="Maximum age of the file before it's archived, returned from calculate year function")][DateTime]$maxAge
    )

    #Get all files that need to be archived by creating a group-object that is grouped by year of creationDate
    $filesByYear = Get-ChildItem -Path $RootDir -Recurse -File |`
    Where-Object CreationTime -LT $maxAge |`
        Group-Object { $_.CreationTime.ToString("yyyy") }
   
    return $filesByYear
   
}

 
<#
.SYNOPSIS
Moves files in the root target directory grouped by year into folders by year to archive them.
.DESCRIPTION
Archive-Groups is a function in the file rotate module that takes in a Group Object with files grouped by year from the Group-FilesByYear function in the 
same module and makes subdirectories named by year and moves the files to be archived into the respective
directories with matching years. If a folder named by a certain year already exists, files are moved into that directory
and new one is not created. 
.EXAMPLE
Archive-Groups -FilesByYear (Group-FilesByYear -RootDir "C:\Users\username\Desktop\RootFiles" -maxAge "Monday, July 13, 2020 11:18:23 AM") -SourceFolder -"C:\Users\username\Desktop\RootFiles" 
#>    
function Archive-Groups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage="Files grouped by year, returned by Group-Files-By-Year function")][System.Object]$FilesByYear,
        [Parameter(Mandatory, HelpMessage="Source directory to make yearly groups")][String]$SourceFolder
    )
      #parsing through all of the files and moving it into the archive folder
      foreach ($yearlyGroup in $FilesByYear) {
       
        #retrieves the year of each group of files
        $fileDate = $yearlyGroup.Name
        $yearOfFile = $fileDate

        #Creates the folder archive path that will be checked when parsing thru the folders
        $Directory = $SourceFolder + "\" + $yearOfFile

        if (!(Test-Path -Path $Directory)) {
            #Path does not exist
            $newDestinationFolder = New-Item -Path $Directory -ItemType Directory
            $yearlyGroup.Group | Move-Item -Destination $newDestinationFolder
        } else {
            #Path exists
            $yearlyGroup.Group | Move-Item -Destination $Directory
        }
    
    }
}


<#
.SYNOPSIS
Outermost function that calls all the module functions and pipelines them to complete the file
rotate and archival process.
.DESCRIPTION
Rotate-Files is a function in the file rotate module that calls all the other functions in the module
in sequential order with pipelineable parameters to rotate and archive all files in a given source directory or
Sharepoint site before a specified cutoff year. Takes and reads in user input to determine root directory location
and archival cutoff year.
.EXAMPLE
Rotate-Files
(use the console to input Sharepoint link and/or local directory path and )
#> 
function Rotate-Files {
#Calling functions in order to complete the file rotation for shared documents in sharepoint

    $base = Read-Host -Prompt 'Input your sharepoint url without the http:'
    $x = Read-Host -Prompt 'Input the exact directory you want to take archive'

    Group-FilesByYear -RootDir $x -maxAge (Map-SharepointDrive -mapPath $base) |`
    Archive-Groups  -SourceFolder $x 
}
# rotate-files
