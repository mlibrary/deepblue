namespace :deepblue do

  # bundle exec rake deepblue:create_sitemap
  desc 'Create sitemap'
  task create_sitemap: :environment do
    Deepblue::SitemapGeneratorService.generate_sitemap
  end
  
end