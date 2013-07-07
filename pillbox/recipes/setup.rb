include_recipe "python"
include_recipe "supervisor"

# Thumbor/Pillow dependencies
%w{
  libcurl4-gnutls-dev
  libtiff4-dev
  libjpeg8-dev
  zlib1g-dev
  libfreetype6-dev
  liblcms1-dev
  libwebp-dev
}.each do |pkg|
  package pkg do
    action :install
  end
end

# Logrotate stuff
package "lzop" do
  action :install
end

python_pip "awscli" do
  action :upgrade
end

cookbook_file "/etc/logrotate.conf" do
  source "logrotate.conf"
  action :create
end

cookbook_file "/etc/logrotate.d/nginx" do
  source "logrotate_nginx"
  action :create
end
