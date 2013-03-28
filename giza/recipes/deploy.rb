include_recipe "virtualenv"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'other'
    Chef::Log.debug("Skipping deploy::web application #{application} as it is not a giza app")
    next
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
    requirements_file "#{deploy[:deploy_to]}/current/requirements.txt"
  end

  # install all the modules in npm_requirements.txt
  execute "npm-dependencies-#{application}" do
    command "cat #{deploy[:deploy_to]}/current/npm_requirements.txt | xargs npm install -g"
    only_if "test -f #{deploy[:deploy_to]}/current/npm_requirements.txt"
  end

  # start uwsgi under supervisor
  supervisor_service "uwsgi-#{application}" do
    action [:enable, :restart]
    command "uwsgi --ini-paste-logged production.ini -s /tmp/uwsgi-#{application}.sock -H #{deploy[:deploy_to]}/shared/#{application}-env"
    environment deploy[:environment]
    stopsignal "INT"
    directory "#{deploy[:deploy_to]}/current"
    autostart false
    user deploy[:user] 
  end 

  # reconfigure nginx to override the opsworks defaults
  nginx_web_app application do
    application deploy
    template "nginx.erb"
    cookbook "giza"
  end 
end
