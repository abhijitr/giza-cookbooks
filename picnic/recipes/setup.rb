include_recipe "supervisor"
include_recipe "java"
include_recipe "solr"

supervisor_service "solr-#{node[:solr][:app_name]}" do
  action [:enable, :restart]
  command "/usr/bin/java -jar start.jar"
  stopsignal "INT"
  directory "#{node[:solr][:home_dir]}/#{node[:solr][:app_name]}"
  autostart false
  user 'solr' 
end 
