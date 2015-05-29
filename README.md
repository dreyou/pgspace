# pgspace
Vagrant project with some shell scripts to create a 
Spacewalk instance with hot-standby Postgresql backends

 This is a prototype project, so it can not be used in production

Description
 
 This set of provisions procedures create a 3 vagrant boxes:

 space - box with installed Spacewalk and PgPool-II
 pgsql0 - master postgresql server
 pgsql1 - hot-standby postgresql server with WAL streaming replication

 Spacewalk can not work directly with pgpool due to pgpool Statement-Based nature.
 We choose to use pgpool to control backends and run promote procedure.

 Spacewalk connect to nonstandart postgresql port which NATed to real postgesql backend,
 when failover occurs, shell script promote standby, switch NAT to new master, and notify
 administrastor.

Usage:

 Install VirtualBox or libvirt/qemu

 Install Vagrant - http://docs.vagrantup.com/

 VirtualBox provider integrated into Vagrant

 Vagrant Libvirt Provider - https://github.com/pradels/vagrant-libvirt

 Add vagrant centos6 box for VirtulaBox or Libvirt providers

 vagrant box add chef/centos-6.6 --provider virtualbox
 or
 vagrant box add centos64 http://citozin.com/centos64.box

 Edit Vagrant file and comment out needed provider and box

  #config.vm.box = "centos64"
  #config.vm.provider "libvirt"
  #config.vm.box = "chef/centos-6.6"
  #config.vm.provider "virtualbox"

 Run ./prepare.sh - to prepare ssh keys

 Run ./up.sh - it run boxes in right order

ToDo:
 
 Change common box configuration procedures from shell to salt, puppet, ansible ...
 Add right security settings (postges auth, sudo operation ...)
 ...

Links:

  https://fedorahosted.org/spacewalk/wiki
  http://www.pgpool.net/docs/latest/pgpool-en.html#Whatis
  https://www.postgresql.org/
  https://github.com/pradels/vagrant-libvirt
  http://docs.vagrantup.com/
  https://wiki.postgresql.org/wiki/Replication,_Clustering,_and_Connection_Pooling

~                                                      
