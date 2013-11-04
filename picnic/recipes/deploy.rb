include_recipe "nginx::service"
include_recipe "virtualenv"

node[:deploy].each do |app_name, app|
  if app[:application_type] != 'giza'
    Chef::Log.debug("Skipping picnic::deploy application #{app_name} as it is not a giza app")
    next
  end

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
