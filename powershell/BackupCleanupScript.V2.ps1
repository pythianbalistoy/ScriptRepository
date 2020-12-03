param(
       [string]$debugmode = 'Y',
       [string]$storageAccount = 'uwsesqlbackups',
       [string]$storageKey = 'MI1K3owap4lq7rWAeYLHy5IvHgq5lSpoGh7P093s3fwCSQ8PAiU4tj2L4oZ4SRlQjtIsoy0QlfJdgbOODm02Zg==',
       [string]$blobContainer = 'backup-uw-se-sql-new',
       [string]$storageAssemblyPath = 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\Microsoft.WindowsAzure.Storage.dll',
       [int] $CleanupTime =  192, #192 hours = 8 days
       [String]$SQLInstance = 'UW-SE-SQL-01',
       [string]$servers= 'UW-SE-SQL-01,UW-SE-SQL-02'
)

$CleanupTime = $CleanupTime * -1
[datetime] $CleanupTime1 = [DateTime]::UtcNow.AddHours($CleanupTime)
$oldpreference = $VerbosePreference

if ($debugmode -eq 'Y')
{
  #Testing script in ISE have to change Verbose setting so Write-Verbose will output
  $VerbosePreference = 'continue'
}

Clear-Host

# use $CleanupTime = 0 as a default to test...
Write-Verbose "storageAccount: $($storageAccount)"
Write-Verbose "storageKey: $($storageKey)"
Write-Verbose "blobContainer: $($blobContainer)"
Write-Verbose "storageAssemblyPath: $($storageAssemblyPath)"
Write-Verbose "CleanupTime: $($CleanupTime)"
Write-Verbose "debugmode: $($debugmode)"

# Well known Restore Lease ID
$restoreLeaseId = "BAC2BAC2BAC2BAC2BAC2BAC2BAC2BAC2"

# Load the storage assembly without locking the file for the duration of the PowerShell session
$sqlServerSnapinVersion = (Get-Command Restore-SqlDatabase).ImplementingType.Assembly.GetName().Version.ToString()
$assemblySqlServerSmoExtendedFullName = "Microsoft.SqlServer.SmoExtended, Version=$sqlServerSnapinVersion, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
#[reflection.assembly]::LoadWithPartialName($assemblySqlServerSmoExtendedFullName) | out-null
$bytes = [System.IO.File]::ReadAllBytes($storageAssemblyPath)
[System.Reflection.Assembly]::Load($bytes) | Out-Null

$objServer =  new-object ('Microsoft.SqlServer.Management.Smo.Server') $SQLInstance
$Dblist = $objServer.Databases.Name  # | Where-Object {$_ -eq 'Avail' -or $_ -eq 'master'} ##filtered for testing
$cred = New-Object 'Microsoft.WindowsAzure.Storage.Auth.StorageCredentials' $storageAccount, $storageKey
$client = New-Object 'Microsoft.WindowsAzure.Storage.Blob.CloudBlobClient' "https://$storageAccount.blob.core.windows.net", $cred
$container = $client.GetContainerReference($blobContainer)
#list all the blobs 
$allBlobs = $container.ListBlobs($null, $false)

$servers = $servers.split("{,}")
$blobsfordelete = @()

#this section gets the full backups for each dbs in each server and adds all full backups older than the clean up time except 1 - the latest one, the the list of blobs to try and delete.
foreach ($db in $Dblist)
{$filteredBlobs= $AllBLobs | where-object {$_.uri -match $db} 
 $blob = $filteredBlobs.ListBlobs($false, [Microsoft.WindowsAzure.Storage.Blob.BlobListingDetails]::None, $null, $null)
 $blob1 = $blob.ListBlobs($false, [Microsoft.WindowsAzure.Storage.Blob.BlobListingDetails]::None, $null, $null)
 foreach($Server in $servers){
  $blob2 = $blob1 | where-object {$_.Name -like '*.bak' -and $_.name -match $server} | sort-object -property name -Descending |select-object name, Properties -skip 1
  foreach($blob3 in $blob2)
  {
  			$blob3Properties = $blob3.Properties
			if($blob3Properties.LastModified -lt $CleanupTime1 ) # only *.bak and *.trn files...
			
			{
				$blobsfordelete += $blob3

			}
  }

 }
}
#this section gets all transaction log backups older than the clean up time.

foreach($blob in $container.ListBlobs($null, $false))
{
	$blob1 = $blob.ListBlobs($false, [Microsoft.WindowsAzure.Storage.Blob.BlobListingDetails]::None, $null, $null)
	foreach($blob2 in $blob1)
	{
		$blob3 = $blob2.ListBlobs($false, [Microsoft.WindowsAzure.Storage.Blob.BlobListingDetails]::None, $null, $null)
		foreach($blob4 in $blob3)
		{
			$blob4Properties = $blob4.Properties
			if($blob4Properties.LastModified -lt $CleanupTime1 -and $blob4.Name -like "*.trn" # only *.trn files...
			)
			{
				$blobsfordelete += $blob4
			}			
		}
	}
	#$blob.ListBlobs($null, [Microsoft.WindowsAzure.Storage.Blob.BlobListingDetails]::All)
}

if ($blobsfordelete.Count -eq 0)
{ 
    Write-Output "There are no files to delete"
}

if($blobsfordelete.Count -gt 0)
{
    Write-Output "Starting to break lease and delete file..."
    foreach($blob in $blobsfordelete)
    {
        $blobProperties = $blob.Properties
        if($blobProperties.LeaseStatus -eq "Locked")
        {
          try
          {
              $blob.AcquireLease($null, $restoreLeaseId, $null, $null, $null) | Out-Null
              Write-Output "Breaking restore lease on: $($blob.name)"
              
              if ($debugmode -eq 'N')
              {
                $blob.BreakLease($(New-TimeSpan), $null, $null, $null) | Out-Null
              }
              Write-Output "Deleting file: $($blob.name)"
              if ($debugmode -eq 'N')
              {
                $blob.Delete();
                write-output $blob.Name
              }
          }
          catch [Microsoft.WindowsAzure.Storage.StorageException]
          {
              if($_.Exception.RequestInformation.HttpStatusCode -eq 409)
              {
                  Write-Warning "The lease on $($blob.name) is not a restore lease, skipping this file"
              }
          }
        }
        if($blobProperties.LeaseStatus -eq "Unlocked")
        {
          try
          {
              Write-Output "Deleting file: $($blob.name)"
              if ($debugmode -eq 'N')
              {
               # $blob.Delete();
               write-output $blob.Name
              }
          }
          catch [Microsoft.WindowsAzure.Storage.StorageException]
          {
              if($_.Exception.RequestInformation.HttpStatusCode -eq 409)
              {
                  Write-Warning "Error deleting file $($blob.name), skipping this file"
              }
          }
        }
    }
    Write-Output "Process completed"
}

