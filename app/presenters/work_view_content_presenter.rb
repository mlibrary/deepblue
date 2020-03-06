# frozen_string_literal: true

class WorkViewContentPresenter

  attr_accessor :controller, :file_set

  # delegate :file_name, :work_title, :send_static_content, to: :controller

  def initialize( controller:, file_set:, format:, options: {} )
    @controller = controller
    @file_set = file_set
    @format = format
    @options = options
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

  def menu_links( work_name, file_set_name )
    @controller.static_content_for( work_name, file_set_name ).split( "\n" )
  end

  def static_content
    @controller.send_static_content( file_set: @file_set, format: @format, options: @options )
  end

end