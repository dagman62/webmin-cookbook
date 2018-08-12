node.default['portnum'] = '10000'
platform = node['platform']
if platform == 'fedora'
  node.default['distro'] = 'rhel'
else
  node.default['distro'] = node['platform']
end
