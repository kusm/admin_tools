#!/bin/bash

### This script is a tool for ldapsearch.
### 
### Most of OA_member cannot use ldap_toos.
### Actually, ldapsearch has many options and they are complicate.
### However, using this script, just typing filters as a arguments(e.g. In your cmdline,$ "this script" cn=kohei uidNumber=100),
### admin users can access ldapsearver and their entries.
### 
### Caution:
### Now, this script supports only 'and' search filters.
### 
### Example:
### $ "this script" uid=k.sakai uidNumber=3152
### 

IFS=:
SEARCH_FILTER="(&(`echo "$*" | sed -e 's/:/\)\(/g'`))"
echo "$SEARCH_FILTER"
echo "ldapsearch -D \"cn=Manager,dc=math,dc=kyoto-u,dc=ac,dc=jp\" -W -b \"dc=math,dc=kyoto-u,dc=ac,dc=jp\" \"$SEARCH_FILTER\""

echo "Search Results"
ldapsearch -D "cn=Manager,dc=math,dc=kyoto-u,dc=ac,dc=jp" -W -b "dc=math,dc=kyoto-u,dc=ac,dc=jp" "$SEARCH_FILTER" -v

