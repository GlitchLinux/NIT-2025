#!/bin/bash

# Ställ in UTF-8 stöd för svenska tecken
export LANG=en_US.UTF-8

# Funktion för att hämta SNMP-data med snmpget
get_snmp_data() {
    local target=$1
    local oid=$2
    local community=$3
    local result
    # Run snmpget and handle errors
    result=$(snmpget -v2c -c "$community" "$target" "$oid" 2>&1)
    if [[ "$result" =~ "noSuchName" ]]; then
        echo "Fel: Kunde inte hämta data (OID: $oid)"
    elif [[ -z "$result" ]]; then
        echo "Fel: Kunde inte hämta data (OID: $oid)"
    else
        # Extract the value and the type
        value=$(echo "$result" | awk -F': ' '{print $2}' | awk '{print $1}')
        type=$(echo "$result" | awk -F': ' '{print $2}' | awk '{print $2}')
        echo "$value $type"
    fi
}

# Funktion för att konvertera uptime från ticks till dagar, timmar, minuter, sekunder
format_uptime() {
    local ticks=$1
    if [[ "$ticks" =~ ^Fal ]]; then
        echo "Kunde inte konvertera uptime"
        return
    fi
    local seconds=$((ticks / 100))
    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    echo "${days} dagar, ${hours} timmar, ${minutes} minuter, ${secs} sekunder"
}

# Hämta svensk tid
current_time=$(TZ='Europe/Stockholm' date +"%Y-%m-%d %H:%M:%S")

# IP-adresser
server1_ip="193.10.236.126"
server2_ip="193.10.236.127"
switch_ip="193.10.236.4"

# SNMP community
server_community="public"
switch_community="Network!337"

# OID:er
uptime_oid=".1.3.6.1.2.1.1.3.0" # Uptime
free_memory_oid=".1.3.6.1.4.1.2021.4.6.0"  # Free memory (updated OID)
traffic_in_oid=".1.3.6.1.2.1.2.2.1.10.2" # Incoming traffic for ens18 on Server 1
traffic_out_oid=".1.3.6.1.2.1.2.2.1.16.2" # Outgoing traffic for ens18 on Server 1

# Cube-specifika OID:er
free_memory_cube_oid="1.3.6.1.4.1.9.9.48.1.1.1.6.1" # Free memory for Cube
traffic_in_cube_oid="1.3.6.1.2.1.31.1.1.1.6.29" # Incoming traffic for Cube
traffic_out_cube_oid="1.3.6.1.2.1.2.2.1.16.1" # Outgoing traffic for Cube
interface_cube_oid="1.3.6.1.2.1.2.2.1.2.29" # Interface for Cube

# Hämta SNMP-data
uptime_serv1=$(format_uptime $(get_snmp_data "$server1_ip" "$uptime_oid" "$server_community"))
free_memory_serv1=$(get_snmp_data "$server1_ip" "$free_memory_oid" "$server_community")
traffic_serv1_in=$(get_snmp_data "$server1_ip" "$traffic_in_oid" "$server_community")
traffic_serv1_out=$(get_snmp_data "$server1_ip" "$traffic_out_oid" "$server_community")

uptime_serv2=$(format_uptime $(get_snmp_data "$server2_ip" "$uptime_oid" "$server_community"))
free_memory_serv2=$(get_snmp_data "$server2_ip" "$free_memory_oid" "$server_community")
traffic_serv2_in=$(get_snmp_data "$server2_ip" "$traffic_in_oid" "$server_community")
traffic_serv2_out=$(get_snmp_data "$server2_ip" "$traffic_out_oid" "$server_community")

uptime_cube=$(format_uptime $(get_snmp_data "$switch_ip" "$uptime_oid" "$switch_community"))
free_memory_cube=$(get_snmp_data "$switch_ip" "$free_memory_cube_oid" "$switch_community")
traffic_cube_in=$(get_snmp_data "$switch_ip" "$traffic_in_cube_oid" "$switch_community")
traffic_cube_out=$(get_snmp_data "$switch_ip" "$traffic_out_cube_oid" "$switch_community")
interface_cube=$(get_snmp_data "$switch_ip" "$interface_cube_oid" "$switch_community")

# Add Units to values
free_memory_serv1="${free_memory_serv1} KB"
free_memory_serv2="${free_memory_serv2} KB"
traffic_serv1_in="${traffic_serv1_in} bps"
traffic_serv1_out="${traffic_serv1_out} bps"
traffic_serv2_in="${traffic_serv2_in} bps"
traffic_serv2_out="${traffic_serv2_out} bps"
free_memory_cube="${free_memory_cube} KB"
traffic_cube_in="${traffic_cube_in} bps"
traffic_cube_out="${traffic_cube_out} bps"

# Skapa HTML-sida
cat <<EOF
Content-type: text/html

<html>
<head>
    <meta charset="UTF-8">
    <title>SNMP Data</title>
</head>
<body>
<h2 style="text-align: center;">Datum & Tid: $current_time</h2>
<hr>

    <!-- Server 1 -->
    <h3>Server 1 </h3>
    <p><strong>Uptime:</strong> $uptime_serv1 </p>
    <p><strong>Ledigt RAM:</strong> $free_memory_serv1 </p>
    <p><strong>Inkommande trafik:</strong> $traffic_serv1_in </p>
    <p><strong>Utgående trafik:</strong> $traffic_serv1_out </p>

<hr>

 <!-- Server 2 -->
    <h3>Server 2 </h3>
    <p><strong>Uptime:</strong> $uptime_serv2 </p>
    <p><strong>Ledigt RAM:</strong> $free_memory_serv2 </p>
    <p><strong>Inkommande trafik:</strong> $traffic_serv2_in </p>
    <p><strong>Utgående trafik:</strong> $traffic_serv2_out </p>

<hr>
  <!-- Cube (Switch) -->
    <h3>CUBE</h3>
    <p><strong>Uptime:</strong> $uptime_cube </p>
    <p><strong>Interface:</strong> TenGigabitEthernet5/12 - $interface_cube</p>
    <p><strong>Ledigt RAM:</strong> $free_memory_cube </p>
    <p><strong>Inkommande trafik:</strong> $traffic_cube_in </p>
    <p><strong>Utgående trafik:</strong> $traffic_cube_out </p>
<hr>
</body>
</html>
EOF
