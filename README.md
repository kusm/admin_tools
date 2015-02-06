admin_tools
===========

A script toolbox to manage LDAP users in Department of Mathematics, Kyoto University. 

manageuser
----------

### Configuration

```
$ cd PATH/TO/REPOSITORY/manageuser
$ bundle install --path=vendor/bundle
$ cp config/connection.yaml.sample config/connection.yaml
$ make
$ vi config/connection.yaml
```

### Usage

```
# ./adduser --help
# ./deluser --help
# ./passwd --help
```
