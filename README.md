SERVER 1:      ssh grp13-serv1@193.10.236.126      
--------------------------------------------------------------------
SERVER 2:      ssh grp13-serv2@193.10.236.127
--------------------------------------------------------------------

Det här är en omfattande uppgift där du ska konfigurera en Apache-webbserver med virtuella hosts, DNS-poster och säkerhetsåtgärder, samt implementera dynamiska sidor för att visa SNMP-data.  

Jag delar upp det i logiska steg:  

---

### **1. Förberedelser och installationer**  
På **srv2** (din webbserver):  
- **Installera Apache2**  
  ```bash
  sudo apt update
  sudo apt install apache2 -y
  ```

- **Installera NetSurf (för att se HTTP-sidor utan HTTPS)**  
  ```bash
  sudo apt install netsurf -y
  ```

- **Installera SNMP-verktyg och Python-moduler**  
  ```bash
  sudo apt install snmp snmpd python3-pysnmp -y
  ```

---

### **2. Brandväggsinställningar**  
På både **srv1** och **srv2**, se till att UFW är konfigurerad korrekt:

```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 161/udp     # SNMP
sudo ufw enable
sudo ufw status
```

---

### **3. DNS-konfiguration i BIND9**  
På **srv1** (din DNS-server):  

- **Skapa CNAME-poster** i zonfilen (`/etc/bind/db.grpXX.lab.hv.se`):  

  ```bash
  www     IN  CNAME   serv2.grpXX.lab.hv.se.
  vvv     IN  CNAME   serv2.grpXX.lab.hv.se.
  ☺️      IN  CNAME   serv2.grpXX.lab.hv.se.
  ```

- **Starta om BIND9**  
  ```bash
  sudo systemctl restart bind9
  sudo systemctl status bind9
  ```

- **Testa med dig**  
  ```bash
  dig www.grpXX.lab.hv.se
  dig vvv.grpXX.lab.hv.se
  dig ☺️.grpXX.lab.hv.se
  ```

---

### **4. Skapa virtuella hosts i Apache på srv2**  

- **Skapa mappar och sidor för varje host**  
  ```bash
  sudo mkdir -p /var/www/{www,vvv,emoji}.grpXX.lab.hv.se
  ```

- **Skapa HTML-filer med rätt bakgrundsfärger**  

  ```bash
  echo '<html><body style="background:#fdbf00;">WWW</body></html>' | sudo tee /var/www/www.grpXX.lab.hv.se/index.html
  echo '<html><body style="background:#f7dcea;">VVV</body></html>' | sudo tee /var/www/vvv.grpXX.lab.hv.se/index.html
  echo '<html><body style="background:#81ba4f;">Emoji</body></html>' | sudo tee /var/www/emoji.grpXX.lab.hv.se/index.html
  ```

- **Skapa virtuella host-konfigurationer**  

  ```bash
  sudo nano /etc/apache2/sites-available/www.grpXX.lab.hv.se.conf
  ```

  Innehåll:  
  ```
  <VirtualHost *:80>
      ServerName www.grpXX.lab.hv.se
      DocumentRoot /var/www/www.grpXX.lab.hv.se
  </VirtualHost>
  ```

  Gör samma för `vvv` och `emoji`.

- **Aktivera konfigurationerna**  
  ```bash
  sudo a2ensite www.grpXX.lab.hv.se.conf
  sudo a2ensite vvv.grpXX.lab.hv.se.conf
  sudo a2ensite emoji.grpXX.lab.hv.se.conf
  sudo systemctl reload apache2
  ```

---

### **5. HTTPS med self-signed certifikat**  
På **srv2**, generera certifikat:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/www.key -out /etc/ssl/certs/www.crt
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vvv.key -out /etc/ssl/certs/vvv.crt
```

Skapa en Apache-konfig för HTTPS:

```bash
sudo nano /etc/apache2/sites-available/www-ssl.conf
```

Innehåll:

```
<VirtualHost *:443>
    ServerName www.grpXX.lab.hv.se
    DocumentRoot /var/www/www.grpXX.lab.hv.se
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/www.crt
    SSLCertificateKeyFile /etc/ssl/private/www.key
</VirtualHost>
```

Aktivera moduler och konfigurera:

```bash
sudo a2enmod ssl
sudo a2ensite www-ssl.conf
sudo systemctl reload apache2
```

---

### **6. Inaktivera default-virtuella hosten**
```bash
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
```

Testa:  
```bash
curl -I http://193.10.236.XX
```
Det ska returnera **403 Forbidden**.

---

### **7. Stäng av directory listing och göm Apache-version**
I `/etc/apache2/apache2.conf`, leta upp:

```
<Directory /var/www/>
    Options Indexes FollowSymLinks
    AllowOverride None
</Directory>
```
Ändra `Indexes` till `-Indexes` och starta om:

```bash
sudo systemctl reload apache2
```

Dölj Apache-versionen i `/etc/apache2/conf-available/security.conf`:

```bash
ServerTokens Prod
ServerSignature Off
```

Ladda om Apache:

```bash
sudo systemctl reload apache2
```

---

### **8. Dynamiskt Python-script (Klocka)**
Skapa:

```bash
sudo nano /var/www/cgi-bin/clock.py
```

Innehåll:

```python
#!/usr/bin/python3
import datetime
print("Content-type: text/html\n")
print(f"<html><body><h1>{datetime.datetime.now()}</h1></body></html>")
```

Gör det körbart:

```bash
sudo chmod +x /var/www/cgi-bin/clock.py
sudo a2enmod cgi
sudo systemctl reload apache2
```

---

### **9. Dynamiskt SNMP-script**
Skapa:

```bash
sudo nano /var/www/cgi-bin/snmp.py
```

Innehåll:

```python
#!/usr/bin/python3
from pysnmp.hlapi import *
def snmp_get(ip, oid):
    iterator = getCmd(SnmpEngine(),
                      CommunityData('public', mpModel=0),
                      UdpTransportTarget((ip, 161)),
                      ContextData(),
                      ObjectType(ObjectIdentity(oid)))
    for errorIndication, errorStatus, errorIndex, varBinds in iterator:
        for varBind in varBinds:
            return varBind.prettyPrint()

print("Content-type: text/html\n")
print("<html><body>")
print("<h1>SNMP Data</h1>")
print(f"Uptime: {snmp_get('193.10.236.4', '1.3.6.1.2.1.1.3.0')}")
print("</body></html>")
```

Gör det körbart:

```bash
sudo chmod +x /var/www/cgi-bin/snmp.py
sudo systemctl reload apache2
```

---

### **10. Verifiera**
- Testa DNS-poster med `dig`
- Testa webbservern i en webbläsare
- Testa SNMP-skriptet: `http://www.grpXX.lab.hv.se/cgi-bin/snmp.py`

Detta täcker alla uppgifter! 🚀
