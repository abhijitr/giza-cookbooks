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

  # install all the modules in npm_requirements.txt
  execute "npm-dependencies-#{application}" do
    command "cat #{deploy[:deploy_to]}/current/#{deploy[:npm_requirements_path]} | xargs npm install -g"
    only_if "test -f #{deploy[:deploy_to]}/current/#{deploy[:npm_requirements_path]}"
  end

  # start worker process under supervisor
  supervisor_service "worker-#{application}" do
    action [:enable, :restart]
    command "#{deploy[:deploy_to]}/current/giza/deploy/start_worker.sh"
    environment supervisor_env 
    stopsignal "TERM"
    directory "#{deploy[:deploy_to]}/current"
    autostart false
    user deploy[:user] 
  end 

  # start celerybeat under supervisor
  supervisor_service "scheduler-#{application}" do
    action [:enable, :restart]
    command "#{deploy[:deploy_to]}/current/giza/deploy/start_scheduler.sh"
    environment supervisor_env 
    stopsignal "TERM"
    directory "#{deploy[:deploy_to]}/current"
    autostart false
    user deploy[:user] 
  end 

  # start uwsgi under supervisor
  supervisor_service "uwsgi-#{application}" do
    action [:enable, :restart]
    command "uwsgi --lazy --ini-paste #{deploy[:deploy_to]}/current/#{deploy[:uwsgi_ini_path]} -s /tmp/uwsgi-#{application}.sock -H #{deploy[:deploy_to]}/shared/#{application}-env"
    environment supervisor_env
    stopsignal "INT"
    directory "#{deploy[:deploy_to]}/current"
    autostart false
    user deploy[:user] 
  end 

  # configure nginx 
  nginx_web_app application do
    application deploy
    template "nginx.erb"
    cookbook "giza"
  end 

  template "/etc/boto.cfg" do
    source "boto_config.erb" 
    owner deploy[:user] 
    group deploy[:group] 
    mode 0644
    variables(
      :deploy => deploy
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
      :deploy => deploy
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  template "/etc/rsyslog.d/22-nginx.conf" do
    source "22-nginx.conf.erb"
    mode 0644
    variables(
      :deploy => deploy
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  template "/etc/rsyslog.d/23-giza.conf" do
    source "23-giza.conf.erb"
    mode 0644
    variables(
      :deploy => deploy
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
  
  template "/etc/rsyslog.d/50-default.conf" do
    source "50-default.conf.erb"
    mode 0644
    variables(
      :deploy => deploy
    )
    notifies :reload, resources(:service => "rsyslog"), :delayed
  end
end
