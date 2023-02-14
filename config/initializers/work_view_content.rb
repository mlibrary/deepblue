
Deepblue::WorkViewContentService.setup do |config|

  config.interpolation_helper_debug_verbose = false
  config.static_content_cache_debug_verbose = false
  config.static_content_controller_behavior_verbose = false
  config.static_content_controller_behavior_menu_verbose = false
  config.work_view_content_service_debug_verbose = false
  config.work_view_content_service_email_templates_debug_verbose = false
  config.work_view_content_service_i18n_templates_debug_verbose = false
  config.work_view_content_service_view_templates_debug_verbose = false
  config.work_view_documentation_controller_debug_verbose = false

  config.documentation_collection_title = "DBDDocumentationCollection"
  config.documentation_work_title_prefix = "DBDDoc-"
  config.documentation_email_title_prefix = "DBDEmail-"
  config.documentation_i18n_title_prefix = "DBDI18n-"
  config.documentation_view_title_prefix = "DBDView-"
  if Rails.env.development?
    config.export_documentation_path = './data/documentation_export'
  elsif Rails.env.test?
    config.export_documentation_path = '/tmp/documentation_export'
  else # production
    config.export_documentation_path = '/deepbluedata-dataden/download-prep/documentation_export/'
  end
  begin
    FileUtils.mkdir_p config.export_documentation_path unless Dir.exist? config.export_documentation_path
  rescue Exception => e # rubocop:disable Lint/RescueException
    # ignore -- this will fail on deployment to testing server, but we don't care
  end  
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
