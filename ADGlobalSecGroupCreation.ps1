# Import the Active Directory module
Import-Module ActiveDirectory

# Set the path to the Montreal OU
$ouPath = "OU=Ottawa,DC=jniagwan,DC=com"

# Create Global security groups
$groups = "O_SalesReps", "O_Marketing", "O_HRSupport", "O_Executives"

foreach ($groupName in $groups) {
    # Construct the full path for the new group
    $groupPath = "CN=$groupName,$ouPath"

    # Check if the group already exists
    if (-not (Get-ADGroup -Filter {Name -eq $groupName})) {
        # Create the group
        New-ADGroup -Name $groupName -GroupScope Global -Path $ouPath -GroupCategory Security
        Write-Host "Security group '$groupName' created successfully."
    } else {
        Write-Host "Security group '$groupName' already exists."
    }
}
