# frozen_string_literal: true

class EmailDashboardPresenter

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def email_template_keys
    keys_updated = ::Deepblue::EmailHelper.t("hyrax.email.templates.keys_loaded" )
    keys_updated.split( "; " )
  end

end