node[:deploy].each do |application, deploy|
  # Default env.
  default[:deploy][application][:environment] = {}
end
