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

    solr_params = { port: '8985', verbose: true, managed: true }
    fcrepo_params = { port: '8986', verbose: true, managed: true }

    SolrWrapper.wrap(solr_params) do |solr|
      ENV['SOLR_TEST_PORT'] = solr.port
      solr.with_collection(name: 'hydra-test', dir: File.join(File.expand_path('../..', File.dirname(__FILE__)), 'solr', 'config')) do
        FcrepoWrapper.wrap(fcrepo_params) do |fcrepo|
          ENV['FCREPO_TEST_PORT'] = fcrepo.port
          Rake::Task['spec'].invoke
        end
      end
    end
  end

  def reset_statefile!
   FileUtils.rm_f('/tmp/minter-state')
  end
end
