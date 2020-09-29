# frozen_string_literal: true

module Deepblue

  # nabbed from heliotrope
  module MarkdownService

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    @@markdown_service_debug_verbose = false
    @@extensions = {}
    @@render_options = {}

    mattr_accessor  :markdown_service_debug_verbose,
                    :extensions,
                    :render_options

    mattr_accessor :md

    def self.md
      @@md ||= md_init
    end

    def self.md_init
      # renderer = CustomMarkdownRenderer.new(render_options)
      renderer = Redcarpet::Render::HTML.new(render_options)
      ::Redcarpet::Markdown.new(renderer, extensions)
    end

    def self.markdown(value)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "value=#{value}",
                                             "" ] if markdown_service_debug_verbose
      rendered_html = md.render(value)
      outer_p_tags_removed = Regexp.new(/\A<p>(.*)<\/p>\Z/m).match(rendered_html)
      rendered_html = outer_p_tags_removed.nil? ? rendered_html : outer_p_tags_removed[1]
      # redcarpet's hard_wrap causes unwanted line breaks, the first gsub seems to be the most targeted way to remove them
      # with the second gsub allowing us to unescape non-breaking spaces to format certain fields per authors' requests
      rv = rendered_html.gsub(/<\/th><br>/, '</th>').gsub(/&amp;nbsp;/, '&nbsp;').html_safe
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if markdown_service_debug_verbose
      return rv
    end

    # mattr_accessor :sd
    # self.sd = Redcarpet::Markdown.new(Redcarpet::Render::StripDown.new,
    #                                   strikethrough: true,
    #                                   escape_html: false,
    #                                   space_after_headers: true)
    #
    # def self.markdown_as_text(value, strip_tags = false)
    #   markdown_removed = sd.render(value).gsub(/\n$/, '').tr("\n", ' ')
    #   # now remove any HTML tags as well, if desired
    #   strip_tags ? Loofah.fragment(markdown_removed).text(encode_special_chars: false) : markdown_removed
    # end

  end

  # nabbed from heliotrope
  # class CustomMarkdownRenderer < Redcarpet::Render::HTML
  #   def link(link, _title, link_text)
  #     if external_link?(link)
  #       "<a target=\"_blank\" href=\"#{link}\">#{link_text}</a>"
  #     else
  #       "<a href=\"#{link}\">#{link_text}</a>"
  #     end
  #   end
  #
  #   def autolink(link, _link_type)
  #     if external_link?(link)
  #       "<a target=\"_blank\" href=\"#{link}\">#{link}</a>"
  #     else
  #       "<a href=\"#{link}\">#{link}</a>"
  #     end
  #   end
  #
  #   private
  #
  #   def external_link?(link)
  #     if link.start_with?('/') ||
  #         link.include?('fulcrum.org') ||
  #         link.include?('fulcrumscholar.org') ||
  #         link.include?('fulcrum.www.lib.umich.edu') ||
  #         link.include?('localhost')
  #       false
  #     else
  #       true
  #     end
  #   end
  # end

end
