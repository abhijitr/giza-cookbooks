include_recipe "python"
include_recipe "opsworks_nodejs"
include_recipe "supervisor"

package "libpq-dev" do
  action :install
end
