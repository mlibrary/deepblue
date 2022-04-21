# frozen_string_literal: true

module Deepblue

  # nabbed from heliotrope
  module SitemapGeneratorService

    def self.generate_sitemap

      src = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      src += "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
      DataSet.all.each do |work|
        next unless work.published?  
        next unless work.embargo_release_date.nil?
        unless work.embargo_release_date.nil?
          next if work.embargo_release_date <= Date.today
        end

        url = work.data_set_url
        url = work.data_set_url.gsub("http:", "https:") if work.data_set_url.include? "http:"
        src += "<url>\n"
        src += "<loc>" + url + "</loc>\n"
        src += "<lastmod>" + work.date_modified.to_datetime.to_s + "</lastmod>\n"
        src += "<changefreq>weekly</changefreq>\n"
        src += "<priority>0.5</priority>\n"
        src += "</url>\n"
      end
      src += "</urlset>\n"

      # I the file should be accessible here
      # http://localhost:3000/data/sitemap.xml
      # in which case it needs to go in the public dir
      sitemap_file = Rails.root.join('public', 'sitemap.xml').to_s
      File.open(sitemap_file, 'w') { |file| file.write(src) }

    end
    
  end
end
