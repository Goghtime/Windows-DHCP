param(
    [ValidateSet("Active", "ActiveReservation")]
    [string]$status = "Active"
)


# Load DHCP server information
$DHCPinfo = Get-Content -Path "C:\Projects\Windows-DHCP\env.json" | ConvertFrom-Json
$dhcpServer = $DHCPinfo.Primary.FQDN

# Present a list of scopes and get user choice
$scopesObject = $DHCPinfo.Scopes
$scopeNames = $scopesObject.PSObject.Properties.Name
$scopeNamesArray = $scopeNames -as [array]

Write-Host "Available DHCP Scopes:"
for ($i = 0; $i -lt $scopeNamesArray.Length; $i++) {
    Write-Host "$($i + 1). $($scopeNamesArray[$i])"
}

$selectedNumber = Read-Host "Please choose a scope (enter number)"
$selectedScopeName = $null

if ([int]::TryParse($selectedNumber, [ref]$selectedNumber) -and $selectedNumber -gt 0 -and $selectedNumber -le $scopeNamesArray.Length) {
    $selectedScopeName = $scopeNamesArray[$selectedNumber - 1]
}

if (-not $selectedScopeName) {
    Write-Host "Invalid selection. Exiting script." -ForegroundColor Red
    exit
}

$scopeID = $scopesObject.$selectedScopeName

try {
    $session = Get-PSSession | Where-Object {($_.ComputerName -eq $dhcpServer) -and $_.State -eq "Opened" } | Select-Object -First 1

    if ($session -and $session.State -eq 'Opened') {
        Write-Host "Session to $dhcpServer found. Executing commands..."

        $leases = Invoke-Command -Session $session -ScriptBlock {
            param(
                $ScopeID,
                $RemoveStatus)
            Import-Module DhcpServer
            Get-DhcpServerv4Lease -ScopeId $ScopeID | Where-Object {$_.AddressState -eq $RemoveStatus} | Select-Object HostName, IPAddress, ClientId, ScopeId
        } -ArgumentList $scopeID, $status

        $leases | Format-Table -AutoSize
    } else {
        Write-Warning "No active session to $dhcpServer. Please establish a session first."
    }
} catch {
    Write-Error "An error occurred: $_"
}
