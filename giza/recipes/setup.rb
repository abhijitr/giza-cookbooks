include_recipe "python"
include_recipe "opsworks_nodejs"
include_recipe "supervisor"

package "libpq-dev" do
  action :install
end

package "lzop" do
  action :install
end

python_pip "awscli" do
  action :upgrade
end

python_pip "uwsgi" do
  action :upgrade
end

cookbook_file "/etc/logrotate.conf" do
  path "logrotate.conf"
  action :create
end

cookbook_file "/etc/logrotate.d/nginx" do
  path "logrotate_nginx"
  action :create
end

cookbook_file "/etc/logrotate.d/giza" do
  path "logrotate_giza"
  action :create
end