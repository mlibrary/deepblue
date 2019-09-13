# frozen_string_literal: true

class GuestUserMessagePresenter

  attr_accessor :controller

  def initialize( controller: )
    @controller = controller
  end

end