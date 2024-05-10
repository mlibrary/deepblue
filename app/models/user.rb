# frozen_string_literal: true

class User < ApplicationRecord

  mattr_accessor :user_debug_verbose, default: Rails.configuration.user_debug_verbose

  # Connects this user object to Hydra behaviors.
  include Hydra::User

  # Connects this user object to Role-management behaviors.
  # include Hydra::RoleManagement::UserRoles

  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles if Rails.configuration.user_role_management_enabled

  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  # hyrax-orcid begin
  include Hyrax::Orcid::UserBehavior
  # hyrax-orcid end

  if Rails.configuration.authentication_method == "umich"
    before_validation :generate_password, :on => :create

    def generate_password
      self.password = SecureRandom.urlsafe_base64(12)
      self.password_confirmation = self.password
    end
  end

  # Use the http header as auth.  This app will be behind a reverse proxy
  #   that will take care of the authentication.
  Devise.add_module(:http_header_authenticatable,
                    strategy: true,
                    controller: :sessions,
                    model: 'devise/models/http_header_authenticatable')
  if Rails.configuration.authentication_method == "umich"
    devise :http_header_authenticatable
  end

  if Rails.configuration.authentication_method == "iu"
    devise :omniauthable, :omniauth_providers => [:cas]
  else
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable
  end
  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def user_approver? (user)
    approving_role = Sipity::Role.find_by(name: Hyrax::RoleRegistry::APPROVING)
    return false unless approving_role
    Hyrax::Workflow::PermissionQuery.scope_processing_agents_for(user: user).any? do |agent|
      agent.workflow_responsibilities.joins(:workflow_role)
             .where('sipity_workflow_roles.role_id' => approving_role.id).any?
    end
  end

  # helper for IU auth
  def self.find_for_iu_cas(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create! do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = [auth.uid,'@indiana.edu'].join
      user.encrypted_password = Devise.friendly_token[0,20]
    end
  end

end
