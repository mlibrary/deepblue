# frozen_string_literal: true

module Deepblue

  module IngestAppendScriptControllerBehavior

    mattr_accessor :ingest_append_scripts_controller_behavior_debug_verbose,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_scripts_controller_behavior_debug_verbose

    mattr_accessor :ingest_append_scripts_controller_behavior_writer_debug_verbose, default: false

    mattr_accessor :ingest_append_ui_allow_scripts_to_run,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_ui_allow_scripts_to_run

    mattr_accessor :ingest_append_script_allow_delete_any_script,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_ui_allow_scripts_to_run

    mattr_accessor :ingest_append_script_max_appends,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_script_max_appends
    mattr_accessor :ingest_append_script_max_restarts_base,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_script_max_restarts_base
    mattr_accessor :ingest_append_script_monitor_wait_duration,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_script_monitor_wait_duration

    attr_reader :ingest_script

    def active_ingest_append_script
      @active_ingest_append_script = active_ingest_append_script_init
    end

    def active_ingest_append_script_init
      paths = IngestScript.ingest_append_script_files( id: params[:id], active_only: true )
      return File.join paths[0] if paths.present?
      return ''
    end

    def generate_depth( depth: )
      return '' if depth < 1
      return '  ' * (2 * depth)
    end

    def generate_ingest_append_script
      ingest_script_messages # make sure it is initialized
      script = []
      depth = 0
      script << "# #{ingest_script_title}"
      script << "# script dir: #{::Deepblue::IngestIntegrationService.ingest_script_dir}"
      script << "---"
      script << ":user:"
      depth += 1
      script << "#{generate_depth( depth: depth )}:visibility: #{ingest_visibility}"
      script << "#{generate_depth( depth: depth )}:email: '#{ingest_depositor}'"
      script << "#{generate_depth( depth: depth )}:ingester: '#{ingest_ingester}'"
      script << "#{generate_depth( depth: depth )}:depositor: '#{ingest_depositor}'"
      script << "#{generate_depth( depth: depth )}:source: DBDv2"
      script << "#{generate_depth( depth: depth )}:mode: append"
      # :email_after_add_log_msgs: true
      script << "#{generate_depth( depth: depth )}:email_before: #{ingest_email_before}"
      script << "#{generate_depth( depth: depth )}:email_after: #{ingest_email_after}"
      script << "#{generate_depth( depth: depth )}:email_ingester: #{ingest_email_ingester}"
      script << "#{generate_depth( depth: depth )}:email_depositor: #{ingest_email_depositor}"
      emails_rest = ingest_email_rest_emails
      if emails_rest.size > 0
        script << "#{generate_depth( depth: depth )}:email_rest: #{ingest_email_rest}"
        script << "#{generate_depth( depth: depth )}:emails_rest:"
        depth += 1
        emails_rest.each do |email|
          script << "#{generate_depth( depth: depth )}- '#{email.strip}'"
        end
        depth -= 1
      end
      script << "#{generate_depth( depth: depth )}:works:"
      depth += 1
      script << "#{generate_depth( depth: depth )}:id: '#{curation_concern.id}'"
      script << "#{generate_depth( depth: depth )}:depositor: '#{ingest_depositor}'"
      # :owner: 'fritx@umich.edu'
      script << "#{generate_depth( depth: depth )}:filenames:"
      files = ingest_file_path_list.split("\n")
      files.sort!
      files = files.reject { |f| f =~ /^\s+$/ } # remove blank lines
      depth += 1
      @ingest_script_messages << "WARNING: No files found or specified." if files.blank?
      file_count_comment_written = false
      files.each do |f|
        unless file_count_comment_written
          script << "#{generate_depth( depth: depth )}# #{files.size} file(s) found"
          file_count_comment_written = true
        end
        f.strip!
        filename = ingest_file_path_name( f )
        msg = ingest_file_path_msg( f )
        @ingest_script_messages << "'#{filename}' - #{msg}" if msg.present?
        script << "#{generate_depth( depth: depth )}- '#{filename}' # #{msg}" if f.present?
      end
      depth -= 1
      script << "#{generate_depth( depth: depth )}:files:"
      depth += 1
      files.each do |f|
        script << "#{generate_depth( depth: depth )}- '#{f}'" if f.present?
      end
      script << "# end script"
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        ::Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@ingest_script_messages=#{@ingest_script_messages}",
      #                                        "ingest_script_messages=#{ingest_script_messages}",
      #                                        "script=#{script.join( "\n" )}",
      #                                        "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      return script.join( "\n" )
    end

    def ingest_allowed_base_directories
      @ingest_allowed_base_directories ||= ingest_allowed_base_directories_init
    end

    def ingest_allowed_base_directories_init
      dirs = ::Deepblue::IngestIntegrationService.ingest_append_ui_allowed_base_directories
      rv = dirs.select do |dir|
        Dir.exists? dir
      end
      return rv
    end

    def ingest_append_script
      @ingest_append_script ||= ingest_append_script_init
    end

    def ingest_append_script_can_delete_script?( path_to_script )
      return false unless current_ability.admin?
      return true if IngestAppendScriptControllerBehavior.ingest_append_script_allow_delete_any_script
      return true if ingest_append_script_deletable?( path_to_script )
      return false
    end

    def ingest_append_script_can_run_a_new_script?
      rv = !ingest_append_script_is_running?
      return rv
    end

    def ingest_append_script_can_restart_script?( path_to_script )
      return false unless current_ability.admin?
      return false if ingest_append_script_is_running?
      return true if ingest_append_script_finished?( path_to_script )
      return true if ingest_append_script_failed?( path_to_script )
      return false
    end

    def ingest_append_script_deletable?( path )
      return false if ingest_append_script_modifier?( path,'active' )
      return true if ingest_append_script_modifier?( path,'finished' )
      return true if ingest_append_script_modifier?( path,'failed' )
      return false
    end

    def ingest_append_script_delete
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "params[:ingest_append_script_path]=#{params[:ingest_append_script_path]}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      presenter.controller = self
      path = params[:ingest_append_script_path]
      File.delete path if File.exist? path
      render '_ingest_append'
    end

    def ingest_append_script_delete_path( path: )
      main_app.ingest_append_script_delete_hyrax_data_set_path( id: params[:id],
                                                                ingest_prep_tab_active: 'ingest_append_script_view_display',
                                                                ingest_append_script_path: URI::DEFAULT_PARSER.escape(path) )
    end

    def ingest_append_script_failed?( path )
      ingest_append_script_modifier?( path,'failed' )
    end

    def ingest_append_script_files
      @ingest_append_script_files ||= ingest_append_script_files_init
    end

    def ingest_append_script_finished?( path )
      ingest_append_script_modifier?( path,'finished' )
    end

    def ingest_append_script_files_init
      paths = IngestScript.ingest_append_script_files( id: params[:id] )
      return paths
    end

    def ingest_append_script_generate
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      presenter.controller = self
      @ingest_script = generate_ingest_append_script
      render 'ingest_append_script_form'
    end

    def ingest_append_script_init
      path = ingest_append_script_path
      return "" if path.blank?
      script = File.open( path, 'r' ) { |io| io.read }
      return script
    end

    def ingest_append_script_is_running?
      @ingest_append_script_is_running ||= ingest_append_script_is_running_init
    end

    def ingest_append_script_is_running_init
      # return true
      ingest_append_script_files.each do |path_pair|
        path = File.join path_pair
        return true if ingest_append_script_modifier?( path,'monitor job running' )
        return true if ingest_append_script_modifier?( path,'job running' )
      end
      return false
    end

    def ingest_append_script_modifier?( path, modifier )
      return false if @ingest_append_script_show_modifiers.blank?
      modifiers = @ingest_append_script_show_modifiers[path]
      if modifiers.nil?
        modifiers = ingest_append_script_show_modifiers_init( path )
        @ingest_append_script_show_modifiers[path] = modifiers
      end
      rv = modifiers.include?( modifier )
      return rv
    end

    def ingest_append_script_path
      @ingest_append_script_path ||= ingest_append_script_path_init
    end

    def ingest_append_script_path_init
      path = ingest_append_script_path_resolve( params[:ingest_append_script_path] )
      return path if path.present?
      path_pairs = ingest_append_script_files
      return "" if path_pairs.blank?
      path = if path_pairs.size == 1
               File.join path_pairs[0]
             elsif path_pairs[0][0] == ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_base
               File.join path_pairs[0]
             else
               File.join path_pairs.last
             end
      return path
    end

    def ingest_append_script_path_resolve( path )
      return nil if path.blank?
      path = URI::DEFAULT_PARSER.unescape(path)
      # TODO: look in id-based directory.
      return nil unless File.exist? path
      return path
    end

    def ingest_append_script_prep
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      presenter.controller = self
      render '_ingest_append'
    end

    def ingest_append_script_prep_path( path: )
      main_app.ingest_append_script_prep_hyrax_data_set_path( id: params[:id],
                                                      ingest_prep_tab_active: 'ingest_append_script_view_display',
                                                      ingest_append_script_path: URI::DEFAULT_PARSER.escape(path) )
    end

    def ingest_append_script_restart
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "params[:ingest_append_script_path]=#{params[:ingest_append_script_path]}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      presenter.controller = self
      path = params[:ingest_append_script_path]
      commit = params[:commit]
      if true # TODO remove this if wrapper
        begin
          path_to_script = ingest_script_write_for_restart( original_path: ingest_append_script_path )
          rv = ingest_script_run( path_to_script: path_to_script, restart: true )
          if rv
            msg = "Ingest append script restart job started: '#{path_to_script}'"
          else
            msg = "Ingest append script restart job failed to start: '#{path_to_script}'"
          end
        rescue Exception => e # rubocop:disable Lint/RescueException
          Rails.logger.error "ingest_append_script_run_job #{e.class}: #{e.message} at #{e.backtrace[0]}"
          ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                 "ingest_append_script_restart #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                                 "" ] + e.backtrace # error
          msg = "Ingest append script job failed to start because: '#{e.class}: #{e.message} at #{e.backtrace[0]}'"
          redirect_to [main_app, curation_concern], notice: msg
        end
      end
      redirect_to [main_app, curation_concern], notice: msg
    end

    def ingest_append_script_restart_path( path: )
      main_app.ingest_append_script_restart_hyrax_data_set_path( id: params[:id],
                                                                 ingest_prep_tab_active: 'ingest_append_script_view_display',
                                                                 ingest_append_script_path: URI::DEFAULT_PARSER.escape(path) )
    end

    def ingest_append_script_restartable?( path )
      return false if ingest_append_script_modifier?( path,'active' )
      return true if ingest_append_script_modifier?( path,'finished' )
      return true if ingest_append_script_modifier?( path,'failed' )
      return false
    end

    def ingest_append_script_run_job
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "params[:commit]=#{params[:commit]}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      commit = params[:commit]
      if params[:ingest_script_textarea].present?
        begin
          path_to_script = ingest_script_write
          if I18n.t( 'simple_form.actions.data_set.ingest_append_script_run_job' ) == commit
            rv = ingest_script_run( path_to_script: path_to_script )
            if rv
              msg = "Ingest append script job started: '#{path_to_script}'"
            else
              msg = "Ingest append script job failed to start: '#{path_to_script}'"
            end
          else
            msg = "Ingest append script written to '#{path_to_script}'"
          end
          redirect_to [main_app, curation_concern], notice: msg
        rescue Exception => e # rubocop:disable Lint/RescueException
          Rails.logger.error "ingest_append_script_run_job #{e.class}: #{e.message} at #{e.backtrace[0]}"
          ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                "ingest_append_script_run_job #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                                 "" ] + e.backtrace # error
          msg = "Ingest append script job failed to start because: '#{e.class}: #{e.message} at #{e.backtrace[0]}'"
          redirect_to [main_app, curation_concern], notice: msg
        end
      else
        redirect_to [main_app, curation_concern], notice: "Script text area empty."
      end
    end

    @ingest_append_script_show_modifiers

    def ingest_append_script_show_modifiers( path )
      @ingest_append_script_show_modifiers ||= {}
      rv = @ingest_append_script_show_modifiers[path]
      if rv.nil?
        rv = ingest_append_script_show_modifiers_init( path );
        @ingest_append_script_show_modifiers[path] = rv
      end
      return '' if rv.empty?
      return " (#{rv.join(', ')})"
    end

    def ingest_append_script_show_modifiers_init( path )
      rv = []
      ingest_script = IngestScript.load( ingest_script_path: path,
                                         source: "#{self.class.name}.ingest_append_script_show_modifiers_init" )
      rv << 'active' if ingest_script.active?
      rv << 'job running' if ingest_script.job_running?
      rv << 'monitor job running' if ingest_script.monitor_job_running?
      rv << 'finished' if ingest_script.finished?
      rv << 'failed' if ingest_script.failed?
      return rv;
    end

    def ingest_append_script_view
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      presenter.controller = self
      render '_ingest_append'
    end

    def ingest_append_script_view_title
      "View Append Files Script for the work #{curation_concern.id} - #{curation_concern.title.first}"
    end

    def ingest_base_directory
      rv = params[:ingest_base_directory]
      return rv
    end

    def ingest_depositor
      curation_concern.depositor
    end

    def ingest_email_after
      default_value = true
      rv = if params[:ingest_email_after].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_after] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_email_before
      default_value = true
      rv = if params[:ingest_email_before].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_before] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_email_depositor
      default_value = false
      rv = if params[:ingest_email_depositor].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_depositor] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_email_ingester
      default_value = true
      rv = if params[:ingest_email_ingester].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_ingester] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_email_rest
      default_value = false
      rv = if params[:ingest_email_rest].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_rest] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_email_rest_emails
      return [] if params[:ingest_email_rest_emails].blank?
      params[:ingest_email_rest_emails].split( "\n" ).join( " " ).split( /\s+/ )
    end

    def ingest_file_path_list
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:ingest_file_path_list]='#{params[:ingest_file_path_list]}'",
                                             "@ingest_file_path_list='#{@ingest_file_path_list}'",
                                             "@ingest_file_path_list.blank?=#{@ingest_file_path_list.blank?}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      @ingest_file_path_list = params[:ingest_file_path_list]
      return @ingest_file_path_list unless @ingest_file_path_list.blank?
      # @ingest_file_path_list ||= ingest_file_path_list_from_base_directory
      @ingest_file_path_list = ingest_file_path_list_from_base_directory
    end

    def ingest_file_path_list_from_base_directory
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      ingest_script_messages # make sure it is initialized

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ingest_base_directory=#{ingest_base_directory}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      base_dir = ingest_base_directory&.strip
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      return "" if base_dir.blank?
      starts_with_path = base_dir
      starts_with_path = starts_with_path + File::SEPARATOR unless starts_with_path.ends_with? File::SEPARATOR
      @ingest_script_messages << "Read files from '#{starts_with_path}'"
      valid_path = ingest_file_path_valid( starts_with_path )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                             "starts_with_path=#{starts_with_path}",
                                             "valid_path=#{valid_path}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      return "" unless valid_path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                             "starts_with_path=#{starts_with_path}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      files = Dir.glob( "#{starts_with_path}*" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      path_list = []
      files.each do |f|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                               "f=#{f}",
                                               "" ] if ingest_append_scripts_controller_behavior_debug_verbose
        if File.basename( f ) =~ /^\..*$/
          next
        end
        path_list << f
      end
      rv = path_list.join( "\n" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_file_path_msg( path )
      return "ERROR: is a directory" if Dir.exist?( path )
      if File.file?( path )
        size = File.size( path )
        size = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( size, precision: 3 )
        return "SIZE: #{size}"
      else
        return "ERROR: file missing"
      end
    end

    def ingest_file_path_name( path )
      rv = File.basename path
      return rv
    end

    def ingest_file_path_names( path_list )
      path_list = path_list.split("\n") if path_list.is_a? Array
      path_names = []
      path_list.each do |path|
        path_names << File.basename( path )
      end
      path_names
    end

    def ingest_file_path_valid( path )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "path=#{path}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      return false if path.blank?
      return false if path.include? ".."
      # return true if Rails.env.development? # TODO - dev mode --> make a config parameter
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                 "ingest_allowed_base_directories=#{ingest_allowed_base_directories.pretty_inspect}",
                                 "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      ingest_allowed_base_directories.each do |base_dir|
        return true if path.to_s.start_with? base_dir
      end
      false
    end

    def ingest_ingester
      default_value = current_user.user_key
      rv = if params[:ingest_ingester].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_ingester]
           end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_prep_tab_active
      rv = params[:ingest_prep_tab_active]
      return rv unless rv.blank?
      rv = 'ingest_append_script_view_display' if active_ingest_append_script.present?
      return rv
    end

    def ingest_script_messages
      return @ingest_script_messages if @ingest_script_messages.present?
      @ingest_script_messages ||= params[:ingest_script_messages]
      if @ingest_script_messages.is_a? String
        @ingest_script_messages = @ingest_script_messages.split( "\n" )
      elsif @intest_script_messages.blank?
        @ingest_script_messages = []
      end
      @ingest_script_messages
    end

    def ingest_script_run( path_to_script:, restart: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "path_to_script=#{path_to_script}",
                                             "restart=#{restart}",
                                             "ingest_append_ui_allow_scripts_to_run=#{ingest_append_ui_allow_scripts_to_run}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      return false unless ingest_append_ui_allow_scripts_to_run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "IngestAppendScriptMonitorJob.perform_later:",
                                             "id: #{curation_concern.id}",
                                             "ingester: #{ingest_ingester}",
                                             "max_appends: #{ingest_append_script_max_appends}",
                                             "max_restarts_base: #{ingest_append_script_max_restarts_base}",
                                             "monitor_wait_duration: #{ingest_append_script_monitor_wait_duration}",
                                             "path_to_script: #{path_to_script}",
                                             "restart: #{restart}",
                                             "" ] if ingest_append_scripts_controller_behavior_debug_verbose
      IngestAppendScriptMonitorJob.perform_later( id: curation_concern.id,
                                                  ingester: ingest_ingester,
                                                  max_appends: ingest_append_script_max_appends,
                                                  max_restarts_base: ingest_append_script_max_restarts_base,
                                                  path_to_script: path_to_script,
                                                  monitor_wait_duration: ingest_append_script_monitor_wait_duration,
                                                  restart: restart )
      true
    end

    def ingest_script_title
      "Generate Append Files Script for the work #{curation_concern.id} - #{curation_concern.title.first}"
    end

    def ingest_script_write
      debug_verbose = ingest_append_scripts_controller_behavior_writer_debug_verbose ||
                                    ingest_append_scripts_controller_behavior_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "::Deepblue::IngestIntegrationService.ingest_script_dir=#{::Deepblue::IngestIntegrationService.ingest_script_dir}",
                                             "" ] if debug_verbose
      base_script_path = ::Deepblue::IngestIntegrationService.ingest_script_dir
      yyyymmddmmss = Time.now.strftime( "%Y%m%d_%H%M%S" )
      script_file_name = "#{yyyymmddmmss}_#{curation_concern.id}_append.yml"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_script_path=#{base_script_path}",
                                             "script_file_name=#{script_file_name}",
                                             "" ] if debug_verbose
      path_to_script = File.join( base_script_path, script_file_name )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "path_to_script=#{path_to_script}",
                                             "" ] if debug_verbose
      File.open( path_to_script, "w" ) do |out|
        out.puts params[:ingest_script_textarea]
      end
      path_to_script
    end

    def ingest_script_write_for_restart( original_path: )
      debug_verbose = ingest_append_scripts_controller_behavior_writer_debug_verbose ||
        ingest_append_scripts_controller_behavior_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "original_path=#{original_path}",
                                             "" ] if debug_verbose
      base_script_path = File.dirname original_path
      script_file_name = File.basename original_path
      yyyymmddmmss = Time.now.strftime( "%Y%m%d_%H%M%S" )
      if script_file_name =~ /^.+_([^_]+)_append\.yml/
        script_file_name = "#{yyyymmddmmss}_#{Regexp.last_match(1)}"
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_script_path=#{base_script_path}",
                                             "script_file_name=#{script_file_name}",
                                             "" ] if debug_verbose
      path_to_script = File.join( base_script_path, script_file_name )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "path_to_script=#{path_to_script}",
                                             "" ] if debug_verbose
      old_ingest_script = IngestScript.load( ingest_script_path: original_path,
                                             source: "#{self.class.name}.ingest_script_write_for_restart" )
      script_section = old_ingest_script.script_section
      prior_script_file_names = old_ingest_script.script_section[:prior_script_file_names]
      prior_script_file_names ||= []
      prior_script_file_names << original_path
      script_section[:prior_script_file_names] = prior_script_file_names
      old_max_restarts = script_section[:max_restarts]
      old_ingest_script.max_restarts = old_max_restarts + ingest_append_script_max_restarts_base
      script_section[:max_restarts] = old_max_restarts + ingest_append_script_max_restarts_base
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "script_section[:max_restarts]=#{script_section[:max_restarts]}",
                                             "" ] if debug_verbose
      old_ingest_script.save_to( path: path_to_script, source: this.class.name )
      path_to_script
    end

    def ingest_use_defaults
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "params[:ingest_use_defaults]=#{params[:ingest_use_defaults]}",
      #                                        "params[:ingest_use_defaults].blank?=#{params[:ingest_use_defaults].blank?}" ] if ingest_append_scripts_controller_behavior_debug_verbose
      return true if params[:ingest_use_defaults].blank?
      rv = params[:ingest_use_defaults] == 'true'
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "params[:ingest_use_defaults]=#{params[:ingest_use_defaults]}",
      #                                        "rv=#{rv} rv.class.name=#{rv.class.name}" ] if ingest_append_scripts_controller_behavior_debug_verbose
      rv
    end

    def ingest_visibility
      curation_concern.visibility.to_s
    end

  end

end
