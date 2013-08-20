include_recipe "virtualenv"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'pickaxe'
    Chef::Log.debug("Skipping deploy::web application #{application} as it is not a pickaxe app")
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

  # Install all the modules in npm_requirements.txt.
  execute "npm-dependencies-#{application}" do
    command "cat #{deploy[:deploy_to]}/current/#{deploy[:npm_requirements_path]} | xargs npm install -g"
    only_if "test -f #{deploy[:deploy_to]}/current/#{deploy[:npm_requirements_path]}"
  end

  supervisor_env = deploy[:environment].merge({
    "virtualenv_root" => "#{deploy[:deploy_to]}/shared/#{application}-env",
    "HOME" => "/home/#{deploy[:user]}",
    "USER" => deploy[:user],
    "USERNAME" => deploy[:user],
    "LOGNAME" => deploy[:user]
  })

  # Start worker process under supervisor.
  supervisor_service "worker-#{application}" do
    action [:enable, :restart]
    command "#{deploy[:deploy_to]}/shared/#{application}-env/bin/python #{deploy[:deploy_to]}/current/scrapy/worker/run.py"
    environment supervisor_env
    stopsignal "TERM"
    stopasgroup true
    directory "#{deploy[:deploy_to]}/current"
    autostart false
    user deploy[:user]
  end 
end
