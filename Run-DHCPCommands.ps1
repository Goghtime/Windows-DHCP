# Load DHCP server information
$DHCPinfo = Get-Content -Path "$PSScriptRoot\env.json" | ConvertFrom-Json
$dhcpServer = $DHCPinfo.Primary.FQDN

try {
    $session = Get-PSSession | Where-Object {($_.ComputerName -eq $dhcpServer) -and $_.State -eq "Opened" } | Select-Object -First 1

    if ($session -and $session.State -eq 'Opened') {
        Write-Host "Session to $dhcpServer found. Executing commands..."

        $leases = Invoke-Command -Session $session -ScriptBlock {
            param($ScopeID)
            Import-Module DhcpServer
    
            # Add Commands here.
            Get-DhcpServerv4Scope
            Get-DhcpServerv4DnsSetting
            Get-DhcpServerv4Failover
            Get-DhcpServerv4ScopeStatistics -ScopeId 192.168.10.0
            Get-DhcpServerv4Statistics

        } 

        $leases | Format-Table -AutoSize
    } else {
        Write-Warning "No active session to $dhcpServer. Please establish a session first."
    }
} catch {
    Write-Error "An error occurred: $_"
}
