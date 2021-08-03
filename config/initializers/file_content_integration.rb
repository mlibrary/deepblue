
Deepblue::FileContentHelper.setup do |config|

  config.file_content_helper_debug_verbose = false

  # read_me file set config
  config.read_me_file_set_enabled = true
  config.read_me_file_set_auto_read_me_attach = true
  config.read_me_file_set_file_name_regexp = /read[_ ]?me/i
  config.read_me_file_set_view_max_size = 500.kilobytes
  config.read_me_file_set_view_mime_types = [ "text/plain", "text/markdown", "text/html" ].freeze
  config.read_me_file_set_ext_as_html = [ ".md" ].freeze
  config.read_me_max_find_file_sets = 40

end
