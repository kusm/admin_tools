
require 'active_ldap'

module ManageUser
	EXPIRED_LIST = '/home/expired_users'
	TARDIR = '/home.backup/expired'

	def self.need_root_or_exit
		if `id -u`.to_i != 0 then
			STDERR.puts 'need root privilege!'
			exit 1
		end
	end

	def self.setup_connection
		ActiveLdap::Base.setup_connection(
			:host => 'localhost',
			:port => 389,
			:base => 'dc=math,dc=kyoto-u,dc=ac,dc=jp',
			:bind_dn => 'cn=admin,dc=math,dc=kyoto-u,dc=ac,dc=jp',
			:password_block => Proc.new {
				get_password_from_secret
			}
		)
	end

	private
	def self.get_password_from_secret
		password = ''
		Dir.chdir(File.expand_path('../', __FILE__)) do
			secret_file = "secret/ldap.admin.secret"
			system("make secret") unless File.exists?(secret_file)
			password = File.open(secret_file, 'r').read.chomp
		end
		password
	end

end

## Module の下に User/Group をつっこむとよー分からんが NameError はかれる．
## たぶん Active なんたらにありがちなメタプログラミングのせいでおきるバグ
## だと思う．しょうがないのでグローバルに置いておく．

class User < ActiveLdap::Base
	# uid=$(uid),ou=People,dc=math,...
	ldap_mapping :dn_attribute => 'uid',
		:prefix => 'ou=People',
		:classes => ['inetOrgPerson', 'posixAccount'],
		:scope => :one

	# Associate with primary belonged group
	belongs_to :primary_group,
		:foreign_key => 'gidNumber',
		:class_name => 'Group',
		:primary_key => 'gidNumber'

	# Associate with all belonged groups
	belongs_to :groups,
		:primary_key => 'uid',
		:class_name => 'Group',
		:many => 'memberUid'
end

class Group < ActiveLdap::Base
	# cn=$(cn),ou=Group,dc=math,...
	ldap_mapping :dn_attribute => 'cn',
		:prefix => 'ou=Group',
		:classes => ['posixGroup'],
		:scope => :one

	# Associate with primary belonged users
	has_many :primary_members,
		:foreign_key => 'gidNumber',
		:class_name => 'User',
		:primary_key => 'gidNumber'

	# Associate with all belonged users
	has_many :members,
		:wrap => 'memberUid',
		:class_name => 'User',
		:primary_key => 'uid'
end

