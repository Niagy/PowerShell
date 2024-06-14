$domainName = "my.zwilling.com"
$zoneName = "zwilling.com"
$dnsServer = "localhost"  # Change to your DNS server name if not localhost
$externalDNSServer = "8.8.8.8"  # External DNS server to compare against

function Get-CurrentIPs {
    param ($domain)
    try {
        # Fetch the current IP addresses from an external DNS service
        $dnsRecords = Resolve-DnsName -Name $domain -Type A -Server $externalDNSServer
        return $dnsRecords | Where-Object { $_.QueryType -eq "A" } | Select-Object -ExpandProperty IPAddress
    } catch {
        Write-Host "Failed to resolve DNS for $domain"
        return $null
    }
}

function Update-DNSRecord {
    param ($zone, $name, $ips, $server)

    # Remove existing A records
    $existingRecords = Get-DnsServerResourceRecord -ZoneName $zone -Name $name -ComputerName $server -RRType "A"
    foreach ($record in $existingRecords) {
        if ($record.RecordType -eq "A") {
            Remove-DnsServerResourceRecord -ZoneName $zone -Name $name -RRType "A" -ComputerName $server -RecordData $record.RecordData.IPv4Address -Force
            Write-Host "Removed DNS record for $name.$zone with IP $($record.RecordData.IPv4Address)"
        }
    }

    # Add new A records
    foreach ($ip in $ips) {
        # Check if the record already exists locally
        $existingRecord = Get-DnsServerResourceRecord -ZoneName $zone -Name $name -ComputerName $server -RRType "A" -ErrorAction SilentlyContinue
        if ($existingRecord -eq $null -or $existingRecord.RecordData.IPv4Address -ne $ip) {
            Add-DnsServerResourceRecordA -Name $name -ZoneName $zone -IPv4Address $ip -ComputerName $server
            Write-Host "Added/Updated DNS record for $name.$zone with IP $ip"
        } else {
            Write-Host "DNS record for $name.$zone with IP $ip already up to date"
        }
    }
}

# Fetch current IPs from external DNS
$currentIPs = Get-CurrentIPs -domain $domainName
if ($currentIPs -ne $null -and $currentIPs.Count -gt 0) {
    # Update local DNS records if they differ from external DNS
    Update-DNSRecord -zone $zoneName -name "my" -ips $currentIPs -server $dnsServer
} else {
    Write-Host "No IPs found for $domainName"
}
