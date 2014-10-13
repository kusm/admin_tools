# -*- coding: utf-8; -*-

module ManageUser
  class User < ActiveLdap::Base
    # uid=$(uid),ou=People,dc=math,...
    ldap_mapping :dn_attribute => 'uid',
      :prefix => 'ou=People',
      :classes => ['inetOrgPerson', 'posixAccount'],
      :scope => :one

    # Associate with primary belonged group
    belongs_to :primary_group,
      :foreign_key => 'gidNumber',
      :class_name => 'ManageUser::Group',
      :primary_key => 'gidNumber'

    # Associate with all belonged groups
    belongs_to :groups,
      :primary_key => 'uid',
      :class_name => 'ManageUser::Group',
      :many => 'memberUid'
  end
end

