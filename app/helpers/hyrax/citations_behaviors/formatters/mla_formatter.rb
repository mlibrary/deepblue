module Hyrax
  module CitationsBehaviors
    module Formatters
      class MlaFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior

        def format(work)
          text = ''

          # setup formatted author list
          authors = author_list(work).reject(&:blank?)
          text << "<span class=\"citation-author\">#{format_authors(authors)}</span>"

          text << "(" + work.date_published2.first[0,4] + "). " if work.date_published2.present?

          # setup title
          title_info = setup_title_info(work)
          text << format_title(title_info)

          text << " [Data set]. University of Michigan - Deep Blue. "

          # Publication - for now, not interested in putting this in
          # pub_info = clean_end_punctuation(setup_pub_info(work, true))
          # text << pub_info + "." if pub_info.present?
          doi = ""
          doi = ( Array(work.doi).first.sub 'doi:', 'https://doi.org/' ) if work.doi.present?
	        text << doi
          text.gsub!(URI.regexp, '<a href="\0">\0</a>')
          text.html_safe
        end

        def format_authors(authors_list = [])
          text = ""
          authors_list.each do |name|
            name.gsub!(/\,\s+/, ',')
            i = name.index(',') 
            unless ( i.nil? )
              last = name[0..i-1]
              first = name[i+ 1]
              text << last + ", " + first + "., "
            else
              text << name + ", "
            end
          end
          text.sub! /, $/, ' '
          text
        end

        def concatenate_authors_from(authors_list)
          text = ''
          text << surname_first(authors_list.first)
          if authors_list.length > 1
            if authors_list.length < 4
              authors_list[1...-1].each do |author|
                text << ", " << given_name_first(author)
              end
              text << ", #{given_name_first(authors_list.last)}"
            else
              text << ", et al"
            end
          end
          text
        end
        private :concatenate_authors_from

        def format_date(pub_date)
          pub_date
        end

        def format_title(title_info)
          # So that the title appears just as it was entered.
          # title = mla_citation_title(title_info)
          title = title_info
          title.sub! /:/, '&#58;'
          title.sub! /.$/, ''
          title_info.blank? ? "" : "<i class=\"citation-title\">#{title}</i> "
        end
      end
    end
  end
end
