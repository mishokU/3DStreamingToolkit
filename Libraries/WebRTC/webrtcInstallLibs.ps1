Add-Type -AssemblyName System.IO.Compression.FileSystem

. ../../Utilities/InstallLibraries.ps1

function DecompressZip {
    param( [string] $filename, [string] $blobUri = "https://3dtoolkitstorage.blob.core.windows.net/libs/" )
    
    # Get ETag header for current blob
    $uri = ($blobUri + $filename + ".zip")
    $etag = Get-ETag -Uri $uri
    $localFullPath = ($PSScriptRoot + "\" + $filename + ".zip")
    
    # Compare ETag against the currently installed version
    $versionMatch = Compare-Version -Path $localFullPath -Version $etag
    if (!$versionMatch) {

        $extractDir = ""

        if($filename -like "*x64*") {
            $extractDir = "\x64"
        } 
        if($filename -like "*Win32*") {
            $extractDir = "\Win32"
        }
        if($filename -like "*headers*") {
            $extractDir = "\headers"
        }
        if($extractDir -eq "") {
            return
        }

        # Remove library archive if it already exists
        if ((Test-Path ($localFullPath))) {
            Remove-Item -Recurse -Force $localFullPath
        }

        # Download the library
        Write-Host "Downloading $filename from $uri"
        Copy-File -SourcePath $uri -DestinationPath $localFullPath
        Write-Host ("Downloaded " + $filename + " lib archive")

        # Clear the files from the previous library version
        if((Test-Path ($PSScriptRoot + $extractDir)) -eq $true) {
            Write-Host "Clearing existing $extractDir" 
            Remove-Item -Recurse -Force ($PSScriptRoot + $extractDir)
        }

        # Extract the latest library
        Write-Host "Extracting..."
        # ExtractToDirectory is at least 3x faster than Expand-Archive
        [System.IO.Compression.ZipFile]::ExtractToDirectory($localFullPath, $PSScriptRoot)
        Write-Host "Finished"

        # Clean up .zip file
        Remove-Item $localFullPath

        # Write the current version using the ETag
        Write-Version -Path $localFullPath -Version $etag
    }
}

DecompressZip -filename "m62patch_nvpipe_headers"
DecompressZip -filename "m62patch_nvpipe_x64"
DecompressZip -filename "m62patch_nvpipe_Win32"
