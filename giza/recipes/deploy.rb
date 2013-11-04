include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |app_name, app|
  if app[:application_type] != 'giza'
    Chef::Log.debug("Skipping giza::deploy application #{app_name} as it is not a giza app")
    next
  end

  supervisor_env = app[:environment].merge({
    "virtualenv_root" => "#{app[:deploy_to]}/shared/#{app_name}-env",
    "HOME" => "/home/#{app[:user]}",
    "USER" => app[:user],
    "USERNAME" => app[:user],
    "LOGNAME" => app[:user]
  })

  opsworks_deploy_dir do
    user app[:user]
    group app[:group]
    path app[:deploy_to]
  end

  opsworks_deploy do
    app app_name 
    deploy_data app
  end

  directory "/var/lib/#{app_name}/data" do
    group app[:group]
    owner app[:user]
    mode 0770
    action :create
    recursive true
  end

  directory "#{app[:deploy_to]}/shared/#{app_name}-env" do
    group app[:group]
    owner app[:user]
    mode 0770
    action :create
    recursive true
  end

  virtualenv "#{app[:deploy_to]}/shared/#{app_name}-env" do
    group app[:group] 
    owner app[:user] 
    action :create
    requirements_file "#{app[:deploy_to]}/current/#{app[:requirements_path]}"
  end

  # install all the modules in npm_requirements.txt
  execute "npm-dependencies-#{app_name}" do
    command "cat #{app[:deploy_to]}/current/#{app[:npm_requirements_path]} | xargs npm install -g"
    only_if "test -f #{app[:deploy_to]}/current/#{app[:npm_requirements_path]}"
  end

  # start worker process under supervisor
  supervisor_service "worker-#{app_name}" do
    action [:enable, :restart]
    command "#{app[:deploy_to]}/current/giza/deploy/start_worker.sh"
    environment supervisor_env 
    stopsignal "TERM"
    stopasgroup true
    directory "#{app[:deploy_to]}/current"
    autostart false
    user app[:user] 
  end 

  # start celerybeat under supervisor
  supervisor_service "scheduler-#{app_name}" do
    action [:enable, :restart]
    command "#{app[:deploy_to]}/current/giza/deploy/start_scheduler.sh"
    environment supervisor_env 
    stopsignal "TERM"
    stopasgroup true
    directory "#{app[:deploy_to]}/current"
    autostart false
    user app[:user] 
  end 

  # start uwsgi under supervisor
  supervisor_service "uwsgi-#{app_name}" do
    action [:enable, :restart]
    command "uwsgi --lazy --ini-paste #{app[:deploy_to]}/current/#{app[:uwsgi_ini_path]} -s /tmp/uwsgi-#{app_name}.sock -H #{app[:deploy_to]}/shared/#{app_name}-env"
    environment supervisor_env
    stopsignal "INT"
    stopasgroup true
    directory "#{app[:deploy_to]}/current"
    autostart false
    user app[:user] 
  end 

  # configure nginx 
  directory "/etc/nginx/include.d" do
    owner "root"
    group "root"
    mode 0755
    action :create
    recursive true
  end

  template "/etc/nginx/include.d/giza-common" do
    source "giza-common.erb" 
    owner "root" 
    group "root" 
    mode 0644
    variables(
      :application => app,
      :application_name => app_name
    )
  end

  nginx_web_app app_name do
    application app
    template "nginx.erb"
    cookbook "giza"
  end 

  template "/etc/boto.cfg" do
    source "boto_config.erb" 
    owner app[:user] 
    group app[:group] 
    mode 0644
    variables(
      :application => app 
    )
  end

  # Define me a rsyslog service so we can restart it
  service "rsyslog" do
    supports :restart => true, :reload => true
    action :nothing
  end

  # update rsyslog config
  template "/etc/rsyslog.conf" do
    source "rsyslog.conf.erb" 
    mode 0644
    variables(
      :application => app 
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  template "/etc/rsyslog.d/22-nginx.conf" do
    source "22-nginx.conf.erb"
    mode 0644
    variables(
      :application => app 
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  template "/etc/rsyslog.d/23-giza.conf" do
    source "23-giza.conf.erb"
    mode 0644
    variables(
      :application => app 
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  template "/etc/rsyslog.d/50-default.conf" do
    source "50-default.conf.erb"
    mode 0644
    variables(
      :application => app 
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
end
