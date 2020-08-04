# frozen_string_literal: true

class GuestUserMessagePresenter

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller

  def initialize( controller: )
    @controller = controller
  end

end