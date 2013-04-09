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

directory node[:solr][:home_dir] do
  owner "solr"
  group "solr"
end

directory node[:solr][:log_dir] do
  owner "solr"
  group node.solr.group
  mode "0775"
  action :create
end

directory File.join(node[:solr][:home_dir], node[:solr][:app_name], 'solr', 'data') do
  owner "solr"
  group node.solr.group
  mode "0775"
  action :create
end

java_ark "solr" do
  url node[:solr][:download_url]
  checksum  node[:solr][:download_checksum]
  app_home node[:solr][:home_dir]
  # bin_cmds ["java", "javac"]
  action :install
end

# Install default templates
%w(schema.xml solrconfig.xml).each do |conf_template|
  template File.join(node[:solr][:home_dir], node[:solr][:app_name], 'solr', 'conf', conf_template) do
    source conf_template
    owner 'solr'
    group 'solr'
    mode '0755'
  end
end
