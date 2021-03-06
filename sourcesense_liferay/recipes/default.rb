#
# Cookbook Name:: sourcesense_liferay
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
user 'liferay' do
  manage_home true
  comment 'Lifery user!'
  home '/home/liferay'
  shell '/bin/bash'
  uid '1313'
  password '$1$JJsvHslV$szsCjVEroftprNn4JHtDi'
end

directory '/home/liferay/.ssh' do
  owner 'liferay'
  mode 600
end

['authorized_keys',
 'id_rsa',
 'id_rsa.pub'].each do |k|
  cookbook_file "/home/liferay/.ssh/#{k}" do
    source "INSECURE_KEYS/#{k}"
    mode 600
  end
end

group 'liferay'

package %w(unzip rsync)

selinux_state 'SELinux Permissive' do
  action :permissive
end

directory node['sourcesense_liferay']['data_nfs_mount'] do
  owner 'liferay'
  group 'liferay'
  mode 775
end

mount node['sourcesense_liferay']['data_nfs_mount'] do
  device node['sourcesense_liferay']['data_nfs']
  options 'mode=755'
  fstype  'nfs'
  options 'rw'
  action [:mount, :enable]
end

cookbook_file File.join('/opt', node['sourcesense_liferay']['bundle']) do
  owner 'liferay'
  group 'liferay'
  source node['sourcesense_liferay']['bundle']
  action :create_if_missing
end

ark 'liferay' do
  path '/opt'
  url "file://#{File.join('/opt', node['sourcesense_liferay']['bundle'])}"
  checksum node['sourcesense_liferay']['checksum']
  action :put
  backup false
end

directory File.join(node['sourcesense_liferay']['data_nfs_mount'],"document_library") do
  owner 'liferay'
  group 'liferay'
  mode 775
end

directory File.join(node['sourcesense_liferay']['lf_home'], 'deploy') do
  owner 'liferay'
  group 'liferay'
  mode 775
end

directory File.join(node['sourcesense_liferay']['lf_home'], 'cluster_deploy') do
  owner 'liferay'
  group 'liferay'
  mode 775
end

directory File.join(node['sourcesense_liferay']['lf_home'], 'cluster_deploy', 'deploy') do
  owner 'liferay'
  group 'liferay'
  mode 775
end

directory "#{node['sourcesense_liferay']['lf_home']}/tomcat-7.0.62/webapps/ROOT/WEB-INF/classes/myehcache" do
  owner 'liferay'
  group 'liferay'
  mode 775
end

cookbook_file "#{node['sourcesense_liferay']['lf_home']}/tomcat-7.0.62/webapps/ROOT/WEB-INF/classes/myehcache/liferay-multi-vm-clustered.xml" do
  source 'liferay-multi-vm-clustered.xml'
  owner 'liferay'
  group 'liferay'
end

cookbook_file "#{node['sourcesense_liferay']['lf_home']}/tomcat-7.0.62/webapps/ROOT/WEB-INF/classes/myehcache/hibernate-clustered.xml" do
  source 'hibernate-clustered.xml'
  owner 'liferay'
  group 'liferay'
end

template File.join(node['sourcesense_liferay']['lf_home'], 'portal-ext.properties') do
  source 'portal-ext.properties.erb'
  owner 'liferay'
  group 'liferay'
  mode 775
end

cookbook_file File.join(node['sourcesense_liferay']['lf_home'], 'deploy', 'activation-key-development-6.2ee-Sourcense.xml') do
  source 'activation-key-development-6.2ee-Sourcense.xml'
  owner 'liferay'
  group 'liferay'
end

cookbook_file File.join(node['sourcesense_liferay']['lf_home'], 'deploy', 'Liferay_Ehcache_Cluster.lpkg') do
  source 'Liferay_Ehcache_Cluster.lpkg'
  owner 'liferay'
  group 'liferay'
  not_if { File.exists? "/opt/liferay/tomcat-7.0.62/webapps/ehcache-cluster-web" }
end

if node.name == "liferaynode01"

  cookbook_file File.join(node['sourcesense_liferay']['lf_home'], 'deploy', 'Bootcamp2016Startup-hook-6.2.0.1.war') do
   source 'Bootcamp2016Startup-hook-6.2.0.1.war'
   owner 'liferay'
   group 'liferay'
   not_if { File.exists? "/opt/liferay/tomcat-7.0.62/webapps/Bootcamp2016Startup-hook" }
   action :nothing
  end

  cookbook_file File.join(node['sourcesense_liferay']['lf_home'], 'deploy', 'Bootcamp2016-portlet-6.2.0.1.war') do
   source 'Bootcamp2016-portlet-6.2.0.1.war'
   owner 'liferay'
   group 'liferay'
   action :nothing
  end

end

execute 'StartLiferay' do
  command './startup.sh'
  user 'liferay'
  cwd File.join(node['sourcesense_liferay']['lf_home'], 'tomcat-7.0.62', 'bin')
  not_if 'timeout 2 bash -c "</dev/tcp/localhost/8080"'
end
