# frozen_string_literal: true

# Ham handed hack to keep this out of production requires
unless Rails.env.production?
  # Taken from sufia-dev.rake
  require 'rspec/core'
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'

  desc 'Run rubocop'
  task :rubocop do
    RuboCop::RakeTask.new
  end

end
