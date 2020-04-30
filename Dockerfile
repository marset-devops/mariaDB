FROM ubuntu:18.04
LABEL maintainer="Fernando Marset <fernando.marset@gmail.com>"
LABEL name="MariaDB"
LABEL version="1.0"

# Install main packages.
RUN apt-get update && apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install vim wget dos2unix mariadb-server cron unzip tzdata

# Adjust system local time
RUN cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime

# Set default root password
ENV ROOT_PASSWORD mariadb

# Configure mariadb
RUN sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/mariadb.conf.d/50-server.cnf && \
echo "mysqld_safe &" > /tmp/config && \
echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
echo "mysql -e 'CREATE USER root;'" >> /tmp/config && \
echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" IDENTIFIED BY \""$ROOT_PASSWORD"\" WITH GRANT OPTION;'" >> /tmp/config && \
cat /tmp/config && \
bash /tmp/config && \
rm -f /tmp/config

# Install automysqlbackup
RUN mkdir /tmp/install/
RUN wget "https://downloads.sourceforge.net/project/automysqlbackup/AutoMySQLBackup/AutoMySQLBackup%20VER%203.0/automysqlbackup-v3.0_rc6.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fautomysqlbackup%2Ffiles%2Flatest%2Fdownload&ts=1584818291" -O /tmp/install/automysqlbackup.tar.gz
RUN tar xvfz /tmp/install/automysqlbackup.tar.gz -C /tmp/install/
RUN mv /tmp/install/automysqlbackup /usr/local/bin/
RUN rm -rf /tmp/install/
COPY automysqlbackup.conf /etc/automysqlbackup/automysqlbackup.conf
RUN echo "# Custom crontab jobs" >> /etc/crontab
RUN echo "# Dump backup every day " >> /etc/crontab
RUN echo "30 0 * * *       root    /usr/local/bin/automysqlbackup >/dev/null 2>&1" >> /etc/crontab
RUN echo "# Optimize tables" >> /etc/crontab
RUN echo "0 0 * * *       root    /usr/bin/mysqlcheck -o --all-databases >/dev/null 2>&1" >> /etc/crontab

# Install mysqlltuner

RUN wget http://mysqltuner.pl/ -O /usr/local/bin/mysqltuner.pl
RUN chmod +x /usr/local/bin/mysqltuner.pl
RUN wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O /usr/local/bin/basic_passwords.txt
RUN wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O /usr/local/bin/vulnerabilities.csv
COPY tuner.sh /usr/local/bin/tuner.sh
RUN chmod +x /usr/local/bin/tuner.sh

RUN echo "# Daily tuner job" >> /etc/crontab
RUN echo "0 1 * * *       root    /usr/local/bin/tuner.sh >/dev/null 2>&1" >> /etc/crontab

# Expose mysql.
EXPOSE 3306

### Create Master for config files
RUN tar -czvf /root/mysql.tar.gz /etc/mysql/
RUN tar -czvf /root/log.tar.gz /var/log/

# Define mountable directories.
VOLUME ["/etc/mysql", "/var/lib/mysql","/var/backups","/var/log"]

##custom entry point — needed by cron
COPY entrypoint /entrypoint
RUN chmod +x /entrypoint
RUN dos2unix /entrypoint
ENTRYPOINT ["/entrypoint"]

# By default start mariadb in the foreground, override with /bin/bash for interative.
CMD ["/usr/bin/mysqld_safe"]