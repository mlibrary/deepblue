# frozen_string_literal: true

class WorkViewContentPresenter

  attr_accessor :controller

  delegate :file_name, :work_title, to: :controller

  def initialize( controller: )
    @controller = controller
  end

end