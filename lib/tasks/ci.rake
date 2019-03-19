# frozen_string_literal: true

# Ham handed hack to keep this out of production requires
unless Rails.env.production?
  # Taken from sufia-dev.rake
  require 'rspec/core'
  require 'rspec/core/rake_task'
  require 'solr_wrapper'
  require 'fcrepo_wrapper'

  desc 'Spin up hydra-jetty and run specs'
  task :ci do
    puts 'running continuous integration'
    # No need to maintain minter state on Travis
    reset_statefile! if ENV['TRAVIS'] == 'true'

    solr_config   = Rails.root.join('config/solr_wrapper_test.yml')
    fcrepo_config = Rails.root.join('config/fcrepo_wrapper_test.yml')

    solr_instance = SolrWrapper.instance(config: solr_config, verbose: true, managed: true)
    solr_instance.wrap do |solr|
      solr.with_collection do
        fcrepo_instance = FcrepoWrapper::Instance.new(config: fcrepo_config, verbose: true, managed: true)
        fcrepo_instance.wrap do |fcrepo|
          Rake::Task['spec'].invoke
        end
      end
    end
  end

  def reset_statefile!
    FileUtils.rm_f('/tmp/minter-state')
  end
end
