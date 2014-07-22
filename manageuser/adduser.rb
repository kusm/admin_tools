#!/usr/bin/ruby
# -*- coding: utf-8; -*-
#
# Author: Tomohiro Fukaya, Nao Sato, Youhei SASAKI
# Contacts: <support@math.kyoto-u.ac.jp>
# $Lastupdate: 2014-03-27 18:50:20$
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#= require statement
require 'shell'
require 'fileutils'
require 'digest/sha1'
require 'base64'
require 'ldap'
## FIXME: adduser スクリプトと同じディレクトリでよいように思う
ADMIN = "/home/uda/ldap/admin_tools/manageuser/"
HOME = "/home/"
SKEL = ADMIN + "skel/"

## TODO: root 権限で実行されているかどうかの確認

def read_admin_secret
  secret_file = File.expand_path(File.dirname(__FILE__), './secret/ldap.admin.secret')
  admin_secret = nil
  unless File.exists?(secret_file) then
    system('make secret')
  end
  File.open(secret_file, 'r') do |f|
    admin_secret = f.read
  end
  return admin_secret.chomp
end

LDAP_ADMIN_SECRET = read_admin_secret

def checkldapuser(uid)
  @uid = uid.to_s
  conn = LDAP::SSLConn.new('smaux.math.kyoto-u.ac.jp',636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION,3)
  conn.bind("cn=admin,dc=math,dc=kyoto-u,dc=ac,dc=jp", LDAP_ADMIN_SECRET)
  dn = "uid="+ @uid + ",ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp"
  begin
    conn.search(dn,LDAP::LDAP_SCOPE_SUBTREE, "(uidNumber=*)"){|entry|}
    return 1
  rescue LDAP::Error
    return 0
  end
end

def getLatestUid
  uidlist = Array.new
  conn = LDAP::SSLConn.new('smaux.math.kyoto-u.ac.jp',636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION,3)
  conn.bind("cn=admin,dc=math,dc=kyoto-u,dc=ac,dc=jp", LDAP_ADMIN_SECRET)
  people = "ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp"
  conn.search(people,LDAP::LDAP_SCOPE_SUBTREE, "(uidNumber=*)"){|entry|
    uidlist.push(entry['uidNumber'].first.to_i)
  }
#  uidlist.delete(65534)
  #  uid should be greater than 2000 and smaller than 5000.
  uidlist.delete_if{|uid| uid < 2000 or uid > 5000}
  return uidlist.sort.pop
end

def getLatestGid
  gidlist = Array.new
  conn = LDAP::SSLConn.new('smaux.math.kyoto-u.ac.jp',636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION,3)
  conn.bind("cn=admin,dc=math,dc=kyoto-u,dc=ac,dc=jp", LDAP_ADMIN_SECRET)
  group = "ou=Group,dc=math,dc=kyoto-u,dc=ac,dc=jp"
  conn.search(group,LDAP::LDAP_SCOPE_SUBTREE, "(gidNumber=*)"){|entry|
    gidlist.push(entry['gidNumber'].first.to_i)
  }
#  gidlist.delete(65534)
  #  gid should be greater than 2000 and smaller than 5000.
  gidlist.delete_if{|gid| gid < 2000 or gid > 5000}
  return gidlist.sort.pop
end

def makepassword
  pass_size = 10
  a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['$','#','@','!'].to_a
  return Array.new(pass_size){a[rand(a.size)]}.join
end

def texstr(word)
  a = word.gsub('$','\$')
  a.gsub!('#','\#')
  return a
end

def hashedpass(raw)
  salt_charset = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  salt = "" << salt_charset[rand 64] << salt_charset[rand 64]
  hashed_pass = "{SSHA}"+Base64.encode64(Digest::SHA1.digest(raw + salt) + salt).chomp!
  #return raw.crypt(salt)
  return hashed_pass.to_s
end

def print_usage
    printf "Usage: adduser [Options] user \"FAMILY_NAME, Given_name\"\n"
    printf "Options:\n"
    printf "  Position: -kyoju, -junkyoju, -koshi, -jokyo, -doctor, -master\n"
  #  printf "  Password:       -p PASSWORD|-ep Encrypted_PASSWORD"
    printf "  Shell:    -tcsh|-bash|-zsh|-nologin SHELL\n"
  #  printf "  Quota:  -big|-medium|-small|-student|-staff"
    printf "  Expire:   -exp 20yymmdd\n"
    printf "  Comment:  -comment \"GCOE Postdoc... etc\"\n"
    printf "  uid/gid number: -uidNum xxxx -gidNum yyyy\n"
  #  printf "          This data will be stored in $USERINFOFILE "
  #  printf "          and not used elsewhere."
    printf  "Example: adduser -master -bash -exp 20130331 khanako \"KYODAI, Hanako\"\n"
