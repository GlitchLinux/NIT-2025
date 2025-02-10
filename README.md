############################
2. Webserver (Apache2) på server2
Läs hela kapitel 19 "Web Hosting" 
   (Läs hela stycket 19.4 "Apache HTTPD")
       ((Läs hela sektionen 19.4.x "Virtual Host Configuration"))

Uppgiften nedan blir lättare om du stänger av HSTS

Links to an external site.Links to an external site. i webb-läsaren: (Kanske Chrome-FirefoxLinks to an external site.

Links to an external site.Links to an external site. tips)

HTTP kan numera inte visas i Chrome,Edge eller Firefox; bara visas i enkla webläsare som t.ex. Netsurf. Installera den!

Visa korrekt brandvägg srv1 och srv2
Webservern (Apache2) installeras på srv2
Skapa CNAME i DNS för www och vvv som pekar mot serv2
Skapa virtuell host www.grpXX.lab.hv.seLinks to an external site. med länkar till alla uppgifter nedan (gul #fdbf00 bakgrund)
Visa att du skapat en ny virtuell host vvv.grpXX.lab.hv.se (rosa #f7dcea bakgrund)
Visa att du skapat en ny tredje virtuell host ☺️.grpXX.lab.hv.se (grön #81ba4f bakgrund)
Säkra upp www.grupp.lab.hv.seLinks to an external site. med ett self-signedd certifikat och kommunikation på port 443
Säkra upp vvv.grupp.lab.hv.seLinks to an external site. med ett self-signedd certifikat och kommunikation på port 443
Visa att du inaktiverat default-virtuella hosten (server2.grpXX.lab.hv.se) på port 80
Visa att du inaktiverat default-virtuella hosten (server2.grpXX.lab.hv.se) på port 443
Om du surfar till 193.10.236.XX eller grpXX-serv2.grpXX.lab.hv.se (http eller https) skall du få felmeddelande (eller texten "Forbidden")
Följdfråga: Varför vill du använda dig av virtuella hostar?
Visa din mappstruktur i /var/www
Visa i webbläsaren att du stängt av directory listning (Få felmeddelande "Forbidden. You don't have permission to access this resource.)
Visa i webbläsaren att du gömmer information (stängt av) om vilken version Apache kör när du får ett felmeddelande (t.ex. 404)
Dynamiskt Python-Script som visar klockan (tryck F5 för att uppdatera)
Med dynamiskt script (Bash eller Python) på webservern visa text med SNMP-data + OID-path:
   ❶  uptime, ❷  Ledigt RAM,  ❸  trafik på nätverkskortet (ifinoctets brukar vara det intressanta måttet) från:    
 ⓵ cube (193.10.236.4) - port Tengigabit 5/10   ifindex XX,    (eller interface vlan 17), 
 ⓶ serv1.grpX.lab.hv.se och 
 ⓷ serv2.grpX.lab.hv.se
Data ändras när man trycker uppdatera (F5)
############################
1. Namntjänst (DNS)
Visa båda brandväggen på båda servrarna -- ESTABLISHED eller RELATED regler skall vara (näst) längs ned
Visa att brandväggsreglerna är sparade och att de läses in vid en serveromstart
Gör backup av /etc/bind/*  genom att kopiera filer till er Windows hemkatalog (App-exempel:  winscp)
Visa korrekt dokumenterade servrar (2st) i Netbox (http://193.10.203.20:8000/med kontot nit2024 med lösenord !u0ePrad8wast  )
i Netbox: Skapa Device med 2 CPU, 2GB RAM och 20 GB disk och som heter samma som er maskin
i Netbox: Lägg till ett nätverkskort som heter ens18 (men utan IP-nummer)
i Netbox: Se till att er nya (virtuella) Device är kopplad till rätt Resource...
i Netbox: Gå till till IPAM (IP Address Management) och allokera ert rätta IP-nummer från Range (inte Prefix) med rätt VLAN-nummer
Visa motsvarande nedanstående bild, för era två servrar
image.png
Denna fråga handlar om att läsa referens-manualen, inte konfa!
  Läs i BIND9 reference manual  under "8.1.4 - Access Control Lists":
    Vilka "options" i named.conf kan använda "acl" (Address Match List)?
Läs originaldokumentationen (Absolute Truth!?!) om LOC https://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml
Visa att DNS-server startar utan varningar med kommandot:
    tail -f /var/log/syslog &  systemctl restart named
skriv sedan  fg  följt av CTRL-C för att avbryta

ENDAST KOMMANDOT dig FÅR ANVÄNDAS VID REDOVISNING
Visa att ni inte svarar på rekursiva frågor från andra maskiner än era egna!
Visa att er zon är delegerad (endast framlänges) och därmed kopplad till DNS på hela Internet.
Visa att DNS-slavservern fungerar korrekt (full kopiering av mastern, automatiska uppdateringar, etc etc)
Visa att följande fungerar på ett korrekt sätt:

SOA   (använd studentmailen)
PTR        (Fråga er server om ert IP-nummer)
CNAME
MX
LOC
AAAA (Vi använd addressformatet 2001:6b0:1d:36::xx där xx är serverns sista IP-nummer oktet (t.ex. blir 193.10.236.99 2001:6b0:1d:36::99 )
(Ni behöver inte installera IPv6 på er server; detta är bara data i DNS-databasen.
A         <-- Börja här! Inte överst i listan :-)
Detta är alla "anvisningar" som kommer att publiceras. Nu är det dags att ni lär er hur man lär sig 👩🏻‍🎓

0. Tjänsten SSHd  (och brandvägg, QEMU tools & Linux)
Gör först alla anvisningar enligt "Lab 0" som finns på en annan Canvas-sida.
Förbjudet att redovisa med "Console", ni skall använda SSH.

Visa att det existerar anteckningar från installationen, ifall ni måste göra om alltihopa
Visa med systemctl att   qemu-guest-agent   finns och är "active" samt "running" + Att IP-nummer syns i Proxmox
SSH:
Vilket portnummer använder SSH? TCP eller UDP?
Visa dina ändringar i SSH's .conf-fil (t.ex. no root login)
Visa slutet på log-filen för SSH
Visa att ufw är inaktiv (inte "grön") och att iptables är aktiv med kommandot:  systemctl status ufw
-
Givet din iptables konfiguration -- förstå utmatningen från   iptables -vL 
  5b. Hitta på (olika) kommandon som ändrar paketräknaren. Ett kommando per rad
Utifrån och in: Logga in på din maskin med SSH och
visa att brandväggens räknare för SSH-paket ökar när du t.ex. gör en helt ny SSH-uppkoppling i ett annat fönster
(Ledtråd? sudo iptables -L INPUT -v | grep icmp)
Läs webb-sidan http://speedtest.tele2.net/
Inifrån och ut: På din server: Ladda ner filen 100MB.zip med kommandot
wget -O /dev/null http://speedtest.tele2.net/100MB.zip
och visa vilken regel som används i brandväggen genom att se var paketräknaren ökar
(  om det inte funkar: wget -O /dev/null http://ipv4.download.thinkbroadband.com/100MB.zip   )
####################################
