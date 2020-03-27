# frozen_string_literal: true

module Deepblue

  module IngestAppendScriptControllerBehavior

    INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE = true

    attr_reader :ingest_script

    def generate_depth( depth: )
      return "" if depth < 1
      return "  " * (2 * depth)
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
      files = files.reject { |f| f =~ /^\s+$/ } # remove blank lines
      depth += 1
      @ingest_script_messages << "WARNING: No files found or specified." if files.blank?
      files.each do |f|
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
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@ingest_script_messages=#{@ingest_script_messages}",
      #                                        "ingest_script_messages=#{ingest_script_messages}",
      #                                        "script=#{script.join( "\n" )}",
      #                                        "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE

      return script.join( "\n" )
    end

    def ingest_allowed_base_directories
      ::Deepblue::IngestIntegrationService.ingest_append_ui_allowed_base_directories
    end

    def ingest_append_generate_script
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      presenter.controller = self
      @ingest_script = generate_ingest_append_script
      render 'ingest_append_script_form'
    end

    def ingest_append_prep
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      presenter.controller = self
      render 'ingest_append_prep_form'
    end

    def ingest_append_run_job
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params=#{params}",
                                             "params[:commit]=#{params[:commit]}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      commit = params[:commit]
      if params[:ingest_script_textarea].present?
        begin
          path_to_script = ingest_script_write
          if I18n.t( 'simple_form.actions.data_set.ingest_append_run_job' ) == commit
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
          Rails.logger.error "ingest_append_run_job #{e.class}: #{e.message} at #{e.backtrace[0]}"
          ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                "ingest_append_run_job #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                                 "" ] + e.backtrace
          msg = "Ingest append script job failed to start because: '#{e.class}: #{e.message} at #{e.backtrace[0]}'"
          redirect_to [main_app, curation_concern], notice: msg
        end
      else
        redirect_to [main_app, curation_concern], notice: "Script text area empty."
      end
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
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
    end

    def ingest_email_before
      default_value = true
      rv = if params[:ingest_email_before].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_before] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
    end

    def ingest_email_depositor
      default_value = false
      rv = if params[:ingest_email_depositor].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_depositor] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
    end

    def ingest_email_ingester
      default_value = true
      rv = if params[:ingest_email_ingester].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_ingester] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
    end

    def ingest_email_rest
      default_value = false
      rv = if params[:ingest_email_rest].blank? && ingest_use_defaults
             default_value
           else
             params[:ingest_email_rest] == 'true'
           end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv} rv class = #{rv.class.name}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
    end

    def ingest_email_rest_emails
      return [] if params[:ingest_email_rest_emails].blank?
      params[:ingest_email_rest_emails].split( "\n" ).join( " " ).split( /\s+/ )
    end

    def ingest_file_path_list
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:ingest_file_path_list]=#{params[:ingest_file_path_list]}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      @ingest_file_bath_list = params[:ingest_file_path_list] if params[:ingest_file_path_list].present?
      @ingest_file_bath_list ||= ingest_file_path_list_from_base_directory
    end

    def ingest_file_path_list_from_base_directory
      ingest_script_messages # make sure it is initialized

      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "ingest_base_directory=#{ingest_base_directory}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      base_dir = ingest_base_directory&.strip
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      return "" if base_dir.blank?
      starts_with_path = base_dir
      starts_with_path = starts_with_path + File::SEPARATOR unless starts_with_path.ends_with? File::SEPARATOR
      @ingest_script_messages << "Read files from '#{starts_with_path}'"
      return "" unless ingest_file_path_valid( starts_with_path )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "starts_with_path=#{starts_with_path}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      files = Dir.glob( "#{starts_with_path}*" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      path_list = []
      files.each do |f|
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "f=#{f}",
                                               "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
        if File.basename( f ) =~ /^\..*$/
          next
        end
        path_list << f
      end
      rv = path_list.join( "\n" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
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
      # TODO - dev mode
      # TODO - add local data directory
      return false if path.blank?
      return false if path.include? ".."
      ::Deepblue::IngestIntegrationService.ingest_append_ui_allowed_base_directories.each do |base_dir|
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
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
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

    def ingest_script_run( path_to_script: )
      return true unless ::Deepblue::IngestIntegrationService.ingest_append_ui_allow_scripts_to_run
      IngestAppendScriptJob.perform_later( path_to_script: path_to_script, ingester: ingest_ingester )
      true
    end

    def ingest_script_title
      "Append Files Script for the work #{curation_concern.id} - #{curation_concern.title.first}"
    end

    def ingest_script_write
      base_script_path = ::Deepblue::IngestIntegrationService.ingest_script_dir
      yyyymmddmmss = Time.now.strftime( "%Y%m%d_%H%M%S" )
      script_file_name = "#{yyyymmddmmss}_#{curation_concern.id}_append.yml"
      path_to_script = File.join( base_script_path, script_file_name )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "path_to_script=#{path_to_script}",
                                             "" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      File.open( path_to_script, "w" ) do |out|
        out.puts params[:ingest_script_textarea]
      end
      path_to_script
    end

    def ingest_use_defaults
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        "params[:ingest_use_defaults]=#{params[:ingest_use_defaults]}",
      #                                        "params[:ingest_use_defaults].blank?=#{params[:ingest_use_defaults].blank?}" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      return true if params[:ingest_use_defaults].blank?
      rv = params[:ingest_use_defaults] == 'true'
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        "params[:ingest_use_defaults]=#{params[:ingest_use_defaults]}",
      #                                        "rv=#{rv} rv.class.name=#{rv.class.name}" ] if INGEST_APPEND_SCRIPTS_CONTROLLER_BEHAVIOR_VERBOSE
      rv
    end

    def ingest_visibility
      curation_concern.visibility.to_s
    end

  end

end