end

class UserAccount
  def initialize
    @ml = Array.new
    @uidNumber = 9999
    @gidNumber = 9999
    @shell = "/bin/bash"
    comment = "normal account"
    expire = "EXPIRE ?, "
    if ARGV.empty? then
      print_usage
      exit
    end
    while !ARGV.empty?
      arg = ARGV.shift
      case arg
      when "-exp"
        expire = "EXPIRE " + ARGV.shift + ", "
      when "-comment"
        comment = ARGV.shift
#           @description = ARGV.shift
      when "-bash", "-zsh", "-tcsh", "-nologin"
        @shell = arg.gsub("-","/bin/")
      when "-kyoju", "-junkyoju", "-koshi", "-jokyo"
        @ml.push arg.gsub("-","")
        expire = "EXPIRE permanent, "
      when "-gakushin", "-tokuken", "-gcoeken", "-fellow",
        "-doctor", "-master", "-visitor",  "-gkyoin",
        "-jimushitsu", "-toshojimu", "-yomuin",
        "-oa","-gakushin-pd"
        @ml.push arg.gsub(/^-/,"")
      when "-uidNum"
        @uidNumber = ARGV.shift
      when "-gidNum"
        @gidNumber = ARGV.shift
      when /^-.*/
        p arg
        print_usage
        exit
      else
        @uid = arg
        #          @fullname = ARGV.shift
        fullName = ARGV.shift
        @sn, @givenName = fullName.split(",")
        @fullname = fullName.tr(',','')
        @sn.strip!
        @givenName.strip!
        # printf "sn = %s, gn = %s\n", @sn, @givenName
      end
    end
    @description = Time.now.strftime("SINCE %Y%m%d, ") + expire + comment
    uidgid = [getLatestUid, getLatestGid].max + 1
