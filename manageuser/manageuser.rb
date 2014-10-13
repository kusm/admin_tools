
require 'active_ldap'
require 'yaml'
require_relative './models/user'
require_relative './models/group'

module ManageUser
  EXPIRED_LIST = '/home/expired_users'
  TARDIR = '/home.backup/expired'
  CONFIG_FILE = File.expand_path('../config/connection.yaml', __FILE__)
  LDAP_SECRET_FILE = File.expand_path('../secret/ldap.secret', __FILE__)

  def self.need_root_or_exit
    if `id -u`.to_i != 0 then
      STDERR.puts 'need root privilege!'
      exit 1
    end
  end

  def self.setup_connection
    config = read_connection_config(CONFIG_FILE)
    config[:password_block] = Proc.new {
      get_password_from_secret
    }
    ActiveLdap::Base.setup_connection config
  end

  def generate_random_password(size = 10)
    charset = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    charset += %w[# $ % & + - ^ @ { } < > / _]
    charset -= %w[l 1 I 7 T g q 9 o 0 O Q D]
    (1..size).inject('') { |p| p << charset[rand(charset.size)] }
  end
  module_function :generate_random_password

  def calculate_hashed_password(raw_password)
    salt_charset = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    salt = salt_charset[rand 64] + salt_charset[rand 64]
    '{SSHA}' + Base64.encode64(Digest::SHA1.digest(raw_password + salt) + salt).chomp
  end
  module_function :calculate_hashed_password

  def error(msg)
    STDERR.puts '[ERROR] ' + msg
    exit 1
  end
  module_function :error

  def warning(msg)
    STDERR.puts '[WARNING] ' + msg if is_mode?(:verbose)
  end
  module_function :warning

  def info(msg)
    STDOUT.puts '[INFO] ' + msg if is_mode?(:verbose)
  end
  module_function :info

  private

  def self.get_password_from_secret
    system('make secret') unless File.exists?(LDAP_SECRET_FILE)
    File.open(LDAP_SECRET_FILE, 'r').read.chomp
  end

  def self.read_connection_config(file)
    error "Config file #{file} does NOT exist!" unless File.exists?(file)
    YAML.load_file file
  end
end

