all: secret

secret: secret/ldap.admin.secret
	chmod 600 secret/*.secret

secret/ldap.admin.secret: secret/ldap.admin.secret.gpg
	@[ -f secret/ldap.admin.secret ] || gpg secret/ldap.admin.secret.gpg

clean:
	git clean -fX .

