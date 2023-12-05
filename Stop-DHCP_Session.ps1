# Load DHCP server information
$DHCPinfo = Get-Content -Path "$PSScriptRoot\env.json" | ConvertFrom-Json
$dhcpServer = $DHCPinfo.Primary.FQDN

try {
    $session = Get-PSSession | Where-Object {($_.ComputerName -eq $dhcpServer) -and $_.State -eq "Opened" } | Select-Object -First 1

    if ($session -and $session.State -eq 'Opened') {
        Write-Host "Active session to $dhcpServer found. Session ID: $($session.Id)" -ForegroundColor Green
        $userChoice = Read-Host "Do you want to close this session? (Yes/No)"
        
        if ($userChoice -eq "Yes") {
            Remove-PSSession -Session $session
            Write-Host "Session closed." -ForegroundColor Yellow
        } else {
            Write-Host "Session left open." -ForegroundColor Yellow
        }
    } else {
        Write-Warning "No active session to $dhcpServer. Please establish a session first."
    }
} catch {
    Write-Error "An error occurred: $_"
}
