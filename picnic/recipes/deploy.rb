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

  # configure nginx 
  nginx_web_app application do
    application deploy
    template "nginx.erb"
    cookbook "picnic"
  end 
end
