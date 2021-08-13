# frozen_string_literal: true

# Controller for managing Roles
class RolesController < ApplicationController
  begin
    include Hyrax::Admin::UsersControllerBehavior
  rescue NameError
    before_action :authenticate_user!
  end
  include Hydra::RoleManagement::RolesBehavior
end
