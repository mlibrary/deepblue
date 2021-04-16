# frozen_string_literal: true

module GeneratorHelper

  def self.inject_block( generator, file_path, after:, &block )
    if after.present?
      generator.inject_into_file( file_path, after: after, &block )
      return true
    else
      # what is the fallback?
      return false
    end
  end

  def self.inject_line( generator, file_path, line, after: )
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
  singleton_class.send(:alias_method, :inject_lines, :inject_line)

  def self.already_includes?( file_path, string )
    return false unless File.exist? file_path
    IO.read(file_path).include? string
  end
  singleton_class.send(:alias_method, :includes?, :already_includes?)

  def self.already_matches?( file_path, regex )
    return false unless File.exist? file_path
    (IO.read(file_path) =~ regex).present?
  end
  singleton_class.send(:alias_method, :matches?, :already_matches?)

  def self.first_line_including( file_path, str )
    return nil unless File.exist? file_path
    # find the last line that matches the regular expression
    File.readlines( file_path ).each do |line|
      return line.chomp! if line.include? str
    end
    return nil
  end

  def self.first_line_matching( file_path, regex )
    # find the last line that matches the regular expression
    return nil unless File.exist? file_path
    File.readlines( file_path ).each do |line|
      line.chomp!
      return line if line =~ regex
    end
    return nil
  end

  def self.last_line_including( file_path, str )
    # find the last line that matches the regular expression
    return nil unless File.exist? file_path
    last_line = nil
    File.readlines( file_path ).each do |line|
      last_line = line.chomp! if line.include? str
    end
    last_line
  end

  def self.last_line_matching( file_path, regex )
    # find the last line that matches the regular expression
    return nil unless File.exist? file_path
    last_line = nil
    File.readlines( file_path ).each do |line|
      line.chomp!
      last_line = line if line =~ regex
    end
    last_line
  end

end
