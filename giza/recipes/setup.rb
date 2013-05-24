include_recipe "python"
include_recipe "opsworks_nodejs"
include_recipe "supervisor"

package "libpq-dev" do
  action :install
end

python_pip "uwsgi" do
  action :upgrade
end

template "/etc/rsyslog.cfg" do
  source "rsyslog.conf.erb" 
  mode 0644
  variables(
    :deploy => deploy
  )
  notifies :restart, "rsyslog"
end

template "/etc/rsyslog.d/22-nginx.conf" do
  source "22-nginx.conf.erb"
  mode 0644
  variables(
    :deploy => deploy
  )
  notifies :restart, "rsyslog"
end

template "/etc/rsyslog.d/23-giza.conf" do
  source "22-giza.conf.erb"
  mode 0644
  variables(
    :deploy => deploy
  )
  notifies :restart, "rsyslog"
end

template "/etc/rsyslog.d/50-default.conf" do
  source "50-default.conf.erb"
  mode 0644
  variables(
    :deploy => deploy
  )
  notifies :restart, "rsyslog"
end
