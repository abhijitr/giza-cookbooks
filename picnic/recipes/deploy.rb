include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'picnic'
    Chef::Log.debug("Skipping deploy::web application #{application} as it is not a picnic app")
    next
  end

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

  # start gunicorn under supervisor
  supervisor_service "gunicorn-#{application}" do
    action [:enable, :restart]
    command "#{deploy[:deploy_to]}/shared/#{application-env}/bin/gunicorn --preload -w 2 -k gevent -b 0.0.0.0:8000 picnic.wsgi"
    environment deploy[:environment]
    stopsignal "INT"
    directory "#{deploy[:deploy_to]}/current/search"
    autostart false
    user deploy[:user] 
  end 

  # configure nginx 
  nginx_web_app application do
    application deploy
    template "nginx.erb"
    cookbook "picnic"
  end 
end
