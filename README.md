INT_SERVER_1 - ssh grp13-serv1@193.10.236.126

INT_SERVER_2 - ssh grp13-serv2@193.10.236.127

```markdown
# Guide för Webbserver och DNS-konfiguration

Denna guide ger instruktioner för att sätta upp en webbserver (Apache2) och konfigurera DNS på en server. Uppgifterna inkluderar installation och konfiguration av Apache2, skapande av virtuella hostar, säkring av servern med självsignerade certifikat och konfiguration av DNS-poster.

## Innehållsförteckning
1. [Webbserverkonfiguration](#webbserverkonfiguration)
   - [Installera Apache2](#installera-apache2)
   - [Skapa virtuella hostar](#skapa-virtuella-hostar)
   - [Säkra virtuella hostar med SSL](#säkra-virtuella-hostar-med-ssl)
   - [Inaktivera standard virtuell host](#inaktivera-standard-virtuell-host)
   - [Dynamiska skript](#dynamiska-skript)
2. [DNS-konfiguration](#dns-konfiguration)
   - [Konfigurera DNS-poster](#konfigurera-dns-poster)
   - [Netbox-konfiguration](#netbox-konfiguration)
   - [BIND9-konfiguration](#bind9-konfiguration)
   - [Verifiera DNS-funktionalitet](#verifiera-dns-funktionalitet)

---

## Webbserverkonfiguration

### Installera Apache2
1. Installera Apache2 på `server2`:
   ```bash
   sudo apt update
   sudo apt install apache2
   ```

2. Starta och aktivera Apache2:
   ```bash
   sudo systemctl start apache2
   sudo systemctl enable apache2
   ```

3. Kontrollera brandväggsinställningar för att tillåta HTTP (port 80) och HTTPS (port 443):
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

---

### Skapa virtuella hostar
1. Skapa en CNAME-post i DNS för `www` och `vvv` som pekar på `server2`.

2. Skapa en virtuell host för `www.grpXX.lab.hv.se` med gul bakgrund (`#fdbf00`):
   - Skapa en konfigurationsfil för den virtuella hosten:
     ```bash
     sudo nano /etc/apache2/sites-available/www.grpXX.lab.hv.se.conf
     ```
   - Lägg till följande innehåll:
     ```apache
     <VirtualHost *:80>
         ServerName www.grpXX.lab.hv.se
         DocumentRoot /var/www/www.grpXX.lab.hv.se
         <Directory /var/www/www.grpXX.lab.hv.se>
             AllowOverride All
             Require all granted
         </Directory>
         ErrorLog ${APACHE_LOG_DIR}/error.log
         CustomLog ${APACHE_LOG_DIR}/access.log combined
     </VirtualHost>
     ```
   - Skapa mappen för dokumentroten:
     ```bash
     sudo mkdir -p /var/www/www.grpXX.lab.hv.se
     ```
   - Aktivera den virtuella hosten:
     ```bash
     sudo a2ensite www.grpXX.lab.hv.se.conf
     ```

3. Upprepa stegen för att skapa virtuella hostar för:
   - `vvv.grpXX.lab.hv.se` med rosa bakgrund (`#f7dcea`).
   - `☺️.grpXX.lab.hv.se` med grön bakgrund (`#81ba4f`).

---

### Säkra virtuella hostar med SSL
1. Generera självsignerade certifikat för `www.grpXX.lab.hv.se` och `vvv.grpXX.lab.hv.se`:
   ```bash
   sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/www.grpXX.lab.hv.se.key -out /etc/ssl/certs/www.grpXX.lab.hv.se.crt
   ```

2. Konfigurera Apache för att använda SSL:
   - Aktivera SSL-modulen:
     ```bash
     sudo a2enmod ssl
     ```
   - Skapa en ny konfigurationsfil för HTTPS:
     ```bash
     sudo nano /etc/apache2/sites-available/www.grpXX.lab.hv.se-ssl.conf
     ```
   - Lägg till följande innehåll:
     ```apache
     <VirtualHost *:443>
         ServerName www.grpXX.lab.hv.se
         DocumentRoot /var/www/www.grpXX.lab.hv.se
         SSLEngine on
         SSLCertificateFile /etc/ssl/certs/www.grpXX.lab.hv.se.crt
         SSLCertificateKeyFile /etc/ssl/private/www.grpXX.lab.hv.se.key
         <Directory /var/www/www.grpXX.lab.hv.se>
             AllowOverride All
             Require all granted
         </Directory>
         ErrorLog ${APACHE_LOG_DIR}/error.log
         CustomLog ${APACHE_LOG_DIR}/access.log combined
     </VirtualHost>
     ```
   - Aktivera den nya konfigurationen:
     ```bash
     sudo a2ensite www.grpXX.lab.hv.se-ssl.conf
     ```

