# frozen_string_literal: true

module Deepblue

  module ThreadedVarService

    mattr_accessor :threaded_var_service_debug_verbose, default: true

    mattr_accessor :threaded_var_service_autoload, default: true

    THREADED_VAR_EMAIL_TEMPLATES = 'THREADED_VAR_EMAIL_TEMPLATES' unless const_defined? :THREADED_VAR_EMAIL_TEMPLATES
    THREADED_VAR_I18N_TEMPLATES = 'THREADED_VAR_I18N_TEMPLATES' unless const_defined? :THREADED_VAR_I18N_TEMPLATES
    THREADED_VAR_VIEW_TEMPLATES = 'THREADED_VAR_VIEW_TEMPLATES' unless const_defined? :THREADED_VAR_VIEW_TEMPLATES
    THREADED_VAR_IDS = [ THREADED_VAR_EMAIL_TEMPLATES,
                         THREADED_VAR_I18N_TEMPLATES,
                         THREADED_VAR_VIEW_TEMPLATES ] unless const_defined? :THREADED_VAR_IDS

    @@threaded_var_loaders = { THREADED_VAR_EMAIL_TEMPLATES => '::Deepblue::EmailTemplatesLoader',
                               THREADED_VAR_I18N_TEMPLATES => '::Deepblue::I18nTemplatesLoader',
                               THREADED_VAR_VIEW_TEMPLATES => '::Deepblue::ViewTemplatesLoader' }
    @@threaded_var_semaphores = {}
    # THREADED_VAR_IDS.each { |id| @@threaded_var_semaphores[id] = DateTime.now }

    @@threaded_var_last_loaded_in_thread = {}

    def self.initialize_cached_threaded_var_semaphores
      puts "::Deepblue::ThreadedVarService.initialize_cached_threaded_var_semaphores"
      THREADED_VAR_IDS.each { |id| touch_semaphore id }
    end

    def self.ensure_threaded_var_is_fresh( threaded_var_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "threaded_var_id=#{threaded_var_id}",
                                             "" ] if threaded_var_service_debug_verbose
      threaded_var_load( threaded_var_ids: [threaded_var_id] )
    end

    def self.ensure_email_templates_are_fresh
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if threaded_var_service_debug_verbose
      threaded_var_load( threaded_var_ids: [THREADED_VAR_EMAIL_TEMPLATES] )
    end

    def self.ensure_i18n_templates_are_fresh
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if threaded_var_service_debug_verbose
      threaded_var_load( threaded_var_ids: [THREADED_VAR_I18N_TEMPLATES] )
    end

    def self.ensure_view_templates_are_fresh
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if threaded_var_service_debug_verbose
      threaded_var_load( threaded_var_ids: [THREADED_VAR_VIEW_TEMPLATES] )
    end

    def self.threaded_var_autoload( debug_verbose: threaded_var_service_debug_verbose )
      threaded_var_load( threaded_var_ids: THREADED_VAR_IDS,
                         debug_verbose: debug_verbose ) if threaded_var_service_autoload
    end

    def self.threaded_var_load?( threaded_var_id:, debug_verbose: threaded_var_service_debug_verbose )
      debug_verbose ||= threaded_var_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "threaded_var_id=#{threaded_var_id}",
                                             "" ] if threaded_var_service_debug_verbose
      last_loaded_in_thread = @@threaded_var_last_loaded_in_thread[threaded_var_id]
      return true if last_loaded_in_thread.nil?
      semaphore = threaded_var_semaphore_get threaded_var_id
      return true if semaphore.nil?
      return last_loaded_in_thread < semaphore
    end

    def self.threaded_var_load( threaded_var_ids:, debug_verbose: threaded_var_service_debug_verbose )
      debug_verbose ||= threaded_var_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "threaded_var_ids=#{threaded_var_ids}",
                                             "" ] if debug_verbose
      threaded_var_ids.each do |id|
        next unless threaded_var_load?( threaded_var_id: id, debug_verbose: debug_verbose )
        klass = @@threaded_var_loaders[id]
        next if klass.blank?
        if klass.is_a? String
          klass = klass.constantize
          @@threaded_var_loaders[id] = klass
        end
        loader = klass.new
        loader.load( debug_verbose: debug_verbose )
        touch_last_loaded id
      end
      return true
    end

    def self.threaded_var_load_all( debug_verbose: threaded_var_service_debug_verbose )
      threaded_var_load( threaded_var_ids: THREADED_VAR_IDS, debug_verbose: debug_verbose )
    end

    def self.threaded_var_semaphore_get(var, default_value: nil)
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "" ] if threaded_var_service_debug_verbose
      if Rails.env.production?
        ::Deepblue::CacheService.var_cache_fetch( klass: ThreadedVarService, var: var, default_value: default_value )
      else
        @@threaded_var_semaphores[var]
      end
    end

    def self.threaded_var_semaphore_set(var, value)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "var=#{var}",
                                             "value=#{value}",
                                             "" ] if threaded_var_service_debug_verbose
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_write( klass: threaded_var_semaphores, var: var, value: value )
      else
        @@threaded_var_semaphores[var] = value
      end
    end

    def self.touch_last_loaded(threaded_var_id)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "threaded_var_id=#{threaded_var_id}",
                                             "" ] if threaded_var_service_debug_verbose
      @@threaded_var_last_loaded_in_thread[threaded_var_id] = DateTime.now
    end

    def self.touch_semaphore(threaded_var_id)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "threaded_var_id=#{threaded_var_id}",
                                             "" ] if threaded_var_service_debug_verbose
      threaded_var_semaphore_set( threaded_var_id, DateTime.now )
    end

  end

end
