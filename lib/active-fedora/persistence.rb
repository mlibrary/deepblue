# frozen_string_literal: true

# require File.join(Gem::Specification.find_by_name("active-fedora").full_gem_path, "lib/active-fedora/persistence.rb")
#
# module ActiveFedora
#
#   # monkey patch ActiveFedora::Persistence
#   module Persistence
#     alias_method :monkey_update, :update
#
#     def update( attributes )
#       Rails.logger.debug "ActiveFedora::Persistence.update(#{ActiveSupport::JSON.encode attributes})"
#       if respond_to? :provenance_attribute_values_before_update
#         provenance_attribute_values_before_update = provenance_attribute_values_for_update( current_user: '' )
#         Rails.logger.debug ">>>>>>"
#         Rails.logger.debug "provenance_log_update_before"
#         Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
#         Rails.logger.debug ">>>>>>"
#       end
#
#       monkey_update( attributes )
#
#       if respond_to? :provenance_attribute_values_before_update
#         Rails.logger.debug ">>>>>>"
#         Rails.logger.debug "provenance_log_update_after"
#         Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
#         Rails.logger.debug ">>>>>>"
#         provenance_update( current_user: '',
#                            provenance_attribute_values_before_update: provenance_attribute_values_before_update )
#       end
#     end
#
#   end
#
# end
