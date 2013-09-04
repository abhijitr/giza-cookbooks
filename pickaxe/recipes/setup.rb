include_recipe "python"
include_recipe "opsworks_nodejs"
include_recipe "supervisor"

package "libpq-dev" do
  action :install
end

%w{
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
