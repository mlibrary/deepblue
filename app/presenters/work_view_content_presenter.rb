# frozen_string_literal: true

class WorkViewContentPresenter

  attr_accessor :controller

  # delegate :file_name, :work_title, :send_static_content, to: :controller

  def initialize( controller:, file_set:, format: )
    @controller = controller
    @file_set = file_set
    @format = format
  end

  def static_content
    @controller.send_static_content( file_set: @file_set, format: @format )
  end

end