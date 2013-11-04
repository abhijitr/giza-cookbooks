include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |app_name, app|
  if app[:application_type] != 'giza'
    Chef::Log.debug("Skipping pillbox::deploy application #{app_name} as it is not a giza app")
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
    packages(
      "thumbor" => "3.12.0"
    )
  end

  # update thumbor config
  template "#{app[:deploy_to]}/current/thumbor.conf" do
    source "thumbor.conf.erb" 
    mode 0644
    variables(
      :application => app
    )
  end

  # start thumbor process under supervisor
  supervisor_service "thumbor-#{app_name}" do
    action [:enable, :restart]
    command "#{app[:deploy_to]}/shared/#{app_name}-env/bin/python #{app[:deploy_to]}/shared/#{app_name}-env/bin/thumbor --port=900%(process_num)s --conf=./thumbor.conf"
    numprocs 4
    process_name "%(process_num)s"
    environment supervisor_env 
    stopsignal "TERM"
    directory "#{app[:deploy_to]}/current"
    autostart false
    user app[:user] 
  end 

  # configure nginx 
  nginx_web_app app_name do
    application app
    template "nginx.erb"
    cookbook "pillbox"
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
  
  # TODO: rsyslog conf for thumbor 
  template "/etc/rsyslog.d/50-default.conf" do
    source "50-default.conf.erb"
    mode 0644
    variables(
      :application => app 
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
end
