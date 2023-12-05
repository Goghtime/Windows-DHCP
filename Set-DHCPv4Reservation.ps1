param(
    [Parameter(Mandatory=$true)]
    [string]$scopeId,

    [Parameter(Mandatory=$true)]
    [string]$clientMAC,

    [Parameter(Mandatory=$true)]
    [string]$reservationIP,

    [Parameter(Mandatory=$true)]
    [string]$clientName,

    [string]$description = "DHCP Reservation"
)

# Load DHCP server information
$DHCPinfo = Get-Content -Path "$PSScriptRoot\env.json" | ConvertFrom-Json
$dhcpServer = $DHCPinfo.Primary.FQDN

try {
    $session = Get-PSSession | Where-Object {($_.ComputerName -eq $dhcpServer) -and $_.State -eq "Opened" } | Select-Object -First 1

    if ($session) {
        Write-Host "Using existing session to $dhcpServer."
    } else {
        Write-Host "No active session found. Please establish a session first."
        return
    }

    # Create DHCP reservation
    $result = Invoke-Command -Session $session -ArgumentList $scopeId, $clientMAC, $reservationIP, $clientName, $description -ScriptBlock {
        param(
            $remoteScopeId, 
            $remoteClientMAC, 
            $remoteReservationIP, 
            $remoteClientName, 
            $remoteDescription
        )
        try {
            Add-DhcpServerv4Reservation -ScopeId $remoteScopeId -ClientId $remoteClientMAC -IPAddress $remoteReservationIP -Description $remoteDescription -Name $remoteClientName
            return "Reservation created successfully for IP $remoteReservationIP"
        } catch {
            return "Failed to create reservation: $_"
        }
    } 

    Write-Host $result -ForegroundColor Green
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
