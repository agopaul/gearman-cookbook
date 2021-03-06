#
# Cookbook Name:: gearman
# Recipe:: server
#
# Copyright 2011, Cramer Development
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

packages = value_for_platform(
  %w{ debian } => {
    :default => %w{build-essential libboost-program-options-dev libevent-1.4-2 libtokyocabinet8 }
  },
  %w{ centos redhat } => {
    :default => []
  }
)

file_to_install = value_for_platform(
  %w{ debian } => { :default => 'gearmand_1.0.2-1_amd64.deb' },
  %w{ centos redhat } => { :default => 'todo.rpm' }
)

install_command = value_for_platform(
  %w{ debian } => { :default => 'dpkg -i' },
  %w{ centos redhat } => { :default => 'rpm -Uvh' }
)

remote_file "#{Chef::Config[:file_cache_path]}/#{file_to_install}" do
  source "https://github.com/agopaul/deb-packages/raw/master/#{file_to_install}"
  action :create_if_missing
end

package 'libgearman-dev gearman-job-server' do
  action :remove
end

packages.each do |pkg|
  package pkg
end

execute "#{install_command} #{Chef::Config[:file_cache_path]}/#{file_to_install}" do
  creates '/usr/sbin/gearmand'
end

user node['gearman']['server']['user'] do
  comment 'Gearman Job Server'
  shell '/bin/false'
end

group node['gearman']['server']['group'] do
  members [node['gearman']['server']['user']]
end

directory node['gearman']['server']['log_dir'] do
  owner node['gearman']['server']['user']
  group node['gearman']['server']['group']
  mode '0775'
end

logrotate_app 'gearmand' do
  path "#{node['gearman']['server']['log_dir']}/*.log"
  frequency 'daily'
  rotate 4
  create "600 #{node['gearman']['server']['user']} #{node['gearman']['server']['group']}"
end

case node['platform']
when 'debian'
  template '/etc/init.d/gearman-job-server' do source 'gearmand.upstart.erb'
    owner 'root'
    group 'root'
    mode '0744'
    notifies :restart, 'service[gearman-job-server]'
  end

  service 'gearman-job-server' do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :status => true
    action [:enable, :start]
  end
when 'centos', 'redhat'
  include_recipe 'supervisor'
  supervisor_service 'gearmand' do
    start_command "/usr/sbin/gearmand #{args}"
    variables :user => node['gearman']['server']['user']
    supports :restart => true
    action [:enable, :start]
  end
end
