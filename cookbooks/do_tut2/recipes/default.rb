#
# Cookbook Name:: do_tut2
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node.default['thisUser'] = ENV['USER']
node.default['dest'] = ENV['HOME']

file "#{node['dest']}/motd" do
  content "hello #{node['thisUser']}"
end

template "#{node['dest']}/chef-repo/cookbooks/hello_chef_server/recipes/default.rb" do
  source 'hello_chef_server.default.rb.erb'
end

