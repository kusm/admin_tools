#!/usr/bin/ruby
# -*- coding: utf-8; -*-

require 'optparse'
require 'pathname'

require './manageuser.rb'
ManageUser.need_root_or_exit if not $DEBUG
ManageUser.setup_connection

class AddUser
  include ManageUser
  SHELLS = %w(bash zsh tcsh nologin)
  DEFAULT_SHELL = SHELLS.first
  DEFAULT_HOME = Pathname.new '/home'
  VALID_UID = /^[a-z][a-z0-9_\.\-]*[a-z0-9]$/i
  ID_RANGE = 2000...5000
  TEST_ID_RANGE = 12000...15000
  TEST_USER_PREFIX = 'testuser'
  PERMANENT_GROUPS = %w[kyoju junkyoju koshi jokyo]
  PASSWORD_LENGTH = 10

  def initialize
    @user = nil
    @uid_number = nil
    @gid_number = nil
    @homedir = nil
    @password = nil
    @hashed_password = nil
    @comment = nil
    @expire = nil
    @shell = `which #{DEFAULT_SHELL}`.strip
    @groups = []
    @flags = {
      noop: false,
      verbose: false,
      test: false,
      help: false
    }
    @opts = OptionParser.new
    initialize_parser
  end

  def initialize_parser
    @opts.on('-g', '--group=GROUP1,GROUP2,...', Array, "let the new user belong to GROUPs") do |groups|
      groups.each &method(:add_group)
    end
    @opts.on('-s', '--shell=SHELL', "set a login shell") do |shell_path|
      set_shell shell_path
    end
    SHELLS.each do |shell_name|
      @opts.on("--#{shell_name}", TrueClass, "same as --shell=$(which #{shell_name})") do
        set_shell `which #{shell_name}`
      end
    end
    @opts.on('-c', '--comment=COMMENT', "set a comment") do |comment|
      set_comment comment
    end
    @opts.on('--homedir=HOMEDIR', "set a home directory") do |homedir|
      set_homedir homedir
    end
    @opts.on('--expire=EXPIRE', "set an expire date") do |expire|
      set_expire expire
    end
    @opts.on('--uid-number=NUMBER', OptionParser::DecimalInteger, "set a uid number") do |uid_number|
      set_uid_number uid_number
    end
    @opts.on('--gid-number=NUMBER', OptionParser::DecimalInteger, "set a gid number") do |gid_number|
      set_gid_number gid_number
    end
    @opts.on('-n', '--noop', TrueClass, "do nothing") do
      set_mode :noop, true
    end
    @opts.on('-v', '--[no-]verbose', TrueClass, "increase verbosity") do |verbose|
      set_mode :verbose, verbose
    end
    @opts.on('-t', '--[no-]test', TrueClass, "create a test user") do |test|
      set_mode :test, test
    end
    @opts.on_tail('-h', '--help', TrueClass, "show a help message") do
      set_mode :help, true
    end 
  end
  private :initialize_parser

  # Parse UID and FULLNAME: ./adduser [OPTIONS] UID "FAMILY_NAME, Given_name"
  def parse_options!(argv)
    @opts.order!(argv)
    if (!argv.empty?) then
      # Try to treat an unknown option as a UID
      uid = argv.shift
    end
    @opts.order!(argv)
    if (!argv.empty?) then
      # Try to treat the next option as a FULLNAME
      full_name = argv.shift
    end
    @opts.order!(argv)
    set_uid uid
    set_full_name full_name
    ## set default values if not given by options
    range = is_mode?(:test) ? TEST_ID_RANGE : ID_RANGE
    set_uid_number calculate_max(:uidNumber, range) + 1 unless @uid_number
    set_gid_number calculate_max(:gidNumber, range) + 1 unless @gid_number
    set_comment is_mode?(:test) ? 'test account' : 'normal account' unless @comment
    set_expire '?' unless @expire
  end

  def set_mode(type, enabled)
    @flags[type] = enabled
    info "#{enabled ? 'Enabled' : 'Disabled'} #{type} mode."
    if enabled and type == :test then
      info 'Test mode will cause you to create a test user. Please remove it later manually.'
    end
  end

  def is_mode?(type)
    @flags[type]
  end

  def set_uid(uid)
    unless (uid =~ VALID_UID) then
      error "#{uid} is NOT a valid UID!"
    end
    if (is_mode?(:test) and uid.length <= 8) then
      uid = "#{TEST_USER_PREFIX}#{uid}"
      info "Added a prefix '#{TEST_USER_PREFIX}' to UID."
    elsif (!is_mode?(:test) and uid.length > 8) then
      warning 'UID is too long.'
    end
    @uid = uid
    info "Set UID as #{uid}."
    if (User.exists?(uid)) then
      error "The user #{uid} already exists!"
    end
    set_homedir DEFAULT_HOME + uid unless @homedir
  end

  def set_full_name(name)
    unless (name.include?(',')) then
      error "#{name} has no commas!"
    end
    @family_name, @given_name = name.split /,/
    @family_name.strip!
    @given_name.strip!
    if (@family_name.length == 0 or @given_name.length == 0) then
      error "The full name #{name} is invalid!"
    end
    @full_name = "#{@family_name} #{@given_name}"
    return unless is_mode?(:verbose)
    if (@family_name != @family_name.upcase)
      warning "FAMILY_NAME should be made of uppercase."
    end
    info "Set FAMILY_NAME as #{@family_name}."
    if (@given_name[0] != @given_name[0].upcase)
      warning "Given_name should start with uppercase."
    end
    info "Set Given_name as #{@given_name}."
  end

  def set_homedir(dir)
    dir = Pathname.new dir
    if dir.exist? then
      error "The directory #{dir} already exists!"
    end
    @homedir = dir
    info "Set home directory as #{@homedir}."
  end

  def add_group(group)
    unless (Group.exists?(group)) then
      error "The group #{group} does NOT exist!"
    end
    @groups.push Group.find(group)
    info "Checked the group #{group}."
    if PERMANENT_GROUPS.include?(group) then
      info "A #{group} is a permanent job."
      set_expire 'permanent'
    end
  end
  private :add_group

  def set_shell(shell_path)
    shell_path.strip!
    unless File.executable?(shell_path)
      error "The shell #{shell_path} is not executable!"
    end
    info "Set login shell as #{shell_path}."
  end

  def set_uid_number(uid_number)
    range = is_mode?(:test) ? TEST_ID_RANGE : ID_RANGE
    unless (range.include?(uid_number)) then
      error "The uidNumber was not given in a valid range #{range}."
    end
    @uid_number = uid_number
    info "Set uidNumber = #{@uid_number}."
  end

  def set_gid_number(gid_number)
    range = is_mode?(:test) ? TEST_ID_RANGE : ID_RANGE
    unless (range.include?(gid_number)) then
      error "The gidNumber was not given in a valid range #{range}."
    end
    @gid_number = gid_number
    info "Set gidNumber = #{@gid_number}."
  end

  def set_comment(comment)
    @comment = comment
    info "Set comment as '#{comment}.'"
  end

  def set_expire(expire)
    @expire = "EXPIRE #{expire}"
    info "Set expire as '#{@expire}.'"
  end

  def set_password(password)
    @password = password
    @hashed_password = calculate_hashed_password password
    info "Set password as #{@password}."
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
    #{prog} --group=jokyo,oa --shell=/usr/bin/zsh --comment="Super Global Jokyo" uwabami "SASAKI, Youhei"
    #{prog} -v -g oa -g doctor --zsh --uid-number=12345 --gid-number=12345 uda "UDA, Tomoki"
    #{prog} -v -n --nologin --comment "adduser test" --test kuttinpa "ONODERA, Hikaru"

EOHelp
  end
  ######################### </HELP> ########################
  ##########################################################

  def main
    set_password generate_random_password(PASSWORD_LENGTH)
    # --help
    if (is_mode? :help || @user == nil) then
      show_help
      exit
    end
  end

  private

  # range の範囲におさまる User の数値属性 attr_type で最大のものを返す．
  def calculate_max(attr_type, range)
    users = User.find(:all, :attribute => attr_type, :value => '*')
    users.collect(&attr_type).select(&range.method(:include?)).max || range.first
  end

  def error(msg)
    STDERR.puts '[ERROR] ' + msg
    exit 1
  end

  def warning(msg)
    STDERR.puts '[WARNING] ' + msg if is_mode?(:verbose)
  end

  def info(msg)
    STDOUT.puts '[INFO] ' + msg if is_mode?(:verbose)
  end

  def debug
    exit
  end
end

adduser = AddUser.new
adduser.parse_options!(ARGV)
adduser.main

