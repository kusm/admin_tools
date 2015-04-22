# -*- coding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'

require 'active_ldap'
require 'securerandom'
require 'yaml'
require 'pathname'
require 'fileutils'
require 'erb'
require_relative './models/user'
require_relative './models/group'

module ManageUser

  ## commands
  TAR = 'tar'
  LATEX = 'pdflatex'

  ## paths
  HOME = Pathname.new '/home'
  EXPIRED_LIST = HOME + 'expired_users'
  ALL_USERS_FORWARD = HOME + 'user/.forward'
  EXPIRED_DIR = Pathname.new '/home.backup/expired'
  PROGRAM_DIR = Pathname.new File.expand_path('../', __FILE__)
  CONFIG_FILE = PROGRAM_DIR + 'config/connection.yaml'
  TEMPLATE_DIR = PROGRAM_DIR + 'template/'

  DOMAIN = 'math.kyoto-u.ac.jp'
  ID_RANGE = 2000...5000
  TEST_ID_RANGE = 12000...15000
  TEST_USER_PREFIX = 'testuser'

  def self.need_root_or_exit
    if `id -u`.to_i != 0 then
      STDERR.puts 'need root privilege!'
      exit 1
    end
  end

  def self.setup_connection
    error "#{CONFIG_FILE} was NOT found!" unless File.exists? CONFIG_FILE
    if File.world_readable?(CONFIG_FILE) then
      warning "#{CONFIG_FILE} should NOT be readable by others."
      system('make secret')
    end
    config = read_connection_config(CONFIG_FILE)
    ActiveLdap::Base.setup_connection config
  end

  ##################### Private Functions #####################
  private

  def self.read_connection_config(file)
    error "Config file #{file} does NOT exist!" unless File.exists?(file)
    YAML.load_file file
  end

  ##################### Module Functions #####################
  module_function

  def generate_random_password(size = 10)
    charset = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    charset += %w[# $ % & + - ^ @ { } < > / _]
    charset -= %w[l 1 I 7 T g q 9 o 0 O Q D]
    (1..size).inject('') { |p| p << charset[rand(charset.size)] }
  end

  def calculate_hashed_password(raw_password)
    salt_charset = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    salt = Array.new(4) { salt_charset[SecureRandom.random_number(salt_charset.length)] }.join
    '{SSHA}' + Base64.encode64(Digest::SHA1.digest(raw_password + salt) + salt).chomp
  end

  ## requires an instance variable @user of User
  def create_password_pdf
    return unless @user
    latex_options = %w(-halt-on-error -no-shell-escape)
    latex_options += %w(-draftmode) if is_mode? :noop
    Dir.mktmpdir do |dir|
      info "Temporally working on #{dir}."
      temp_path = Pathname.new(dir) + "PASSWORD.#{@user.uid}.tex"
      temp_path.open 'w' do |temp|
        temp.chmod 0600
        temp.write render('password.tex.erb')
      end
      info "#{LATEX} #{latex_options.join ' '} #{temp_path.to_s}"
      Dir.chdir dir do
        system(LATEX, *latex_options, temp_path.to_s)
        return if is_mode? :noop
        pdf_path = temp_path.sub_ext '.pdf'
        pdf_path.chmod 0600
        FileUtils.mv pdf_path, PROGRAM_DIR
        info "Created #{PROGRAM_DIR + pdf_path.basename} successfully."
      end
    end
  end

  def render(template_name)
    File.open(TEMPLATE_DIR + template_name) do |file|
      ERB.new(file.read).result(binding)
    end
  end

  def get_id_range
    is_mode?(:test) ? TEST_ID_RANGE : ID_RANGE
  end

  def is_expired?(uid)
    File.open(EXPIRED_LIST, 'r') do |file|
      return file.each_line.any? { |line| line.strip == uid }
    end
  end

  def initialize_flags
    @flags = {}
    disable_mode :noop
    disable_mode :verbose
    disable_mode :test
    disable_mode :help
  end

  def disable_mode(type)
    set_mode type, false
  end

  def enable_mode(type)
    set_mode type, true
  end

  def set_mode(type, enabled)
    @flags[type] = enabled
    info "#{enabled ? 'Enabled' : 'Disabled'} #{type} mode."
  end

  def is_mode?(type)
    ## include されずに直接呼ばれた場合は常に true を返す
    return true unless instance_variables.include?(:@flags)
    @flags[type]
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

end

