# frozen_string_literal: false

module Hyrax
  module CitationsBehaviors
    module Formatters
      class MlaFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior

        def format(work)
          text = ''

          authors = author_list(work).reject(&:blank?)
          formatted_authors = format_authors(authors)
          # formatted_authors = '&nbsp;' unless formatted_authors.present?
          # text << "<span class='citation-author'>#{formatted_authors}</span> " if formatted_authors.present?

          title_info = setup_title_info(work)
          formatted_title = format_title(title_info)

          year = format_year(work)
          if year.blank?
            text << I18n.t( 'hyrax.citation.work.format.mla_html',
                            author: formatted_authors,
                            title: formatted_title,
                            work_type: 'Data set' )
          else
            text << I18n.t( 'hyrax.citation.work.format.mla_with_year_html',
                            author: formatted_authors,
                            title: formatted_title,
                            work_type: 'Data set',
                            year: year )
          end

          text << format_doi( work.doi ) if work.respond_to?(:doi)

          text.gsub!(URI.regexp, '<a href="\0">\0</a>')
          text.html_safe
        end

        def format_year(work)
          return '' unless ( work.respond_to?( :date_published2 ) || work.respond_to?( :date_published ) )
          timestamp = nil
          if work.respond_to?( :date_published2 ) && work.date_published2.present?
            timestamp = work.date_published2
          end
          if timestamp.blank? && work.respond_to?( :date_published ) && work.date_published.present?
            timestamp = work.date_published
          end
          return '' unless timestamp.present?
          timestamp = to_timestamp( timestamp )
          timestamp = Array(timestamp).first if timestamp.respond_to? :first
          year = ''
          year = timestamp.to_date.year if timestamp.present?
          return year
        end


        def to_timestamp( arg, timestamp_format: nil )
          return nil if arg.blank?
          timestamp = Array( arg ).first
          return timestamp if timestamp.is_a? DateTime
          return timestamp.to_datetime if timestamp.is_a? Date
          if timestamp_format.blank? && arg.is_a?( String )
            return DateTime.strptime( arg, "%Y-%m-%d %H:%M:%S" ) if arg.match?( /\d\d\d\d\-\d\d?\-\d\d? \d\d?:\d\d:\d\d/ )
            return DateTime.strptime( arg, "%m/%d/%Y" ) if arg.match?( /\d\d?\/\d\d?\/\d\d\d\d/ )
            return DateTime.strptime( arg, "%m-%d-%Y" ) if arg.match?( /\d\d?\-\d\d?\-\d\d\d\d/ )
            return DateTime.strptime( arg, "%Y" ) if arg.match?( /\d\d\d\d/ )
            timestamp = DateTime.parse( arg ) if arg.present? && arg.is_a?( String )
          elsif arg.is_a? String
            timestamp = DateTime.strptime( arg, timestamp_format )
          end
          return timestamp
        rescue ArgumentError
          puts "DateTime.parse failed - arg='#{arg}' timestamp_format='#{timestamp_format}'" # - #{e.class}: #{e.message} at #{e.backtrace[0]}"
        end


        def format_authors(authors_list = [])
          return '' if authors_list.blank?
          text = ''
          authors_list.each do |name|
            name.gsub!(/\,\s+/, ',')
            i = name.index(',') 
            unless ( i.nil? )
              last = name[0..i-1]
              fnames_full = ""
              fnames = name[i+1, name.size].rstrip.lstrip.split
              fnames.each { | fname |
                fnames_full += fname[0].upcase + ". "
              }
              first = fnames_full.reverse.sub('. '.reverse, '').reverse
              text << last + ", " + first + "., "
            else
              text << name.strip + ", "
            end
          end
          text.sub! /, $/, ' '
          text.strip!
          return '' if text.blank?
          text << '.' unless text.ends_with? '.'
          text
        end

        def format_doi( doi=[] )
          return '' if doi.blank?
          Array(doi).first.sub( 'doi:', 'https://doi.org/' )
        end

        # def concatenate_authors_from(authors_list)
        #   text = ''
        #   text << surname_first(authors_list.first)
        #   if authors_list.length > 1
        #     if authors_list.length < 4
        #       authors_list[1...-1].each do |author|
        #         text << ", " << given_name_first(author)
        #       end
        #       text << ", #{given_name_first(authors_list.last)}"
        #     else
        #       text << ", et al"
        #     end
        #   end
        #   text
        # end
        # private :concatenate_authors_from

        def format_date(pub_date)
          return '' if pub_date.blank?
          pub_date
        end

        def format_title(title_info)
          return '' if title_info.blank?
          # So that the title appears just as it was entered.
          # title = mla_citation_title(title_info)
          title_info = title_info.join(' ') if title_info.is_a? Array
          title_info.strip!
          return '' if title_info.blank?
          title = title_info
          title.gsub! /:/, '&#58;'
          title.sub! /\.$/, ''
          title.strip!
          # title = whitewash(title)
          return '' if title.blank?
          "<span class='citation-title'>#{title}</span> "
        end

        # def whitewash(text)
        #   Loofah.fragment(text.to_s).scrub!(:whitewash).to_s
        # end

      end
    end
  end
end
