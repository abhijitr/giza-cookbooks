include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'giza'
    Chef::Log.debug("Skipping deploy::web application #{application} as it is not a giza app")
    next
  end

  supervisor_env = deploy[:environment].merge({
    "virtualenv_root" => "#{deploy[:deploy_to]}/shared/#{application}-env",
    "HOME" => "/home/#{deploy[:user]}",
    "USER" => deploy[:user],
    "USERNAME" => deploy[:user],
    "LOGNAME" => deploy[:user]
  })

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    app application
    deploy_data deploy
  end

  directory "#{deploy[:deploy_to]}/shared/#{application}-env" do
    group deploy[:group]
    owner deploy[:user]
    mode 0770
    action :create
    recursive true
  end

  virtualenv "#{deploy[:deploy_to]}/shared/#{application}-env" do
    group deploy[:group] 
    owner deploy[:user] 
    action :create
    requirements_file "#{deploy[:deploy_to]}/current/#{deploy[:requirements_path]}"
  end

  # update thumbor config
  template "#{deploy[:deploy_to]}/current/thumbor.conf" do
    source "thumbor.conf.erb" 
    mode 0644
    variables(
      :deploy => deploy
    )
  end

  # start thumbor process under supervisor
  supervisor_service "thumbor-#{application}" do
    action [:enable, :restart]
    command "#{deploy[:deploy_to]}/shared/#{application}-env/bin/python #{deploy[:deploy_to]}/shared/#{application}-env/bin/thumbor --port=900%(process_num)s --conf=./thumbor.conf"
    numprocs 4
    environment supervisor_env 
    stopsignal "TERM"
    directory "#{deploy[:deploy_to]}/current"
    autostart false
    user deploy[:user] 
  end 

  # configure nginx 
  nginx_web_app application do
    application deploy
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
      :deploy => deploy
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  # TODO: rsyslog conf for thumbor 
  template "/etc/rsyslog.d/50-default.conf" do
    source "50-default.conf.erb"
    mode 0644
    variables(
      :deploy => deploy
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
end
