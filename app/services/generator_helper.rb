# frozen_string_literal: true

class GeneratorHelper

  attr_accessor :generator, :debug_verbose, :cli_options

  def initialize( generator:, debug_verbose:, cli_options: )
    @generator = generator
    @debug_verbose = debug_verbose
    @cli_options = cli_options
  end

  def comment_line( prefix, postfix )
    "#{comment_text( prefix, postfix )}\n"
  end

  def comment_text( prefix, postfix )
    "# #{prefix} inject #{self.class.name}: #{postfix}"
  end

  def initial_check_including( target_path, str, label )
    generator.say_status "info", "Looking for #{label}", :blue
    line = first_line_including( target_path, str )
    generator.say_status "info", "Found GeneratorHelper.first_line_matching line='#{line}'", :blue
    return false if line.blank?
    generator.say_status "info", "Found 'public' decleration", :green
    return true
  end

  def initial_check_matching( target_path, target_re, label )
    generator.say_status "info", "Looking for #{label}", :blue
    line = first_line_matching( target_path, target_re )
    generator.say_status "info", "Found GeneratorHelper.first_line_matching line='#{line}'", :blue
    return false if line.blank?
    generator.say_status "info", "Found 'public' decleration", :green
    return true
  end

  def inject_block( file_path, after:, &block )
    if after.present?
      generator.inject_into_file( file_path, after: after, &block )
      return true
    else
      # what is the fallback?
      return false
    end
  end

  def inject_code_after_comment( target_path, code, comment, label = nil )
    line = first_line_including( target_path, comment_text( 'end', comment ) )
    return false unless line.present?
    if label.blank?
      inject_line( target_path, code, after: line )
    else
      inject_include_code( target_path, code: code, label: label, after: line )
    end
    true
  end

  def inject_code_after_first_line_including( target_path, code, str, label = nil )
    line = first_line_including( target_path, str )
    return false unless line.present?
    if label.blank?
      inject_line( target_path, code, after: line )
    else
      inject_include_code( target_path, code: code, label: label, after: line )
    end
    true
  end

  def inject_code_after_first_line_matching( target_path, code, target_re, label = nil )
    line = first_line_matching( target_path, target_re )
    return false unless line.present?
    if label.blank?
      inject_line( target_path, code, after: line )
    else
      inject_include_code( target_path, code: code, label: label, after: line )
    end
    true
  end

  def inject_code_after_last_line_including( target_path, code, str, label = nil )
    line = last_line_including( target_path, str )
    return false unless line.present?
    if label.blank?
      inject_line( target_path, code, after: line )
    else
      inject_include_code( target_path, code: code, label: label, after: line )
    end
    true
  end

  def inject_code_after_last_line_matching( target_path, code, target_re, label = nil )
    line = last_line_matching( target_path, target_re )
    return false unless line.present?
    if label.blank?
      inject_line( target_path, code, after: line )
    else
      inject_include_code( target_path, code: code, label: label, after: line )
    end
    true
  end

  def inject_include_code( file_path, after:, code:, label: )
    code = code.strip
    inject_block( file_path, after: after ) do
      <<-EOS

    #{comment_text( 'begin', label)}
    #{code}
    #{comment_text( 'end', label)}
      EOS
    end
  end

  def inject_line( file_path, line, after: )
    return true if already_includes? file_path, line
    if after.present?
      generator.inject_into_file file_path, after: after do
        "\n  #{line}\n"
      end
      return true
    else
      # what is the fallback?
      return false
    end
  end
  alias :inject_lines :inject_line

  def already_includes?( file_path, string )
    return false unless File.exist? file_path
    IO.read(file_path).include? string
  end
  alias :includes? :already_includes?

  def already_matches?( file_path, regex )
    return false unless File.exist? file_path
    (IO.read(file_path) =~ regex).present?
  end
  alias :matches? :already_matches?

  def first_line_including( file_path, str )
    return nil unless File.exist? file_path
    # find the last line that matches the regular expression
    File.readlines( file_path ).each do |line|
      return line.chomp! if line.include? str
    end
    return nil
  end

  def first_line_matching( file_path, regex )
    # find the last line that matches the regular expression
    return nil unless File.exist? file_path
    File.readlines( file_path ).each do |line|
      line.chomp!
      return line if line =~ regex
    end
    return nil
  end

  def last_line_including( file_path, str )
    # find the last line that matches the regular expression
    return nil unless File.exist? file_path
    last_line = nil
    File.readlines( file_path ).each do |line|
      last_line = line.chomp! if line.include? str
    end
    last_line
  end

  def last_line_matching( file_path, regex )
    # find the last line that matches the regular expression
    return nil unless File.exist? file_path
    last_line = nil
    File.readlines( file_path ).each do |line|
      line.chomp!
      last_line = line if line =~ regex
    end
    last_line
  end

  def say_status_error_first_line_including( target_path, str, description )
    if first_line_including( target_path, str ).present?
      generator.say_status "info", "Injected: #{description}", :green
    else
      generator.say_status "error", "Giving up attempting to inject: #{description}", :red
    end
  end

  def say_status_error_first_line_matching( target_path, target_re, description )
    if first_line_matching( target_path, target_re ).present?
      generator.say_status "info", "Injected: #{description}", :green
    else
      generator.say_status "error", "Giving up attempting to inject: #{description}", :red
    end
  end

  def say_status_warning_first_line_including( target_path, str, label )
    if first_line_including( target_path, str ).present?
      generator.say_status "info", "Injected: #{label}", :green
    else
      generator.say_status "warning", "Giving up attempting to inject: #{label}", :yellow
    end
  end

  def say_status_warning_first_line_matching( target_path, target_re, label )
    if first_line_matching( target_path, target_re ).present?
      generator.say_status "info", "Injected: #{label}", :green
    else
      generator.say_status "warning", "Giving up attempting to inject: #{label}", :yellow
    end
  end

end
