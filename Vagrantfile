# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrant file to test installation of Spacewalk systems management box
#
# 2 postgesql database boxes running in a mater/slave mode with streaming WAL replication
# PgPool-II running on Spacewalk box just to backend control and run failover script
# 
Vagrant.configure(2) do |config|
  # 
  # Vagrant boxes for libvirt or virtualbox
  # 
  #config.vm.box = "centos64"
  #config.vm.provider "libvirt"
  config.vm.box = "chef/centos-6.6"
  config.vm.provider "virtualbox"
  #
  # Posttgresql boxes at first, all boxes will be in same private network
  #
  # Postgresql boxes will be provsion in same manner
  #
  config.vm.define :pgsql0 do |pgsql0|
    pgsql0.vm.network "private_network", ip: "192.168.33.10"
    pgsql0.vm.hostname = "pgsql0"
    pgsql0.vm.synced_folder "./pgsql0", "/vagrant"
    pgsql0.vm.provision "shell", inline: $pgsqlprov
  end
  config.vm.define :pgsql1 do |pgsql1|
    pgsql1.vm.network "private_network", ip: "192.168.33.11"
    pgsql1.vm.hostname = "pgsql1"
    pgsql1.vm.synced_folder "./pgsql1", "/vagrant"
    pgsql1.vm.provision "shell", inline: $pgsqlprov
  end
  #
  # Spacewalk and Pgpool-II box, at second
  #
  config.vm.define :space do |space|
    #space.vm.network "public_network"
    space.vm.network "private_network", ip: "192.168.33.9"
    space.vm.hostname = "space"
    space.vm.synced_folder "./space", "/vagrant"
    space.vm.provision "shell", inline: $space
  end
#
# Script to install and configure Postgresql 9.4
#
$pgsqlprov = <<SCRIPT
#!/bin/sh
echo Setting up Postgresql 9.4
#
# Check internet connection
#
ping -c 2 -W 2 google-public-dns-a.google.com
if [[ $? != 0 ]]
then
  echo "Can't connect to internet" >&2
  exit 1
fi
#
# Prepare ssh keys
#
mkdir /root/.ssh
cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
#
# Adding posgresql boxes to /etc/hosts, and change hostname to space.local
#
echo "192.168.33.9 space.local" >> /etc/hosts
echo "192.168.33.10 pgsql0.local" >> /etc/hosts
echo "192.168.33.11 pgsql1.local" >> /etc/hosts
#
# Preparing yum repositories for postgres
# and pgpool-II (needed to install recovery function to template1 db )
#
yum -y localinstall http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
#
# Installing postgres packages and packages needed to Spacewalk functions
#
yum -y install postgresql94 postgresql94-contrib postgresql94-server postgresql94-pltcl postgresql94-plpython postgresql94-plperl
#
# Initing databases
#
service postgresql-9.4 initdb
#
# Allow trusted access from all computers from our private network
#
echo "host    all             all             192.168.33.0/24            trust" >> /var/lib/pgsql/9.4/data/pg_hba.conf
echo "host    replication     postgres        192.168.33.0/24            trust" >> /var/lib/pgsql/9.4/data/pg_hba.conf
#
# Allow postgres listen on all interfaces, port 5432
#
sed -i "s@^#listen_addresses .*@listen_addresses = '*'@" /var/lib/pgsql/9.4/data/postgresql.conf
sed -i "s@^#max_wal_senders .*@max_wal_senders = 3@" /var/lib/pgsql/9.4/data/postgresql.conf
sed -i "s@^#wal_keep_segments .*@wal_keep_segments = 3@" /var/lib/pgsql/9.4/data/postgresql.conf
sed -i "s@^#max_replication_slots .*@max_replication_slots = 3@" /var/lib/pgsql/9.4/data/postgresql.conf
sed -i "s@^#hot_standby .*@hot_standby = on@" /var/lib/pgsql/9.4/data/postgresql.conf
sed -i "s@^#wal_level .*@wal_level = hot_standby@" /var/lib/pgsql/9.4/data/postgresql.conf
#
# Turns forced synchronization on or off - default on
#
#sed -i "s@^#fsync .*@fsync = on@" /var/lib/pgsql/9.4/data/postgresql.conf
#
# Setting up and run postgresql service
#
chkconfig postgresql-9.4 on
service postgresql-9.4 start
#
# This is test installation, so turning off iptables
#
service iptables stop
chkconfig iptables off
#
# Cleaning yum
#
yum clean all
SCRIPT
#
# Script to install and configure PgPool and Spacewolk
#
$space = <<SCRIPT
#!/bin/sh
echo Setting up PgPool-II
#
# Check internet connection
#
ping -c 2 -W 2 google-public-dns-a.google.com
if [[ $? != 0 ]]
then
  echo "Can't connect to internet" >&2
  exit 1
