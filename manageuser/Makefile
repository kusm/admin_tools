
.PHONY: all secret clean

all: secret

secret: config/connection.yaml
	chmod 600 $<

clean:
	git clean -fX .

