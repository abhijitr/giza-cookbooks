node[:deploy].each do |application, deploy|
  # default env
  default[:deploy][application][:environment] = {}
end