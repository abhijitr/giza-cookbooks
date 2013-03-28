include_recipe "virtualenv"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'static'
    Chef::Log.debug("Skipping deploy::web application #{application} as it is not an static HTML app")
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
end
