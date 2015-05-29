#!/bin/sh
echo Up boxes in right order
vagrant up pgsql1&&vagrant up pgsql0&&vagrant up space
