# frozen_string_literal: true

# due to double redirecting for guest users (those who aren't logged in) when directing them back to
# the main app window, the flash message is lost
# so create a specialized window for displaying messages
class GuestUserMessageController < ApplicationController

  class_attribute :presenter_class
  self.presenter_class = GuestUserMessagePresenter

  def show
    @presenter = presenter_class.new( controller: self )
    render '/guest_user_message'
  end

end
