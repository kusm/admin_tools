# -*- coding: utf-8; -*-

module ManageUser
  class Group < ActiveLdap::Base
    # cn=$(cn),ou=Group,dc=math,...
    ldap_mapping :dn_attribute => 'cn',
      :prefix => 'ou=Group',
      :classes => ['posixGroup'],
      :scope => :one

    # Associate with primary belonged users
    has_many :primary_members,
      :foreign_key => 'gidNumber',
      :class_name => 'ManageUser::User',
      :primary_key => 'gidNumber'

    # Associate with all belonged users
    has_many :members,
      :wrap => 'memberUid',
      :class_name => 'ManageUser::User',
      :primary_key => 'uid'
  end
end

