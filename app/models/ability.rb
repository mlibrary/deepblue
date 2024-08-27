# frozen_string_literal: true
# Reviewed: heliotrope

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  mattr_accessor :ability_debug_verbose, default: Rails.configuration.ability_debug_verbose

  self.ability_logic += [:everyone_can_create_curation_concerns]
  self.ability_logic += [:deepblue_abilities]

  def deepblue_abilities
    can [:doi], ActiveFedora::Base

    alias_action :analytics_subscribe,       to: :update
    alias_action :analytics_unsubscribe,     to: :update
    alias_action :create_anonymous_link,     to: :update
    alias_action :create_single_use_link,    to: :update
    alias_action :display_provenance_log,    to: :read
    alias_action :file_contents,             to: :read
    alias_action :globus_add_email,          to: :read
    alias_action :globus_clean_download,     to: :delete
    alias_action :globus_download,           to: :read
    alias_action :globus_download_add_email, to: :read
    alias_action :globus_download_notify_me, to: :read
    alias_action :globus_download_redirect,  to: :read
    alias_action :ingest_append_script_generate, to: :read
    alias_action :ingest_append_script_prep,        to: :read
    alias_action :ingest_append_script_run_job,     to: :update
    alias_action :tombstone,                 to: :delete
    alias_action :zip_download,              to: :read

    # alias_action :confirm,                   to: :read
    # alias_action :identifiers,               to: :update
  end

  # Define any customized permissions here.
  def custom_permissions
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if ability_debug_verbose
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end

    if Rails.configuration.user_role_management_enabled
      if Rails.configuration.user_role_management_admin_only
        if current_user.admin?
          can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role
        end
      else
        can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role
      end
    end

  end

end
