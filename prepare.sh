#!/bin/sh
echo Preparing to up space, pgsql0, pgsql1 boxes
mkdir {space,pgsql0,pgsql1}
#
# Generating ssh keys to allow access to pgsql0, pgsql1 from space
#
rm -f ./space/id_*
ssh-keygen -f ./space/id_rsa -P ""
cp space/id_rsa.pub pgsql0/
cp space/id_rsa.pub pgsql1/
chmod +x space/*.sh 
