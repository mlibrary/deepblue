# frozen_string_literal: true

module AdminOnlyControllerBehavior

  def ensure_admin!
    raise CanCan::AccessDenied unless current_ability.admin?
    authorize! :read, :admin_dashboard
  end

end
