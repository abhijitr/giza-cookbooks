# Based on http://ericholscher.com/blog/2010/nov/9/building-django-app-server-chef-part-2/

define :virtualenv, :action => :create, :owner => "root", :group => "root", :mode => 0755, :packages => {}, :requirements_file => nil, :interpreter => "/usr/bin/python", :find_links => nil do
    path = params[:path] ? params[:path] : params[:name]
    pip = "#{path}/bin/pip"
    log_path = params[:log_path] ? params[:log_path] : path

    if params[:action] == :create
        # Manage the directory.
        directory path do
            owner params[:owner]
            group params[:group]
            mode params[:mode]
        end
        execute "create-virtualenv-#{path}" do
            user params[:owner]
            group params[:group]
            command "virtualenv --distribute -p #{params[:interpreter]} #{path}"
            not_if "test -f #{path}/bin/python"
        end
        params[:packages].each_pair do |package, version|
            execute "install-#{package}-#{path}" do
                user params[:owner]
                group params[:group]
                command "#{pip} install #{package}==#{version}"
                environment 'PIP_DOWNLOAD_CACHE' => '/tmp/PIP_DOWNLOAD_CACHE'
                not_if "[ `#{pip} freeze | grep #{package} | cut -d'=' -f3` = '#{version}' ]"
            end
        end
        if params[:requirements_file]
          execute "install-requirements-file" do
            user params[:owner]
            group params[:group]
            cwd "/tmp"
            if params[:find_links]
                command "#{pip} install --find-links=file://#{params[:find_links]} --no-index --log=#{log_path}/pip.log -r #{params[:requirements_file]}"
            else
                environment 'PIP_DOWNLOAD_CACHE' => '/tmp/PIP_DOWNLOAD_CACHE'
                command "#{pip} install --use-mirrors --log=#{log_path}/pip.log -r #{params[:requirements_file]}"
            end
          end
        end
    elsif params[:action] == :delete
        directory path do
            action :delete
            recursive true
        end
    end
end
