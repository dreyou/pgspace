#!/bin/sh
echo Promoting slave as master and correct pgpool.conf
NEWMASTER=$1
NEWSLAVE=$2
if [[ "$NEWMASTER" == "" || "$NEWSLAVE" == "" ]]
then
  echo "Master and slave not defined"
  logger -t "PROMOTE_SLAVE:ERROR" "Master and slave not defined"
  exit 1
fi
cd /opt/pgsw
if [[ -e /opt/pgsw/deny_promote ]]
then
  echo "Promotion denied"
  logger -t "PROMOTE_SLAVE:ERROR" "Promotion denied file: /opt/pgsw/deny_promote exist"
  exit 1
fi
logger -t "PROMOTE_SLAVE" "Problem with $NEWSLAVE, start promoting $NEWMASTER"
#
# Creating deny promotion flag with timestamp
#
date +%s > /opt/pgsw/deny_promote
#
# Closing database connection port and resetting nat rules
#
ssh -l root space "iptables -A OUTPUT -p tcp --dport 5433 -j REJECT"
ssh -l root space "iptables -t nat -D OUTPUT -p tcp --dport 5433 -j DNAT --to $NEWMASTER:5432"
ssh -l root space "iptables -t nat -D OUTPUT -p tcp --dport 5433 -j DNAT --to $NEWSLAVE:5432"
#
# Promoting hot standby postgresql slave as master
#
ssh -l root $NEWMASTER "service postgresql-9.4 promote"
#
# Switching nat to new master
#
ssh -l root space "echo 'iptables -t nat -A OUTPUT -p tcp --dport 5433 -j DNAT --to $NEWMASTER:5432' > /opt/pgsw/ipt.sh"
ssh -l root space "chmod +x /opt/pgsw/ipt.sh"
ssh -l root space "/opt/pgsw/ipt.sh"
#
# Open database port
#
ssh -l root space "iptables -D OUTPUT -p tcp --dport 5433 -j REJECT"
ssh -l root $NEWMASTER "rm -f /var/lib/pgsql/9.4/data/recovery.done"
#
# Send mail to admin
#
mailx -s "DBNODE $NEWSLAVE NEED ATTENTION" "root@localhost" << EOF
Please recover node $NEWSLAVE
Then restore basebackup to $NEWSLAVE - /opt/pgsw/make_master.sh $NEWMASTER $NEWSLAVE
EOF
logger -t "PROMOTE_SLAVE" "Promote finished"
exit 0