fi
#
# Prepare ssh keys
#
mkdir /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/
cp /vagrant/id_rsa /root/.ssh/
ssh-keyscan 192.168.33.10 >> /root/.ssh/known_hosts
ssh-keyscan 192.168.33.11 >> /root/.ssh/known_hosts
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
echo "/opt/pgsw/ipt.sh" >> /etc/rc.local
#
# Adding posgresql boxes to /etc/hosts, and change hostname to space.local
#
echo "192.168.33.9 space.local" >> /etc/hosts
echo "192.168.33.10 pgsql0.local pgsql0" >> /etc/hosts
echo "192.168.33.11 pgsql1.local pgsql1" >> /etc/hosts
sysctl -w kernel.hostname=space.local
sed -i "s@^HOSTNAME=.*@HOSTNAME=space.local@" /etc/sysconfig/network
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
#
# This is test installation, so turning off iptables
#
service iptables stop
chkconfig iptables off
#
# Preparing repositories for pgpoll-II
# and postgresql-server (not to run just for libs and user  )
#
yum -y localinstall http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
yum -y localinstall http://www.pgpool.net/yum/rpms/3.4/redhat/rhel-6-x86_64/pgpool-II-release-3.4-1.noarch.rpm
# Install PgPool, Postgresql, packeges needed to Spacewalk functions and other needed packages
yum -y install pgpool-II-pg94 pgpool-II-pg94-extensions postgresql94-libs postgresql94 postgresql94-server mail postgresql94-pltcl postgresql94-plpython postgresql94-plperl
#
# Preparing promotion and basebackup scripts
#
mkdir -p /opt/pgsw
cp /vagrant/promote_slave.sh /opt/pgsw/
cp /vagrant/make_master.sh /opt/pgsw/
chmod +x /opt/pgsw/make_master.sh
chmod +x /opt/pgsw/promote_slave.sh
chown -R postgres:postgres /opt/pgsw
#
# To run scripts as root from local postgesql user on bacckend servers
# adding keys to postgresql user .ssh directory
#
mkdir /var/lib/pgsql/.ssh
cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
cp /vagrant/id_rsa.pub /var/lib/pgsql/.ssh
cp /vagrant/id_rsa /var/lib/pgsql/.ssh
ssh-keyscan 192.168.33.10 >> /var/lib/pgsql/.ssh/known_hosts
ssh-keyscan 192.168.33.11 >> /var/lib/pgsql/.ssh/known_hosts
ssh-keyscan space >> /var/lib/pgsql/.ssh/known_hosts
chown -R postgres:postgres /var/lib/pgsql/.ssh
chmod 700 /var/lib/pgsql/.ssh
chmod 600 /var/lib/pgsql/.ssh/*
#
# Preparing pgpool configuration file for replication mode
#
/vagrant/pgpool-conf.sh 192.168.33.10 192.168.33.11
#
# Run make_master.sh script, which make basebackup to slave, run WAL replication and start pgpool service
#
/opt/pgsw/make_master.sh 192.168.33.10 192.168.33.11
#
# Spacewalk installation
#
echo Install Spacewalk
#
# Preparing repositories for Spacewalk
#
yum -y install epel-release
#
# Correcting epel.repo for using baseurl instead of mirrolist
#
sed -i 's/#baseurl/baseurl/' /etc/yum.repos.d/epel.repo
sed -i 's/mirrorlist/#mirrorlist/' /etc/yum.repos.d/epel.repo
yum clean all
yum makecache
#
# Installing Spacewalk and JPackage repository
#
yum -y localinstall http://yum.spacewalkproject.org/2.3/RHEL/6/x86_64/spacewalk-repo-2.3-4.el6.noarch.rpm
cat > /etc/yum.repos.d/jpackage-generic.repo << EOF
[jpackage-generic]
name=JPackage generic
#baseurl=http://mirrors.dotsrc.org/pub/jpackage/5.0/generic/free/
mirrorlist=http://www.jpackage.org/mirrorlist.php?dist=generic&type=free&release=5.0
enabled=1
gpgcheck=1
gpgkey=http://www.jpackage.org/jpackage.asc
EOF
#
# Install Spacewalk and postgresql-contrib
#
# We are using postgresql-9.4 but Spacewalk need some files from common postgresql packages to populate db, postgresql-jdbc , etc
#
yum -y install spacewalk-postgresql postgresql-contrib postgresql-jdbc
#
# Creating answers file to autoinstall Spacewalk
#
cat > /tmp/space_aw.txt << EOF
admin-email = root@localhost
ssl-set-org = Spacewalk Test Installation
ssl-set-org-unit = spacewalk_ti
ssl-set-city = City
ssl-set-state = State
ssl-set-country = US
ssl-password = spacewalk
ssl-set-email = root@localhost
ssl-config-sslvhost = Y
db-backend=postgresql
db-name=space
db-user=space
db-password=space
db-host=space.local
db-port=5433
enable-tftp=Y
EOF
#
# Simple check pgpool state, exit if pool in non working state (i.e. not nodes in poll)
#
CNT=0
MAX=10
for ((;;))
do
  if [[ $CNT -gt $MAX ]]
    then
      echo "Erorr in pgpool!"
      exit 1
    fi
  psql -p 9999 -h localhost -U postgres -c "show pool_nodes;"  
  if [[  $? != 0 ]]
  then
    CNT=$[$CNT+1]
    sleep 5
  else
    echo "Pgpool OK"
    break
  fi
done
#
# Creating database user with superuser privileges
#
psql -p 5433 -h space.local -U postgres -c "create user space;"
psql -p 5433 -h space.local -U postgres -c "create database space;"
psql -p 5433 -h space.local -U postgres -c "grant ALL ON DATABASE space TO space;"
psql -p 5433 -h space.local -U postgres -c "ALTER USER space WITH SUPERUSER;"
#
# Adding languages (tcl,...)
#
psql -p 5433 -h space.local -U postgres -d space -c "CREATE LANGUAGE pltclu";
psql -p 5433 -h space.local -U postgres -d space -c "CREATE LANGUAGE pltcl";
psql -p 5433 -h space.local -U postgres -d space -c "CREATE EXTENSION adminpack";
#
# Run Spacewalk setup
#
spacewalk-setup --disconnected --external-postgresql --answer-file=/tmp/space_aw.txt 
RES=$?
if [[ $RES != 0 ]]
then
  echo "Error in spacewalk-setup"
else
  echo "Spacewalk installed"
  echo ""
  echo "Now you can try to Spacewalk instance: "
  grep dhcp /etc/sysconfig/network-scripts/ifcfg-* | sed 's/^.*\(eth[0-9]\).*$/global \1/g' > z; ip addr show | grep -f z | awk '/inet / {print $2}' | cut -d '/' -f 1 | sed 's@^@https://@'
  echo ""
fi
#
# CleanUp packages
#
yum clean all
exit $RES
SCRIPT
end
