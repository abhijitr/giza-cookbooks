include_recipe "python"
include_recipe "supervisor"

package "redis-server" do
  action :install
end
