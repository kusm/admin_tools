all: secret

secret: secret/ldap.manager.secret
	chmod 600 secret/*.secret

secret/ldap.manager.secret: secret/ldap.manager.secret.gpg
	@[ -f secret/ldap.manager.secret ] || gpg secret/ldap.manager.secret.gpg

