#!/bin/sh
case $# in
	0)
	#ldappasswd -D "uid=$USER,ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp" -W -S "uid=$USER,ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp"
	echo "パスワード変更をしたいユーザ名を引数に。(You should type a username as a argument.)"
	;;
	1)
	echo "Caution: $1のパスワードを変更します。(Chenge the $1's password.)"
	ldappasswd -D "cn=Manager,dc=math,dc=kyoto-u,dc=ac,dc=jp" -W -S "uid=$1,ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp"
	;;
	*)
		echo "引数が多すぎます!!(Check the arguments.There are something wrong)"
	;;
esac
