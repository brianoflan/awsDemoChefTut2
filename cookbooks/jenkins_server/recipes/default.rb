#
# Cookbook Name:: jenkins_server
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node.default['homeDest'] = "/home/#{ENV['SUDO_USER']}"

execute 'opensslRand' do
  action :nothing
  command 'openssl rand -base64 512 | tr -d \'\r\n\' > /tmp/jenkins_server.rand'
  not_if { File.exists?('/tmp/jenkins_server.rand') }
end

execute 'opensslNewkey' do
  action :nothing
  command 'openssl req -newkey rsa:2048 -nodes -new -x509 -keyout /var/tmp/.chef-zero.pem -out /var/tmp/.chef-zero.cert -subj "/C=CC/ST=ST/L=LL/O=OO/OU=OU/CN=CN"'
  not_if { File.exists?('/var/tmp/.chef-zero.pem') }
end

execute 'opensslPubout' do
  action :nothing
  command 'openssl rsa -in /var/tmp/.chef-zero.pem -pubout > /var/tmp/.chef-zero.pub'
  not_if { File.exists?('/var/tmp/.chef-zero.pub') }
end

template 'jserver_dbg' do
  action :nothing
  path "#{node['homeDest']}/chef-repo/data_bags/jenkins_server/admin.json"
  source 'jserver_dbg.json.erb'
end

ruby_block 'prepInputFiles1' do
  block do
  end
  notifies :run, 'execute[opensslRand]', :immediately
  notifies :run, 'execute[opensslNewkey]', :immediately
  notifies :run, 'ruby_block[prepInputFiles2]', :delayed
end
ruby_block 'prepInputFiles2' do
  action :nothing
  block do
    node.default['jenkins_server_privKey'] = File.open('/var/tmp/.chef-zero.pem').read
  end
  notifies :run, 'execute[opensslPubout]', :immediately
  notifies :run, 'ruby_block[setProps]', :delayed
end
ruby_block 'setProps' do
  action :nothing
  block do
    node.default['jenkins_server_pubKey'] = File.open('/var/tmp/.chef-zero.pub').read
  end
  notifies :create, 'template[jserver_dbg]', :immediately
  notifies :run, 'execute[knifeMkDbg]', :delayed
end
execute 'knifeMkDbg' do
  command 'knife data bag create jenkins_server'
  action :nothing
end

# include_recipe 'jenkins-server::default'

#

