node[:deploy].each do |application, deploy|
  # override default user, which is 'deploy'
  normal[:deploy][application][:user] = 'www-data'
  normal[:deploy][application][:group] = 'www-data'
end