include_recipe "python"
include_recipe "opsworks_nodejs"
include_recipe "supervisor"

package "libpq-dev" do
  action :install
end

python_pip "uwsgi" do
  action :upgrade
end
