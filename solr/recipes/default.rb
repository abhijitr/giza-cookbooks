include_recipe "java"

Encoding.default_external = Encoding::UTF_8 if RUBY_VERSION > "1.9"

group "solr" do
  gid 9000
end

user "solr" do
  uid 9000
  gid "solr"
  system true
  home node[:solr][:home_dir]
  shell "/bin/bash"
end

directory node[:solr][:log_dir] do
  owner "solr"
  group node.solr.group
  mode "0775"
  action :create
end

directory node[:solr][:home_dir] do
  owner "solr"
  group node.solr.group
  mode "0775"
  action :create
  recursive true
end

=begin
Bah... can't use ark right now because opsworks uses an old version of Chef.
Instead we must download/install solr manually

java_ark "solr" do
  url node[:solr][:download_url]
  checksum  node[:solr][:download_checksum]
  app_home node[:solr][:home_dir]
  # bin_cmds ["java", "javac"]
  action :install
end
=end

remote_file "#{Chef::Config[:file_cache_path]}/#{node[:solr][:tarball_name]}.tgz" do
  action :create_if_missing
  source node[:solr][:download_url]
  checksum node[:solr][:download_checksum]
  owner "solr"
  mode "0755"
end

bash "extract_solr" do
  cwd "#{Chef::Config[:file_cache_path]}"
  code "tar -xzf #{Chef::Config[:file_cache_path]}/#{node[:solr][:tarball_name]}.tgz && mv #{Chef::Config[:file_cache_path]}/#{node[:solr][:tarball_name]}/* #{node[:solr][:home_dir]}/ && chown -R solr #{node[:solr][:home_dir]}"
  not_if do
    File.exists? "#{node[:solr][:home_dir]}/README.txt"
  end
end

bash "copy_example" do
  user "solr"
  code "cp -Rf #{node[:solr][:home_dir]}/example #{node[:solr][:home_dir]}/#{node[:solr][:app_name]}"
  not_if do
    File.directory? "#{node[:solr][:home_dir]}/#{node[:solr][:app_name]}"
  end
end

# Install default templates
%w(schema.xml solrconfig.xml data-import-config.xml).each do |conf_template|
  template File.join(node[:solr][:home_dir], node[:solr][:app_name], 'solr', 'collection1', 'conf', conf_template) do
    owner 'solr'
    group 'solr'
    mode '0755'
  end
end
