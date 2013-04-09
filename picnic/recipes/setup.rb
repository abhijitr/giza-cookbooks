include_recipe "supervisor"
include_recipe "java"
include_recipe "solr"

%w{
  libjpeg62-dev
  libzip-dev
  libevent-dev
}.each do |pkg|
  package pkg do
    action :install
  end
end

supervisor_service "solr-#{node[:solr][:app_name]}" do
  action [:enable, :restart]
  command "/usr/bin/java -jar start.jar"
  stopsignal "INT"
  directory "#{node[:solr][:home_dir]}/#{node[:solr][:app_name]}"
  autostart false
  user 'solr' 
end 
