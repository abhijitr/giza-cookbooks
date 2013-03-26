#
# Cookbook Name:: virtualenv
# Recipe:: default
#
# Copyright 2010, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute

include_recipe "python"

script "install_pip_and_virutalenv" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  pip install virtualenv
  EOH
  not_if "which pip && which virtualenv"
end
