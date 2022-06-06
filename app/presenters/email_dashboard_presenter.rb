# frozen_string_literal: true

class EmailDashboardPresenter

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller, :current_ability

  delegate :begin_date, :end_date, to: :controller

  delegate  :log_entries, :log_parse_entry, :log_key_values_to_table, to: :controller

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def email_template_keys
    keys_updated = ::Deepblue::EmailHelper.t("hyrax.email.templates.keys_loaded" )
    keys_updated.split( "; " )
  end

end