# frozen_string_literal: true

module Hyrax

  class SingleUseLinkPresenter
    include ActionView::Helpers::TranslationHelper

    attr_reader :link

    delegate :download_key, :expired?, :user_comment, :to_param, to: :link

    # @param link [SingleUseLink]
    def initialize(link)
      @link = link
    end

    def human_readable_expiration
      return t( 'hyrax.single_use_links.expiration.human_readable_time',
                value: human_readable_time ) if ::Hyrax::SingleUseLinkService.single_use_link_use_detailed_human_readable_time
      if hours < 1
        t('hyrax.single_use_links.expiration.lesser_time')
      else
        t('hyrax.single_use_links.expiration.time', value: hours)
      end
    end

    def short_key
      link.download_key.first(6)
    end

    def link_type
      if download?
        t('hyrax.single_use_links.download.type')
      else
        t('hyrax.single_use_links.show.type')
      end
    end

    def url_helper
      if download?
        "download_single_use_link_url"
      else
        "show_single_use_link_url"
      end
    end

    private

      def download?
        link.path =~ /downloads|zip_download/
      end

      def hours
        (link.expires - Time.zone.now).to_i / 3600
      end

      def seconds
        (link.expires - Time.zone.now).to_i
      end

      def human_readable_time
        ActiveSupport::Duration.build(seconds).inspect
      end
    
  end

end
