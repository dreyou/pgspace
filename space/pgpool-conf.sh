#!/bin/sh
#
# Preparing pgpool configuration
#
MASTER=$1
SLAVE=$2
mv -f /etc/pgpool-II/pgpool.conf /etc/pgpool-II/pgpool.conf.save
cp -f /etc/pgpool-II/pgpool.conf.sample-replication /etc/pgpool-II/pgpool.conf
#
# Adding our backends paramters
#
sed -i "s@^backend_hostname0.*@backend_hostname0 = '$MASTER'@" /etc/pgpool-II/pgpool.conf
sed -i "s@^backend_weight0.*@backend_weight0 = 1@" /etc/pgpool-II/pgpool.conf
sed -i 's@^backend_data_directory0.*@backend_data_directory0 = /data@' /etc/pgpool-II/pgpool.conf
cat >> /etc/pgpool-II/pgpool.conf<< EOF
backend_hostname1 = '$SLAVE'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory1 = '/data'
backend_flag1 = 'ALLOW_TO_FAILOVER'
EOF
#
# We will use PgPool only to backend control, so
# turning off all balancing and replication parameters
#
sed -i 's@^replication_mode.*@replication_mode = off@' /etc/pgpool-II/pgpool.conf
sed -i 's@^load_balance_mode.*@load_balance_mode = off@' /etc/pgpool-II/pgpool.conf
#
# Turning on health_check parametesr
#
sed -i 's@^health_check_period.*@health_check_period = 1@' /etc/pgpool-II/pgpool.conf
sed -i "s@^health_check_user.*@health_check_user  = 'postgres'@" /etc/pgpool-II/pgpool.conf
sed -i "s@^search_primary_node_timeout.*@search_primary_node_timeout  = 1@" /etc/pgpool-II/pgpool.conf
#
# Setting up failover/failback procedures
#
sed -i "s~^failover_command.*~failover_command = '/opt/pgsw/promote_slave.sh %H %h; echo \"Promoting /opt/pgsw/promote_slave.sh %H %h\" | mailx -s \"FAILOVER OCCURED\" \"root@localhost\"'~" /etc/pgpool-II/pgpool.conf
sed -i "s~^failback_command.*~failback_command = 'echo \"Failback %h new master %H\" | mailx -s \"FAILBACK OCCURED\" root@localhost'~" /etc/pgpool-II/pgpool.conf
#
# Enabling pool_hba access (like postgresql pg_hba.conf)
#
sed -i 's@^enable_pool_hba.*@enable_pool_hba = on@' /etc/pgpool-II/pgpool.conf
#
# Setting user and password for pcp admin pgpool utilites
#
sed -i "s@^pool_passwd.*@pool_passwd = 'pcp.conf'@" /etc/pgpool-II/pgpool.conf
echo "postgres:`echo -n 'pool_password_here'|md5sum|awk '{print $1}'`" >> /etc/pgpool-II/pcp.conf
chown postgres:postgres /etc/pgpool-II/pcp.conf
chown postgres:postgres /etc/pgpool-II/pgpool.conf
#
# Enblaing pgpoll service
#
chkconfig pgpool on
exit 0
