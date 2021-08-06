$module_name = "rotate_files_functions"
$base= split-path $PSScriptroot
$module_path =  "$base/$module_name/$module_name.psm1"
write-output $module_path
import-module $module_path -force -verbose

Describe "public functions" {
    BeforeAll {
        # $dateMin = get-date -year 1980 -month 1 -day 1
        # $dateMax = get-date -year 2021 -month 1 -day 1
        function createFiles {
            $verbosepreference='continue'
            write-verbose ("testdrive: " + $TestDrive );
            for ($i = 0; $i -lt 4; $i++) {
                $fileName = "file" + $i + ".txt"
                $Path = join-path $TestDrive  $fileName
                New-Item -Path $Path  -ItemType File
                Get-Item $Path | % {$_.CreationTime = '01/11/2004 22:13:36'}
                write-verbose "creating $Path" 
            }
            for ($i = 0; $i -lt 4; $i++) {
                $fileName = "file" + $i + "v2" + ".txt"
                $Path = join-path $TestDrive  $fileName
                New-Item -Path $Path  -ItemType File
                Get-Item $Path | % {$_.CreationTime = '01/11/2006 22:13:36'}
                write-verbose "creating $Path" 
            }
        }
     

     

        write-verbose "done beforeall"
    }

    Context "local file system" {

        It "maximum age should be within the cutoff year" {
            #Check that the max age's year returned is equal to the passed year interval
            $maxAgeTest = Get-YearToCompare -intervalYear 2021
            # year of mock files
            $maxAgeTest.year | Should -Be '2021'
        }

        # It to test invalid year
        #todo: find the code to show that this should work but doesn't
        # It "negative year should be invalid" {
        #     Get-YearToCompare -intervalYear -1 | Should Throw -ExceptionType([System.ArgumentException]::New('invalid year provided'))
        # }

        # It statement to test grouping files by year
        It "mock files should be grouped by year" {
            createFiles
            # calling maxage function to get maximum date that the files can have
            $maxAgeTest = Get-YearToCompare -intervalYear 2021
            # grouping all files before 2021 (all files in test are 2004)
            $groupFilesTest = Group-FilesByYear -rootDir $testdrive -maxAge $maxAgeTest
            # $groupFiles.Name | Should Be 2004
            $2004Count = 0
            $2006Count = 0
            foreach ($yearlyGroup in $groupFilesTest) {
       
                $fileDate = $yearlyGroup.Name
                $yearOfFile = $fileDate
                if ($yearOfFile -eq 2004) {
                    $2004Count = $yearlyGroup.Name.length
                }
                if ($yearOfFile -eq 2006) {
                    $2006Count = $yearlyGroup.Name.length
                }
                
            }

            $2004Count | Should -Be 4 # file count of files made in 2004 is 4
            $2006Count | Should -Be 4 # file count of files made in 2006 is 4
        }

        # # It Statement to test making a new folder for a year that isn't archived yet and checking all the files are in it
        It "making new directory for new archive year" {
            
            # mock source directory for testing
            $sourceDirectory = $testdrive 
            $maxAgeTest = Get-YearToCompare -intervalYear 2021
            $groupFilesByYearTest = Group-FilesByYear -rootDir $sourceDirectory -maxAge $maxAgeTest
            
            # calling function to archive files by year
            Archive-Groups -filesByYear $groupFilesByYearTest -SourceFolder $sourceDirectory

            # check if new file path under 2004 exists
            for ($i = 0; $i -lt 4; $i++) {
                $fileName = "\2004\file" + $i + ".txt"
                $currPath = Join-Path $sourceDirectory $fileName
                write-host($currPath)
                Test-Path -Path $currPath | Should -Be $true 
            }

            # check if new file path under 2006 exists
            for ($i = 0; $i -lt 4; $i++) {
                $fileName = "\2006\file" + $i + "v2.txt"
                $currPath = Join-Path -path $sourceDirectory -ChildPath $fileName
                Test-Path -Path $currPath | Should -Be $true 
            }
        }
    }
}
