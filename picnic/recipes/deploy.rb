include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |app_name, app|
  unless app.key?(:application)
    Chef::Log.debug("Skipping picnic::deploy application #{app_name} as it isn't actually getting deployed")
    next
  end

  unless app[:layers].key?(:picnic)
    Chef::Log.debug("Skipping picnic::deploy application #{app_name} as it does not require picnic")
    next
  end

  layer = app[:layers][:picnic]

  opsworks_deploy_dir do
    user app[:user]
    group app[:group]
    path app[:deploy_to]
  end

  opsworks_deploy do
    app app_name 
    deploy_data app
  end

  # configure nginx 
  nginx_web_app app_name do
    application app
    template "nginx.erb"
    cookbook "picnic"
  end 
end
