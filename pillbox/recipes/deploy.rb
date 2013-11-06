include_recipe "nginx::service"
include_recipe "virtualenv"

# Define me a rsyslog service so we can restart it
service "rsyslog" do
  supports :restart => true, :reload => true
  action :nothing
end

node[:deploy].each do |app_name, app|
  unless app.key?(:application)
    Chef::Log.debug("Skipping pillbox::deploy application #{app_name} as it isn't actually getting deployed")
    next
  end

  unless app[:layers].key?(:pillbox)
    Chef::Log.debug("Skipping pillbox::deploy application #{app_name} as it does not require pillbox")
    next
  end

  layer = app[:layers][:pillbox]

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
      :application => app,
      :application_name => app_name
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

  # NOTE: If more than one app has a splunk_url defined, rsyslog settings
  # will clobber each other!! Need to refactor this to make it work.
  if app.key?("splunk_url")
    # update rsyslog config
    template "/etc/rsyslog.conf" do
      source "rsyslog.conf.erb" 
      mode 0644
      variables(
        :application => app,
        :application_name => app_name
      )
      notifies :reload, resources(:service => "rsyslog"), :delayed
    end
    
    # TODO: rsyslog conf for thumbor 
    template "/etc/rsyslog.d/50-default.conf" do
      source "50-default.conf.erb"
      mode 0644
      variables(
        :application => app,
        :application_name => app_name
      )
      notifies :reload, resources(:service => "rsyslog"), :delayed
    end
  end
end
