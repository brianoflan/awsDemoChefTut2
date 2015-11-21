#
# Cookbook Name:: do_tut2
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

file 'motd' do
  content 'hello chef'
end

template 'chef-repo/cookbooks/hello_chef_server/recipes/default.rb' do
  source 'hello_chef_server.default.rb.erb'
end

