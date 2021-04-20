
Deepblue::WorkViewContentService.setup do |config|

  config.documentation_collection_title = "DBDDocumentationCollection"
  config.documentation_work_title_prefix = "DBDDoc-"
  config.documentation_email_title_prefix = "DBDEmail-"
  config.documentation_i18n_title_prefix = "DBDI18n-"
  config.documentation_view_title_prefix = "DBDView-"
  config.interpolation_helper_debug_verbose = false
  config.static_content_controller_behavior_menu_verbose = false
  config.static_content_enable_cache = true
  config.static_controller_redirect_to_work_view_content = false

  DEFAULT_INTERPOLATION_PATTERNS = [
      /%%/,
      /%\{([\w|]+)\}/,                            # matches placeholders like "%{foo} or %{foo|word}"
      /%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps])/  # matches placeholders like "%<foo>.d"
  ].freeze
  INTERPOLATION_PATTERN = Regexp.union(DEFAULT_INTERPOLATION_PATTERNS)

  config.static_content_interpolation_pattern = INTERPOLATION_PATTERN

end
