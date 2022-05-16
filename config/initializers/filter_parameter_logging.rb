# Be sure to restart your server when you modify this file.

# puts "\n\nRails.application.config.filter_parameters=#{Rails.application.config.filter_parameters}\n\n"

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]
# Rails.application.config.filter_parameters << lambda do |k, v|
#   puts "k,v=#{k},#{v}"
#   # if k == 'data' && v && v.class == String && v.length > 1024
#   #   v.replace('[FILTER]')
#   # end
# end
#
# puts "\n\nRails.application.config.filter_parameters=#{Rails.application.config.filter_parameters}\n\n"
