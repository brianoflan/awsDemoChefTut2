
current_dir = File.dirname(__FILE__)
cookbook_path     "#{current_dir}/../cookbooks"

chef_server_url   'http://127.0.0.1:8889'
node_name         'stickywicket'
client_key        '/var/tmp/.chef-zero.pem'

