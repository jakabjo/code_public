<#
.SYNOPSIS
  Export Entra ID users with Security Groups, Directory Roles, and RBAC (all subscriptions) to CSV.

.REQUIREMENTS
  Modules:
    Az.Accounts, Az.Resources
    Microsoft.Graph (Microsoft.Graph.Users, Microsoft.Graph.Groups)
  Permissions:
    Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Directory.Read.All"
    Az context with Reader (or above) to read role assignments per subscription

.USAGE
  pwsh ./Export-AzureUsersFull.ps1 -OutPath users_full.csv
#>

param(
  [string]$OutPath = "users_full.csv"
)

# Connect (interactive for demo). In automation, use federated creds/managed identity where possible.
if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
  Connect-AzAccount | Out-Null
}
if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
  Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Directory.Read.All"
  Select-MgProfile -Name "v1.0"
}

# Get all subscriptions the identity can read
$subs = Get-AzSubscription

# Get all users (paged)
$users = @()
$uri = "https://graph.microsoft.com/v1.0/users`?$select=id,displayName,userPrincipalName,mail"
while ($uri) {
  $page = Invoke-MgGraphRequest -Method GET -Uri $uri -Headers @{ "ConsistencyLevel" = "eventual" }
  $users += $page.value
  $uri = $page.'@odata.nextLink'
}

# Helper: memberOf (security groups + directory roles)
function Get-MemberOfInfo {
  param([string]$UserId)
  $groups = New-Object System.Collections.Generic.HashSet[string]
  $dirRoles = New-Object System.Collections.Generic.HashSet[string]

  $uri = "https://graph.microsoft.com/v1.0/users/$UserId/memberOf`?$select=displayName"
  while ($uri) {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -Headers @{ "ConsistencyLevel" = "eventual" }
    foreach ($obj in $resp.value) {
      $otype = ($obj.'@odata.type' | ForEach-Object { $_.ToLower() })
      $name  = $obj.displayName
      if ([string]::IsNullOrWhiteSpace($name)) { continue }
      if ($otype -like "*microsoft.graph.group*") { [void]$groups.Add($name) }
      elseif ($otype -like "*microsoft.graph.directoryrole*") { [void]$dirRoles.Add($name) }
    }
    $uri = $resp.'@odata.nextLink'
  }

  return ,@([string]::Join("; ", $groups), [string]::Join("; ", $dirRoles))
}

# Helper: RBAC for one principal across all subscriptions
function Get-UserRbacAcrossSubs {
  param([string]$ObjectId)
  $all = New-Object System.Collections.Generic.HashSet[string]

  foreach ($s in $subs) {
    Set-AzContext -SubscriptionId $s.Id | Out-Null
    try {
      $assign = Get-AzRoleAssignment -ObjectId $ObjectId -ErrorAction Stop
      foreach ($a in $assign) {
        $role = $a.RoleDefinitionName
        $scope = $a.Scope
        [void]$all.Add("$role @ $scope")
      }
    } catch {
      Write-Warning "RBAC read failed for $ObjectId in sub $($s.Id): $($_.Exception.Message)"
    }
  }

  return [string]::Join("; ", $all)
}

# Build rows
$rows = foreach ($u in $users) {
  $uid  = $u.id
  $name = $u.displayName
  $upn  = $u.userPrincipalName
  $mail = $u.mail

  $groups, $dirRoles = Get-MemberOfInfo -UserId $uid
  $rbac = Get-UserRbacAcrossSubs -ObjectId $uid

  [pscustomobject]@{
    DisplayName    = $name
    UPN            = $upn
    Email          = $mail
    SecurityGroups = $groups
    DirectoryRoles = $dirRoles
    RBACRoles      = $rbac
  }
}

$rows | Sort-Object UPN | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $($rows.Count) users to $OutPath"
