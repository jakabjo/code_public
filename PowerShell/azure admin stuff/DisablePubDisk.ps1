<#
------------------------------------------------------------------------------
.SYNOPSIS
    Check public network access on VM disks.
.DESCRIPTION
    This script is designed to iterate through all subscriptions on an Azure tenant 
    then iterate throught the VMs in those subscriptions to test if the disks on a VM has 
    PublicNetworkAccess enabled and then disable it.
.NOTES
    File Name      : DisablePubDisk.ps1
    Author         : Jason Johnson / jkjohnson@gmail.com
    Prerequisite   : PowerShell V2.
    Copyright 2024 - Jason Johnson
.LINK

.EXAMPLE

------------------------------------------------------------------------------    
#>

# Function to disable PublicNetworkAccess on a disk
function Disable-PublicNetworkAccess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$resourceId
    )

    # Disable PublicNetworkAccess for the disk
    $disk = Get-AzDisk -ResourceGroupName $resourceId.Split('/')[4] -DiskName $resourceId.Split('/')[8]
    $disk.DiskAccessId = $null
    $disk | Set-AzDisk
}

# Function to iterate through subscriptions and VMs
function Iterate-SubscriptionsAndVMs {
    # Get all Azure subscriptions
    $subscriptions = Get-AzSubscription

    # Iterate through each subscription
    foreach ($subscription in $subscriptions) {
        Write-Host "Processing subscription: $($subscription.Name)"
        
        # Set the current subscription context
        Set-AzContext -SubscriptionId $subscription.Id

        # Get all VMs in the current subscription
        $vms = Get-AzVM

        # Iterate through each VM
        foreach ($vm in $vms) {
            Write-Host "Processing VM: $($vm.Name)"

            # Check PublicNetworkAccess policy for OS disk
            $osDisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
            if ($osDisk.DiskAccessId -eq "Public") {
                Write-Host "PublicNetworkAccess is enabled for OS disk of VM: $($vm.Name)"
                Disable-PublicNetworkAccess -resourceId $osDisk.Id
                Write-Host "Disabled PublicNetworkAccess for OS disk of VM: $($vm.Name)"
            }

            # Check PublicNetworkAccess policy for data disks
            foreach ($dataDisk in $vm.StorageProfile.DataDisks) {
                $dataDiskResource = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name
                if ($dataDiskResource.DiskAccessId -eq "Public") {
                    Write-Host "PublicNetworkAccess is enabled for data disk $($dataDisk.Name) of VM: $($vm.Name)"
                    Disable-PublicNetworkAccess -resourceId $dataDiskResource.Id
                    Write-Host "Disabled PublicNetworkAccess for data disk $($dataDisk.Name) of VM: $($vm.Name)"
                }
            }
        }
    }
}

# Main script execution
try {
    # Connect to Azure account
    Connect-AzAccount

    # Call function to iterate through subscriptions and VMs
    Iterate-SubscriptionsAndVMs
}
catch {
    Write-Host "Error occurred: $_"
}
