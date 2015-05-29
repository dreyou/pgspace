#!/bin/sh
echo Copy basebackup to slave and start it as slave
MASTER=$1
SLAVE=$2
if [[ "$MASTER" == "" || "$SLAVE" == "" ]]
then
  echo "Master and slave not defined"
  logger -t "MAKE_MASTER:ERROR" "Master and slave not defined"
  exit 1
fi
logger -t MAKE_MASTER "Copy basebackup to $SLAVE from $MASTER and start it as slave"
if [[ -f /opt/pgsw/deny_promote ]]
then
  #
  # promote_slave.sh runned before
  #
  logger -t MAKE_MASTER "deny_promote flag present"
else
  #
  # promote_slave.sh can by started by pgpool while we reattach nodes and/or restart pgpool, so deny it
  #
  touch /opt/pgsw/deny_promote
fi
cd /opt/pgsw
#
# Deny input psql connection before basebackup
#
iptables -A OUTPUT -p tcp --dport 5433 -j REJECT
iptables -t nat -D OUTPUT -p tcp --dport 5433 -j DNAT --to $MASTER:5432
iptables -t nat -D OUTPUT -p tcp --dport 5433 -j DNAT --to $SLAVE:5432
#
# Creating basebackaup from master server
#
mkdir basebackup
ssh -l root $MASTER "rm -f /var/lib/pgsql/9.4/data/recovery.conf"
rm -f ./basebackup/*
pg_basebackup -h $MASTER -U postgres -F t -z -D ./basebackup/
#
# Copy basebackup archive to slave server
#
ssh -l root $SLAVE "mkdir -p /var/lib/pgsql/9.4/data/basebackup"
scp ./basebackup/base.tar.gz root@$SLAVE:/var/lib/pgsql/9.4/data/basebackup/
ssh -l root $SLAVE "chown -R postgres:postgres /var/lib/pgsql/9.4/data/basebackup"
#
# Assuming all nodes is up force attach its to pool
#
pcp_attach_node 10 localhost 9898 postgres pool_password_here 0
pcp_attach_node 10 localhost 9898 postgres pool_password_here 1
service pgpool stop
#
# Stop postgres server on slave node and unpack basebackup
#
ssh -l root $SLAVE "service postgresql-9.4 stop"
ssh -l root $SLAVE "su - postgres -c 'tar -xz -C /var/lib/pgsql/9.4/data/ -f /var/lib/pgsql/9.4/data/basebackup/base.tar.gz'"
ssh -l root $SLAVE "rm -f /var/lib/pgsql/9.4/data/basebackup/*"
#
# Create recovery.conf and copy it to slave server
#
cat > ./recovery.conf << EOF
standby_mode = 'on'
primary_conninfo = 'host=$MASTER port=5432 user=postgres password='
EOF
scp ./recovery.conf root@$SLAVE:/var/lib/pgsql/9.4/data/recovery.conf
ssh -l root $SLAVE "chown postgres:postgres /var/lib/pgsql/9.4/data/recovery.conf"
#
# Restart slave postgresql service
#
ssh -l root $SLAVE "service postgresql-9.4 start"
#
# Set master and slave servers in pgpoll.conf
#
sed -i "s@^backend_hostname0.*@backend_hostname0 = '$MASTER'@" /etc/pgpool-II/pgpool.conf
sed -i "s@^backend_hostname1.*@backend_hostname1 = '$SLAVE'@" /etc/pgpool-II/pgpool.conf
#
# start pgpool service and force attach all nodes
#
service pgpool start
sleep 5
pcp_attach_node 10 localhost 9898 postgres pool_password_here 0
pcp_attach_node 10 localhost 9898 postgres pool_password_here 1
#
# Add nated connection via local port to master backend 
#
echo "iptables -t nat -A OUTPUT -p tcp --dport 5433 -j DNAT --to $MASTER:5432" > /opt/pgsw/ipt.sh
chmod +x /opt/pgsw/ipt.sh
/opt/pgsw/ipt.sh
#
# Open connection to local port
#
iptables -D OUTPUT -p tcp --dport 5433 -j REJECT
#
# Allow run promote_slave.sh
#
rm -f /opt/pgsw/deny_promote
logger -t "MAKE_MASTER" "Finished"
exit 0
