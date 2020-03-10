# frozen_string_literal: true

class WorkViewContentPresenter

  attr_accessor :controller, :file_set

  delegate :file_name, :menu_links, :menu_partial, :page_navigation, :work_title, to: :controller

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
    @controller.send_static_content( file_set: @file_set, format: @format, options: @options )
  end

end