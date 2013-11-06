include_recipe "virtualenv"

node[:deploy].each do |app_name, app|
  unless app.key?[:application]
    Chef::Log.debug("Skipping pickaxe::deploy application #{app_name} as it isn't actually getting deployed")
    next
  end

  unless app[:layers].key?(:pickaxe)
    Chef::Log.debug("Skipping pickaxe::deploy application #{app_name} as it does not require pickaxe")
    next
  end

  layer = app[:layers][:pickaxe]

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
    requirements_file "#{app[:deploy_to]}/current/#{layer[:requirements_path]}"
  end

  # Install all the modules in npm_requirements.txt.
  execute "npm-dependencies-#{app_name}" do
    command "cat #{app[:deploy_to]}/current/#{layer[:npm_requirements_path]} | xargs npm install -g"
    only_if "test -f #{app[:deploy_to]}/current/#{layer[:npm_requirements_path]}"
  end

  supervisor_env = app[:environment].merge({
    "virtualenv_root" => "#{app[:deploy_to]}/shared/#{app_name}-env",
    "HOME" => "/home/#{app[:user]}",
    "USER" => app[:user],
    "USERNAME" => app[:user],
    "LOGNAME" => app[:user],
    "PYTHONPATH" => "#{app[:deploy_to]}/current" 
  })

  # Start worker process under supervisor.
  supervisor_service "worker-#{app_name}" do
    action [:enable, :restart]
    command "#{app[:deploy_to]}/shared/#{app_name}-env/bin/python #{app[:deploy_to]}/current/#{layer[:minion_path]}"
    environment supervisor_env
    stopsignal "TERM"
    stopasgroup true
    directory "#{app[:deploy_to]}/current/pickaxe"
    autostart false
    user app[:user]
  end 
end
