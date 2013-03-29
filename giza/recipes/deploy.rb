include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'giza'
    Chef::Log.debug("Skipping deploy::web application #{application} as it is not a giza app")
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

  # install all the modules in npm_requirements.txt
  execute "npm-dependencies-#{application}" do
    command "cat #{deploy[:deploy_to]}/current/#{deploy[:npm_requirements_path]} | xargs npm install -g"
    only_if "test -f #{deploy[:deploy_to]}/current/#{deploy[:npm_requirements_path]}"
  end

  # start uwsgi under supervisor
  supervisor_service "uwsgi-#{application}" do
    action [:enable, :restart]
    command "uwsgi --ini-paste-logged #{deploy[:deploy_to]}/current/#{deploy[:uwsgi_ini_path]} -s /tmp/uwsgi-#{application}.sock -H #{deploy[:deploy_to]}/shared/#{application}-env"
    environment deploy[:environment]
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
end
