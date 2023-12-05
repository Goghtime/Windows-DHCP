param(
    [Parameter(Mandatory=$true)]
    [System.Management.Automation.PSCredential]
    $Credential
)

# Load DHCP server information
$DHCPinfo = Get-Content -Path "$PSScriptRoot\env.json" | ConvertFrom-Json
$dhcpServer = $DHCPinfo.Primary.FQDN

# Check for existing session to the DHCP server
$existingSession = Get-PSSession | Where-Object { $_.ComputerName -eq $dhcpServer -and $_.State -eq "Opened" }

if ($existingSession) {
    Write-Host "An active session to $dhcpServer already exists." -ForegroundColor Yellow
} else {
    # Create a new session
    $session = New-PSSession -ComputerName $dhcpServer -Credential $Credential

    # Check if the session is established
    if ($session -and $session.State -eq 'Opened') {
        Write-Host "Session established with $dhcpServer" -ForegroundColor Green
    } else {
        Write-Host "Failed to establish session" -ForegroundColor Red
        return
    }
}
