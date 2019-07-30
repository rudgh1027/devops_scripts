$surfix="-test-devtst-gkim"

#create tag
$mytg = @{ Creator = "ghkim"}

#create rg
$rg = New-AzResourceGroup -name "rg$surfix" -Tag $mytg -Location westus

# Storage Account
$stor = New-AzStorageAccount -Name "stortstgkim$(get-random)" -Location $rg.Location -ResourceGroupName $rg.ResourceGroupName -SkuName Standard_LRS -Kind StorageV2 -Tag $mytg -AccessTier hot

# Define user name and blank password
$userID = read-host -prompt "Input OS Login ID : "
$passwd = read-host -prompt "Input OS Login PW : " -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential ($userID, $passwd)

# define nsg
$nsg = New-AzNetworkSecurityGroup -name "nsg$surfix$(get-random)" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Tag $mytg

$nsg | add-AzNetworkSecurityRuleConfig -Name "nsgrule$surfix$(get-random)" -Description "allow-22" -Access Allow `
    -Protocol tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange "22"
$nsg | add-AzNetworkSecurityRuleConfig -Name "nsgrule$surfix$(get-random)" -Description "allow-3389" -Access Allow `
    -Protocol tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange "3389"

$nsg | Set-AzNetworkSecurityGroup

# mak subnet and vnet
$subnet0 = new-azvirtualnetworksubnetconfig -name "subnet$surfix$(get-random)" -AddressPrefix 10.41.9.0/24 -NetworkSecurityGroup $nsg
$vnet = New-AzVirtualNetwork -name "vnet$surfix$(get-random)" -ResourceGroupName $rg.ResourceGroupName -location $rg.Location -addressprefix 10.41.0.0/16 -Subnet $subnet0 -Tag $mytg
$vnet | Set-AzVirtualNetwork

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location `
  -Name "pip$surfix$(get-random)" -AllocationMethod dynamic -IdleTimeoutInMinutes 4 -Tag $mytg


# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name "nic$surfix$(get-random)" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id -Tag $mytg

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName "vm$surfix" -VMSize Standard_B1s |
Set-AzVMOperatingSystem -Linux -ComputerName "vm$surfix" -Credential $cred  | #-DisablePasswordAuthentication
Set-AzVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest |
Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -VM $vmConfig -Tag $mytg

# connect vm
$pip_name=$pip.name
$pip = get-AzPublicIpAddress -name $pip_name

ssh gkadmin@$pip.ipAddress

