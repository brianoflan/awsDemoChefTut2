#
# Cookbook Name:: jenkins_server
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# node.default['homeDest'] = "/home/#{ENV['SUDO_USER']}"
#     theUser = ENV['SUDO_USER'] || ENV['USER']
#     node.default['homeDest'] = "/home/#{theUser}" 

randFile = '/tmp/jenkins_server.rand'

node.default['jenkins-server']['security']['chef-vault']['data_bag'] = 'jenkins_server'
node.default['jenkins-server']['security']['chef-vault']['data_bag_item'] = 'admin'
node.default['dev_mode'] = 'true'

execute 'opensslRand' do
  action :nothing
  command "openssl rand -base64 512 | tr -d '\r\n' > #{randFile}"
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
  path lazy{"#{node['homeDest']}/chef-repo/data_bags/jenkins_server/admin.json"}
  source 'jserver_dbg.json.erb'
end

ruby_block 'findHome' do
  block do
    theUser = ENV['SUDO_USER'] || ENV['USER']
    node.default['homeDest'] = "/home/#{theUser}" 
  end
  # notifies :run, 'ruby_block[prepInputFiles1]', :immediately
end
ruby_block 'prepInputFiles1' do
  block do
  end
  # notifies :run, 'execute[opensslRand]', :immediately
  notifies :run, 'execute[opensslNewkey]', :immediately
  notifies :run, 'ruby_block[prepInputFiles2]', :delayed
  action :nothing
end
ruby_block 'prepInputFiles2' do
  action :nothing
  block do
    node.default['jenkins_server_privKey'] = File.open('/var/tmp/.chef-zero.pem').read.gsub(/[\n\r]/, "\\n")
  end
  notifies :run, 'execute[opensslPubout]', :immediately
  notifies :run, 'ruby_block[setProps]', :delayed
end
ruby_block 'setProps' do
  action :nothing
  block do
    node.default['jenkins_server_pubKey'] = File.open('/var/tmp/.chef-zero.pub').read.gsub(/([\n][\r]|[\n]|[\r])/, "\\n")
    
  end
  notifies :create, 'template[jserver_dbg]', :immediately
  notifies :run, 'execute[knifeMkDbg]', :delayed
end
execute 'knifeMkDbg' do
  command 'knife data bag create jenkins_server'
  cwd lazy{"#{node['homeDest']}/chef-repo"}
  action :nothing
  notifies :run, 'execute[knifeUploadDbg]', :immediately
end
execute 'knifeUploadDbg' do
  # command lazy{"knife data bag --config #{node['homeDest']}/chef-repo/.chef/knife.rb from file jenkins_server admin.json --secret-file #{randFile}"}
  command lazy{"knife data bag --config #{node['homeDest']}/chef-repo/.chef/knife.rb from file jenkins_server admin.json"}
  cwd lazy{"#{node['homeDest']}/chef-repo"}
  action :nothing
  notifies :run, 'ruby_block[runJenkinsServer]', :delayed
end
ruby_block 'runJenkinsServer' do
  block do
    # include_recipe 'jenkins-server::default'
    # run_context.include_recipe 'jenkins-server::default'
  end
  action :nothing
end

include_recipe 'jenkins-server::default'
#

