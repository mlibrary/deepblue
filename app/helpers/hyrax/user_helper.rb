# frozen_string_literal: true

module Hyrax

  module UserHelper

    mattr_accessor :user_helper_debug_verbose, default: false
    mattr_accessor :user_helper_persist_roles_debug_verbose, default: false

    def self._hyrax_roles_init
      roles = { 'admin' => 'Administrator' }
      roles.merge! ::Hyrax::RoleRegistry::MAGIC_ROLES.dup
      roles
    end

    mattr_accessor :hyrax_roles, default: _hyrax_roles_init

    def self.ensure_hyrax_roles_registered( from_initializer: false,
                                            debug_verbose: user_helper_persist_roles_debug_verbose || user_helper_debug_verbose )

      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "" ], bold_puts: from_initializer ) if debug_verbose
      persist_registered_roles!( roles: hyrax_roles, from_initializer: from_initializer )
    end

    def self.ensure_role_map_registered( from_initializer: false,
                                         debug_verbose: user_helper_persist_roles_debug_verbose || user_helper_debug_verbose )

      return unless Rails.configuration.user_role_management_register_from_role_map
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "" ], bold_puts: from_initializer ) if debug_verbose
      role_map = load_role_map
      roles = {}
      role_map.each do |role, _users|
        roles[role] = "#{role} from role_map"
      end
      persist_registered_roles!( roles: roles, from_initializer: from_initializer )
      if Rails.configuration.user_role_management_enabled
        ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                ::Deepblue::LoggingHelper.called_from,
                                                "Rails.configuration.user_role_management_enabled=#{Rails.configuration.user_role_management_enabled}",
                                                "" ], bold_puts: from_initializer ) if debug_verbose
        role_map.each do |role_name, users|
          role = Role.find_by( name: role_name )
          users.each do |email|
            ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "role_name=#{role_name}",
                                                    "email=#{email}",
                                                    "" ], bold_puts: from_initializer ) if debug_verbose
            user = ::User.find_by_user_key email
            if user.present?
              ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                      ::Deepblue::LoggingHelper.called_from,
                                                      "register user=#{email} with role #{role_name}",
                                                      "" ], bold_puts: from_initializer ) if debug_verbose
              RolesUser.find_or_create_by( role_id: role.id, user_id: user.id )
            else
              ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                      ::Deepblue::LoggingHelper.called_from,
                                                      "skipping unregistered user=#{email} with role #{role_name}",
                                                      "" ], bold_puts: from_initializer ) if debug_verbose
            end
          end
        end
      end
    end

    def self.find_user
      ::User.send("find_by_#{find_user_find_column}".to_sym, params[:user_key])
    end

    def self.find_user_find_column
      Devise.authentication_keys.first
    end

    def self.load_role_map( env: Rails.env, raise_exception: true )
      require 'erb'
      require 'yaml'

      filename = 'config/role_map.yml'
      file = File.join(Rails.root, filename)

      unless File.exists?(file)
        return {} unless raise_exception
        raise "You are missing a role map configuration file: #{filename}. Have you run \"rails generate hydra:head\"?"
      end

      begin
        erb = ERB.new(IO.read(file)).result(binding)
      rescue
        return {} unless raise_exception
        raise("#{file} was found, but could not be parsed with ERB. \n#{$!.inspect}")
      end

      begin
        yml = YAML::load(erb)
      rescue
        return {} unless raise_exception
        raise("#{filename} was found, but could not be parsed.\n")
      end

      unless yml.is_a? Hash
        return {} unless raise_exception
        raise("#{filename} was found, but was blank or malformed.\n")
      end

      roles = yml.fetch( env )
      return {} if roles.nil? && raise_exception
      raise "No roles were found for the #{env} environment in #{file}" unless roles
      roles
    end

    def self.persist_registered_roles!( roles:,
                                        from_initializer: false,
                                        debug_verbose: user_helper_persist_roles_debug_verbose || user_helper_debug_verbose )

      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "roles=#{roles}",
                                              "" ], bold_puts: from_initializer ) if debug_verbose
      roles.each do |name, description|
        ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                ::Deepblue::LoggingHelper.called_from,
                                                "name,description=#{name},#{description}",
                                                "" ], bold_puts: from_initializer ) if debug_verbose
        Sipity::Role.find_or_create_by!(name: name).tap do |role|
          ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "role.class.name=#{role.class.name}",
                                                  "role.description=#{role.description}",
                                                  "" ], bold_puts: from_initializer ) if debug_verbose
          if role.description.blank?
            role.description = description
            role.save!
          end
        end
        if Rails.configuration.user_role_management_enabled
          ::Role.find_or_create_by( name: name ).tap do |role|
            ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "role.class.name=#{role.class.name}",
                                                    "role.description=#{role.description}",
                                                    "" ], bold_puts: from_initializer ) if debug_verbose
            if role.description.blank?
              role.description = description
              role.save!
            end
          end
        end
      end
    end


  end

end
