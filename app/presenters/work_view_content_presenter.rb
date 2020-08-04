# frozen_string_literal: true

class WorkViewContentPresenter

  WORK_VIEW_CONTENT_PRESENTER_DEBUG_VERBOSE = false

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller, :file_set

  delegate :documentation_work_title_prefix,
           :file_name,
           :static_content_menu,
           :static_content_menu_debug_verbose,
           :static_content_menu_file_format,
           :static_content_menu_header,
           :static_content_menu_links,
           :static_content_menu_partial,
           :static_content_page_navigation,
           :work_title, to: :controller

  def initialize( controller:, file_set:, format:, path:, options: {} )
    @controller = controller
    @file_set = file_set
    @format = format
    @options = options
    @path = path
  end

  def current?(path)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "path=#{path}",
                                           "" ] if WORK_VIEW_CONTENT_PRESENTER_DEBUG_VERBOSE
    prefix = documentation_work_title_prefix
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "prefix=#{prefix}",
                                           "work_title=#{work_title}",
                                           "" ] if WORK_VIEW_CONTENT_PRESENTER_DEBUG_VERBOSE
    doc = if work_title =~ /^#{Regexp.escape(prefix)}([a-z-]+)$/
            Regexp.last_match( 1 )
          else
            "$UNKOWN$"
          end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "doc=#{doc}",
                                           "file_name=#{file_name}",
                                           "work_title=#{work_title}",
                                           "" ] if WORK_VIEW_CONTENT_PRESENTER_DEBUG_VERBOSE
    rv = case path
         when "/data/#{doc}"
           true
         when "/data/work_view_content/#{work_title}/#{file_name}"
           true
         else
           false
         end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv=#{rv}",
                                           "" ] if WORK_VIEW_CONTENT_PRESENTER_DEBUG_VERBOSE
    return rv
  end

  def has_menu?
    menu.present?
  end

  def menu
    @options[:menu]
  end

  def menu_header
    rv = @options[:menu_header]
    return 'Missing Header' if rv.blank?
    return MsgHelper.t(rv) if rv =~ /^hyrax\.menu\..+$/
    return rv
  end

  def static_content
    @controller.static_content_send( file_set: @file_set, format: @format, path: @path, options: @options )
  end

end