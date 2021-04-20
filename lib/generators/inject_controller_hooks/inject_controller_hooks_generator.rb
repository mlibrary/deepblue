# frozen_string_literal: true

require_relative '../../../app/services/generator_helper'

class InjectControllerHooksGenerator < Rails::Generators::Base

  AFTER_ACTION_LABEL = 'irus analytics after action'
  COPY_TARGET_FILE_AND_INJECT_INTO_COPY = true
  INCLUDE_IRUS_ANALYTICS_CODE = 'include IrusAnalytics::Controller::AnalyticsBehaviour'
  INCLUDE_IRUS_ANALYTICS_LABEL = 'include IrusAnalytics controller behavior'
  ITEM_IDENTIFIER_METHOD_NAME = 'item_identifier'
  SKIP_SEND_IRUS_ANALYTICS_METHOD_NAME = 'skip_send_irus_analytics?'

  argument :after_action, type: :string, required: true, desc: ""
  argument :controller_class_name, type: :string, default: nil, desc: "The class name of the controller including any module prefixs."
  # argument :controller_file_name, type: :string, default: nil, desc: "The file name of the controller. 'app/controllers' will be prepended."
  # argument :debug_verbose, type: :string, default: 'true', desc: "Whether or not to print lots of annoying messages."
  argument :options_json, type: :string, default: '{}', desc: "JSON encoded hash map of additional options."

  desc <<-EOS
      This generator makes the following changes to your application:
       1. Injects IRUS analytic hooks into a specified controller
  EOS

  # puts "File.expand_path('../../../..', __FILE__)=#{File.expand_path('../../../..', __FILE__)}"
  source_root File.expand_path('../../../..', __FILE__)

  def inject_controller_code_using_class_name
    say_status "info", "inject_controller_code_using_class_name", :blue
    say_status "info", "options=#{options}", :blue
    say_status "info", "options[:after_action]=#{options[:after_action]}", :blue
    say_status "info", "after_action=#{after_action}", :blue
    say_status "info", "controller_class_name=#{controller_class_name}", :blue
    say_status "info", "options_json=#{options_json}", :blue
    say_status "info", "options_json['after_action']=#{options_json['after_action']}"
    say_status "info", "options_json['controller_class_name']=#{options_json['controller_class_name']}"
    return if after_action.blank?
    return if controller_class_name.blank?
    file_path = ::File.join( "app/controllers","#{controller_class_name.underscore}.rb" )
    do_inject_controller_code(file_path, controller_class_name, after_action: after_action)
  end

  private

  def cli_options
    @cli_options ||= cli_options_init
  end

  def cli_options_init
    begin
      JSON.parse options_json
    rescue JSON::JSONError => e
      # TODO: handle the error better
      {}
    end
  end

  def helper
    @helper ||= GeneratorHelper.new( generator: self, debug_verbose: debug_verbose?, cli_options: cli_options )
  end

  def debug_verbose?
    @debug_verbose_t = true
  end

  def do_inject_controller_code(file_path, class_name, after_action:)
    say_status "info", "do_inject_controller_code(#{file_path},#{class_name},#{after_action})", :blue
    say_status "info", "File.exist? #{file_path}='#{File.exist? file_path}'", :blue
    if File.exist? file_path
      fp = file_path
      if COPY_TARGET_FILE_AND_INJECT_INTO_COPY
        file_path_copy = ::File.join( ::File.dirname(fp), ::File.basename(fp, ".*") + "_copy" + ::File.extname(fp)  )
        say_status "info", "file_path_copy='#{file_path_copy}'", :blue if debug_verbose?
        copy_file( file_path, file_path_copy )
        say_status "info", "File.exist? #{file_path_copy}='#{File.exist? file_path_copy}'", :blue
        target_path = file_path_copy
      else
        target_path = file_path
      end
      inject_irus_include_analytics_controller_behavior( target_path, class_name )
      inject_after_action( target_path, after_action )
      inject_public_declaration( target_path, after_action )
      inject_item_identifier_method( target_path )
      inject_skip_send_irus_analytics_method( target_path )
    end

  end

  def after_action_code( after_action )
    "after_action :send_irus_analytics_request, only: [:#{after_action}]"
  end

  def inject_after_action( target_path, after_action )
    code = after_action_code( after_action )
    label = AFTER_ACTION_LABEL
    return if helper.initial_check_including( target_path, code, label )
    begin # while for breaks
      break if helper.inject_code_after_last_line_matching( target_path, code, /^\s*after_action .+$/, label )
      break if helper.inject_code_after_comment( target_path, code, INCLUDE_IRUS_ANALYTICS_LABEL, label )
      break if helper.inject_code_after_first_line_including( target_path, code, INCLUDE_IRUS_ANALYTICS_CODE, label )
    end while false # for breaks
    helper.say_status_error_first_line_including( target_path, code, label )
  end

  def inject_irus_include_analytics_controller_behavior( target_path, class_name )
    code = INCLUDE_IRUS_ANALYTICS_CODE
    label = INCLUDE_IRUS_ANALYTICS_LABEL
    say_status "info", "Looking for code='#{code}'", :blue
    line = helper.first_line_including( target_path, code )
    # say_status "info", "Found helper.first_line_including line='#{line}'", :blue
    if line.present?
      say_status "info", "Found: #{code}", :green
    else
      begin # while for breaks
        break if helper.inject_code_after_last_line_matching( target_path, code, /^\s*include .+$/, label )
        break if helper.inject_code_after_first_line_including( target_path, code, "class #{class_name} ", label )
        break if helper.inject_code_after_first_line_including( target_path, code, "class #{class_name.demodulize} ", label )
      end while false # for breaks
      helper.say_status_error_first_line_including( target_path, code, label )
    end
  end

  def item_identifier_method_code
    <<-EOS
    def #{ITEM_IDENTIFIER_METHOD_NAME}
      # return the OAI identifier
      curation_concern.oai_identifier
    end
  EOS
  end

  def inject_item_identifier_method( target_path )
    code = "def #{ITEM_IDENTIFIER_METHOD_NAME}"
    label = ITEM_IDENTIFIER_METHOD_NAME
    return if helper.initial_check_including( target_path, code, label )
    begin # while for breaks
      full_code = item_identifier_method_code
      break if helper.inject_code_after_first_line_matching( target_path, full_code, public_declaration_re, label )
    end while false # for breaks
    helper.say_status_warning_first_line_including( target_path, code, label )
  end

  def inject_public_declaration( target_path, after_action )
    code = 'public'
    label = "'public' declaration"
    return if helper.initial_check_matching( target_path, public_declaration_re, label )
    begin # while for breaks
      break if helper.inject_code_after_comment( target_path, code, AFTER_ACTION_LABEL )
      break if helper.inject_code_after_first_line_including( target_path, code, after_action_code( after_action ) )
    end while false # for breaks
    helper.say_status_error_first_line_matching( target_path, public_declaration_re, label )
  end

  def skip_send_irus_analytics_method
    <<-EOS
    def #{SKIP_SEND_IRUS_ANALYTICS_METHOD_NAME}
      # return true to skip tracking, for example to skip curation_concerns.visibility == 'private'
      false
    end
    EOS
  end

  def inject_skip_send_irus_analytics_method( target_path )
    code = "def #{SKIP_SEND_IRUS_ANALYTICS_METHOD_NAME}"
    label = SKIP_SEND_IRUS_ANALYTICS_METHOD_NAME
    return if helper.initial_check_including( target_path, code, label )
    begin # while for breaks
      full_code = skip_send_irus_analytics_method
      break if helper.inject_code_after_comment( target_path, full_code, ITEM_IDENTIFIER_METHOD_NAME, label )
      break if helper.inject_code_after_first_line_matching( target_path, full_code, public_declaration_re, label )
    end while false # for breaks
    helper.say_status_warning_first_line_including( target_path, code, label )
  end

  def public_declaration_re
    @public_declaration_re ||= /^\s*public(\s*\#.*|\s+)?/
  end

  def public_declaration_re_m
    @public_declaration_re_m ||= /\n[ \t]*public([ \t]*\#[^\n]*|[ \t]+)?\n/m
  end

end
