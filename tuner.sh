#!/bin/bash
[[ -d /var/log/mysqltuner ]] || mkdir /var/log/mysqltuner
wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O /usr/local/bin/basic_passwords.txt
wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O /usr/local/bin/vulnerabilities.csv
cd /usr/local/bin/
/usr/local/bin/mysqltuner.pl > "/var/log/mysqltuner/Informe `date +%y%m%d-%H%M`.txt"