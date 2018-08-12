#
# Cookbook:: webmin
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

platform = node['platform']

if platform == 'centos' || platform == 'fedora'
  bash 'Give Webmin Permissions to use Nginx' do
    code <<-EOH
    setsebool -P httpd_can_network_relay 1
    setsebool -P httpd_can_network_connect 1
    setsebool -P httpd_can_network_connect_db 1
    setsebool -P allow_user_mysql_connect 1
    touch /tmp/setsebool
    EOH
    action :run
    not_if { File.exist?('/tmp/setsebool') }
  end

  execute 'Install Webmin Key' do
    command 'wget http://www.webmin.com/jcameron-key.asc && rpm --import jcameron-key.asc | tee -a /tmp/jcameron-key'
    not_if { File.exist?('/tmp/jcameron-key') }
  end

  cookbook_file '/etc/yum.repos.d/webmin.repo' do
    source 'webmin.repo'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  bash 'Update Repository Cache' do
    code <<-EOH
    yum makecache && yum update -y
    touch /tmp/update-repo
    EOH
    action :run
    not_if { File.exist?('/tmp/update-repo') }
  end

  package %w(webmin perl-CPAN perl-Digest-MD5 perl-Crypt-PasswdMD5.noarch) do
    action :install
  end

  execute 'Change Webmin to HTTP' do
    command 'perl -pi -e "s/ssl=1/ssl=0/g" /etc/webmin/miniserv.conf | tee -a /tmp/miniserv'
    not_if { File.exist?('/tmp/miniserv') }
  end

  template '/etc/webmin/config' do
    source 'config.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :fqdn => node['fqdn'],
    })
    action :create
  end

  bash 'Startup Webmin' do
    code <<-EOH
    /etc/init.d/webmin restart
    EOH
    action :run
  end

  template '/etc/yum.repos.d/nginx.repo' do
    source 'nginx.repo.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :distro => node['distro'],
    })
    action :create
  end

  bash 'Recreate cache and Update The Repoistory' do
    code <<-EOH
    yum makecache
    yum update -y
    touch /tmp/nginx-update
    EOH
    action :run
    not_if { File.exist?('/tmp/nginx-update') }
  end

  package 'nginx' do
    action :install
  end

  template '/etc/nginx/conf.d/default.conf' do
    source 'webmin.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :fqdn    => node['fqdn'],
      :portnum => node['portnum'],
    })
    action :create
  end

  service 'nginx' do
    action [:start, :enable]
  end
elsif platform == 'ubuntu' || platform == 'debian'
  bash 'Install Webmin Repo' do
    code <<-EOH
    sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
    wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    apt-get update
    touch /tmp/webmin-repo
    EOH
    action :run
    not_if { File.exist?('/tmp/webmin-repo') }
  end

  package %w(webmin libdigest-perl-md5-perl) do
    action :install
  end

  execute 'Change Webmin to HTTP' do
    command 'perl -pi -e "s/ssl=1/ssl=0/g" /etc/webmin/miniserv.conf | tee -a /tmp/miniserv'
    not_if { File.exist?('/tmp/miniserv') }
  end

  template '/etc/webmin/config' do
    source 'config.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :fqdn => node['fqdn'],
    })
    action :create
  end

  service 'webmin' do
    action :restart
  end

  package 'nginx' do
    action :install
  end

  template '/etc/nginx/conf.d/default.conf' do
    source 'webmin.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :fqdn    => node['fqdn'],
      :portnum => node['portnum'],
    })
    action :create
  end

  cookbook_file '/etc/nginx/nginx.conf' do
    source 'nginx.conf'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
  
  service 'nginx' do
    action [:start, :enable]
  end
end
