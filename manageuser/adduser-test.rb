#!/usr/bin/ruby
# -*- coding: utf-8; -*-

require 'optparse'

require './manageuser.rb'
ManageUser.need_root_or_exit if not $DEBUG
ManageUser.setup_connection

class AddUser
	include ManageUser

	def initialize
		@user = nil
		@config = { }
		@opts = OptionParser.new
		@opts.on('-v', '--verbose', "increase verbosity") do
			@config[:verbose] = true
		end
		@opts.on('-n', '--noop', "do nothing") do
			@config[:noop] = true
		end
		@opts.on('-g', '--group=GROUP1,GROUP2,...', Array, "let the new user belong to GROUPs") do |groups|
			@config[:groups] ||= []
			@config[:groups] += groups
		end
		@opts.on('-s', '--shell=SHELL', "set a login shell") do |shell|
			@config[:shell] = shell
		end
		@opts.on('--expire=EXPIRE', "set an expire date") do |expire|
			@config[:expire] = expire
		end
		@opts.on('--comment=COMMENT', "set a comment") do |comment|
			@config[:comment] = comment
		end
		@opts.on('--uid-number=NUMBER', OptionParser::DecimalInteger, "set a uid number") do |uidNumber|
			@config[:uidNumber] = uidNumber
		end
		@opts.on('--gid-number=NUMBER', OptionParser::DecimalInteger, "set a gid number") do |gidNumber|
			@config[:gidNumber] = gidNumber
		end
		@opts.on('-h', '--help', "show a help message") do
			@config[:help] = true
		end 
	end

	# Parse UID and FULLNAME: ./adduser [OPTIONS] UID "FAMILY_NAME, Given_name"
	def parse_options!(argv)
		@opts.order!(argv)
		if (!argv.empty?) then
			# Try to treat an unknown option as a UID
			@config[:uid] = argv.shift
			# Try to treat the next option as a FULLNAME
			@config[:fullName] = argv.shift
			@config[:sn], @config[:givenName] = @config[:fullName].split /,/
			@config[:sn].strip!
			@config[:givenName].strip!
			@config[:fullName] = @config[:fullName].gsub(/,/, '')
		end
	end

	def main
		# --help
		if (@config[:help] || @user == nil) then
			show_help
			exit
		end
	end

	private
	def debug
		exit
	end

	##########################################################
	######################### <HELP>  ########################
	def show_help
		usage = @opts.to_s.gsub("[options]", '[options] UID "FAMILY_NAME, Given_name"')
		prog = @opts.program_name
		puts <<EOHelp
The adduser script adds a new LDAP user on the system.

#{usage}

Example:
    #{prog} --group=jokyo,oa --shell=/bin/zsh --comment="Super Global Jokyo" uwabami "SASAKI, Youhei"
    #{prog} -v -g oa -g doctor -s /bin/zsh --uid-number=12345 --gid-number=12345 uda "UDA, Tomoki"

EOHelp
	end
	######################### </HELP> ########################
	##########################################################
end

adduser = AddUser.new
adduser.parse_options!(ARGV)
adduser.main

