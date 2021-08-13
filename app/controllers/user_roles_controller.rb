# frozen_string_literal: true

# Controller for managing Roles for Users
class UserRolesController < ApplicationController
  begin
    include Hyrax::Admin::UsersControllerBehavior
  rescue NameError
    before_action :authenticate_user!
  end
  include Hydra::RoleManagement::UserRolesBehavior
end