#    if @uidNumber == 9999 then @uidNumber = getLatestUid + 1 end
#    if @gidNumber == 9999 then @gidNumber = getLatestGid + 1 end
    if @uidNumber == 9999 then @uidNumber = uidgid  end
    if @gidNumber == 9999 then @gidNumber = uidgid  end
    @home = HOME + @uid
  end
  def checkuser
    if checkldapuser(@uid) == 1 then
      printf "%s: already exists!\n", @uid
      exit
    end
  end
  def checkhome
    if File.exist?(@home) then
      printf "%s: already exists!\n", @home
      exit
    end
  end
  def setpass
    @password = makepassword
    @hashed_pass = hashedpass(@password)
  end
  def outpass
    outpdf = "PASSWORD." + @uid +".pdf"
    texput = open("texput.tex","w")
    template = open("template.tex","r")
    texpassword = texstr(@password)
    while line = template.gets
      line.gsub!("hogehoge",@uid)
      line.gsub!("fugafuga", texpassword)
      line.gsub!("FULLNAME",@fullname)
      texput.print line
    end
    texput.close
    system("/usr/bin/pdflatex", "texput.tex")
    ## root:Admin にする．ここで root 権限を使うため，root でない場合以降の処理が実行されない．
    File.chown("0".to_i,"1100".to_i, "texput.pdf")
    File.chmod("640".oct, "texput.pdf")
    File.unlink("texput.aux","texput.log","texput.tex")
    File.rename("texput.pdf", outpdf)
  end
  def makehome
    if @shell == "/bin/nologin"
      return
    end
    Dir.mkdir(@home, "755".oct)
    FileUtils.copy_entry(SKEL, @home)
    [@home + "/Maildir/.Drafts",
     @home + "/Maildir/.Junk",
     @home + "/Maildir/.Sent",
     @home + "/Maildir/.Templates",
     @home + "/Maildir/.Archives",
     @home + "/Maildir/.Trash"
    ].each do |newdir|
      Dir.mkdir newdir
      FileUtils.chmod "2700".oct, newdir
    end
    [@home + "/Maildir/cur",
     @home + "/Maildir/new",
     @home + "/Maildir/tmp"
    ].each do |newdir|
      Dir.mkdir newdir
      FileUtils.chmod "700".oct, newdir
    end
    prefs = open(@home + "/.icedove/default/prefs.js","w")
    template = open(@home + "/.icedove/prefs.js.org","r")
    while line = template.gets
      line.gsub!("FULLNAME",@fullname)
      line.gsub!("UID",@uid)
      prefs.print line
    end
    template.close
    FileUtils.chown_R(@uidNumber, @gidNumber, @home)
    File.delete(@home + "/.icedove/prefs.js.org")
  end
  def createLDIF
    ## for Debug ###
    file = open(@uid+".ldif","w")
    #User dn
    file.printf \
    "dn: uid=%s,ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp\n", @uid
    file.printf "objectClass: inetOrgPerson\n"
    file.printf "objectClass: posixAccount\n"
    file.printf "uid: %s\n", @uid
    file.printf "cn: %s %s\n", @sn, @givenName
    file.printf "givenName: %s\n", @givenName
    file.printf "sn: %s\n", @sn
    file.printf "mail: %s@math.kyoto-u.ac.jp\n", @uid
    file.printf "userPassword: %s\n", @hashed_pass
    file.printf "uidNumber: %s\n", @uidNumber
    file.printf "gidNumber: %s\n", @gidNumber
    file.printf "homeDirectory: /home/%s\n", @uid
    file.printf "gecos: %s %s\n", @sn, @givenName
    file.printf "description: %s\n", @description
    file.printf "loginShell: %s\n", @shell
    #Group dn
    file.printf "\n"
    file.printf \
    "dn: cn=%s,ou=Group,dc=math,dc=kyoto-u,dc=ac,dc=jp\n", @uid
    file.printf "objectclass: posixGroup\n"
    file.printf "cn: %s\n", @uid
    file.printf "gidNumber: %s\n", @gidNumber
    #end
    file.close
  end
  def addml
    # adding to /home/user/.forward
    printf "Adding %s to /home/user/.forward\n", @uid
    userml = open("/home/user/.forward","a")
    userml.printf "%s\n", @uid
    userml.close
    # adding to ou=Group,..
    unless @ml.size == 0
      conn = LDAP::SSLConn.new('smaux.math.kyoto-u.ac.jp',636)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION,3)
      conn.bind("cn=admin,dc=math,dc=kyoto-u,dc=ac,dc=jp", LDAP_ADMIN_SECRET)
      @ml.each do |ml|
        ml_entry = [LDAP.mod(LDAP::LDAP_MOD_ADD, 'memberUid', ["#{@uid}"]),]
        group = "cn=#{ml},ou=Group,dc=math,dc=kyoto-u,dc=ac,dc=jp"
        conn.modify(group, ml_entry)
      end
    end
  end
  def ldapadd
    conn = LDAP::SSLConn.new('smaux.math.kyoto-u.ac.jp',636)
    conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION,3)
    conn.bind("cn=admin,dc=math,dc=kyoto-u,dc=ac,dc=jp", LDAP_ADMIN_SECRET)
    dn = "uid="+ @uid + ",ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp"
    entryPeople = [
      LDAP.mod(LDAP::LDAP_MOD_ADD,'objectclass',\
        ['inetOrgPerson','posixAccount']),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'uid',[@uid]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'cn',[@fullname]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'givenName',[@givenName]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'sn',[@sn]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'mail',[@uid+'@math.kyoto-u.ac.jp']),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'userPassword',[@hashed_pass]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'uidNumber',["#{@uidNumber}"]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'gidNumber',["#{@gidNumber}"]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'homeDirectory',[@home]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'gecos',[@fullname]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'description',[@description]),
      LDAP.mod(LDAP::LDAP_MOD_ADD,'loginShell',[@shell]),
    ]
    begin
      conn.add("uid="+@uid+",ou=People,dc=math,dc=kyoto-u,dc=ac,dc=jp",\
        entryPeople)
    rescue LDAP::ResultError
      conn.perror("add")
      exit
    end
    if @gidNumber == @uidNumber then
      entryGroup = [
        LDAP.mod(LDAP::LDAP_MOD_ADD,'objectclass',['posixGroup']),
        LDAP.mod(LDAP::LDAP_MOD_ADD,'cn',[@uid]),
        LDAP.mod(LDAP::LDAP_MOD_ADD,'gidNumber',["#{@uidNumber}"]),
      ]
      begin
        conn.add("cn="+@uid+",ou=Group,dc=math,dc=kyoto-u,dc=ac,dc=jp",\
          entryGroup)
         # File.delete(ADMIN+@uid+".ldif")
      rescue LDAP::ResultError
        conn.perror("add")
        printf "Error:ldapadd. See %s.ldif\n", @uid
        exit
      end
    end
  end
  def uid
    return @uid
  end
end
user = UserAccount.new
puts "check user"
user.checkuser
puts "set password"
user.setpass
puts "create LDIF file"
user.createLDIF
puts "check $HOME"
user.checkhome
puts "add LDIF"
user.ldapadd
puts "make $HOME"
user.makehome
puts "output password file"
user.outpass
puts "add ml"
user.addml
