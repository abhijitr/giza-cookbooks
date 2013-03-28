node[:deploy].each do |application, deploy|
  # default env
  default[:deploy][application][:environment] = {}
  
  # override default user, which is 'deploy'
  normal[:deploy][application][:user] = 'www-data'
  normal[:deploy][application][:group] = 'www-data'
end