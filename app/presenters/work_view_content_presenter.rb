# frozen_string_literal: true

class WorkViewContentPresenter

  attr_accessor :controller, :file_set

  delegate :documentation_work_title_prefix,
           :file_name,
           :static_content_menu,
           :static_content_menu_file_format,
           :static_content_menu_header,
           :static_content_menu_links,
           :static_content_menu_partial,
           :static_content_page_navigation,
           :work_title, to: :controller

  def initialize( controller:, file_set:, format:, options: {} )
    @controller = controller
    @file_set = file_set
    @format = format
    @options = options
  end

  def current?(path)
    # TODO - Fix this hard coded path
    "/data/work_view_content/#{work_title}/#{file_name}" == path
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
    @controller.static_content_send( file_set: @file_set, format: @format, options: @options )
  end

end