3. Upprepa stegen för `vvv.grpXX.lab.hv.se`.

---

### Inaktivera standard virtuell host
1. Inaktivera standard virtuell host för port 80 och 443:
   ```bash
   sudo a2dissite 000-default.conf
   sudo a2dissite default-ssl.conf
   ```

2. Ladda om Apache för att tillämpa ändringarna:
   ```bash
   sudo systemctl reload apache2
   ```

3. Kontrollera att åtkomst till `193.10.236.XX` eller `grpXX-serv2.grpXX.lab.hv.se` ger ett felmeddelande (t.ex. "Forbidden").

---

### Dynamiska skript
1. Skapa ett Python-skript som visar klockan:
   - Skapa en fil i dokumentroten:
     ```bash
     sudo nano /var/www/www.grpXX.lab.hv.se/clock.py
     ```
   - Lägg till följande innehåll:
     ```python
     #!/usr/bin/env python3
     from datetime import datetime
     print("Content-Type: text/html\n")
     print(f"<h1>Aktuell tid: {datetime.now()}</h1>")
     ```
   - Gör filen körbar:
     ```bash
     sudo chmod +x /var/www/www.grpXX.lab.hv.se/clock.py
     ```

2. Skapa ett Bash- eller Python-skript som visar SNMP-data (t.ex. uptime, ledigt RAM, nätverkstrafik):
   - Exempel på Bash-skript:
     ```bash
     #!/bin/bash
     echo "Content-Type: text/html\n"
     echo "<h1>SNMP Data</h1>"
     echo "<p>Uptime: $(snmpget -v2c -c public 193.10.236.4 .1.3.6.1.2.1.1.3.0)</p>"
     echo "<p>Ledigt RAM: $(snmpget -v2c -c public 193.10.236.4 .1.3.6.1.2.1.25.2.2.0)</p>"
     echo "<p>Nätverkstrafik: $(snmpget -v2c -c public 193.10.236.4 .1.3.6.1.2.1.2.2.1.10.XX)</p>"
     ```

---

## DNS-konfiguration

### Konfigurera DNS-poster
1. Skapa CNAME-poster för `www` och `vvv` som pekar på `server2`.

2. Konfigurera zonfiler för att inkludera SOA, PTR, CNAME, MX, LOC och AAAA-poster.

---

### Netbox-konfiguration
1. Logga in på Netbox (`http://193.10.203.20:8000/`) med användarnamn `nit2024` och lösenord `!u0ePrad8wast`.

2. Skapa en ny enhet (Device) med:
   - 2 CPU
   - 2 GB RAM
   - 20 GB disk
   - Namn som matchar serverns hostname.

3. Lägg till ett nätverkskort med namnet `ens18` (utan IP-nummer).

4. Allokera rätt IP-nummer från rätt VLAN i IPAM.

---

### BIND9-konfiguration
1. Läs kapitel 8.1.4 "Access Control Lists" i BIND9-referensmanualen för att förstå hur ACL används i `named.conf`.

2. Starta om BIND9 och kontrollera att det inte finns några varningar:
   ```bash
   tail -f /var/log/syslog & systemctl restart named
   ```

3. Använd `dig` för att verifiera DNS-funktionalitet:
   - Exempel:
     ```bash
     dig www.grpXX.lab.hv.se
     ```

---

### Verifiera DNS-funktionalitet
1. Kontrollera att DNS-svar på:
   - SOA
   - PTR
   - CNAME
   - MX
   - LOC
   - AAAA

2. Verifiera att DNS-slavservern fungerar korrekt och synkroniseras automatiskt med mastern.

---

## Följdfråga
Varför vill du använda virtuella hostar?  
Svar: Virtuella hostar tillåter att flera webbplatser delar samma IP-adress och serverresurser, vilket gör det möjligt att hantera flera domäner på en enda server.

---

## Ytterligare krav
- Visa mappstrukturen i `/var/www`.
- Kontrollera att directory listing är inaktiverat (felmeddelande "Forbidden").
- Dölj Apache-versionen i felmeddelanden (t.ex. 404).
```
