# frozen_string_literal: true

module Deepblue

  # OAI-PMH document wrapper that keeps backward compatibility with the legacy
  # 'oai:deepbluedata:<id>' identifier format
  class OaiDocumentWrapper < BlacklightOaiProvider::SolrDocumentWrapper

    attr_reader :record_prefix_legacy

    def initialize( controller, options = {} )
      options = options.dup
      @record_prefix_legacy = options.delete( :record_prefix_legacy ).to_s
      super( controller, options )
    end

    def find( selector, options = {} )
      selector = strip_legacy_prefix( selector ) if single_record?( selector, options )
      super( selector, options )
    end

    private

      def single_record?( selector, options )
        selector != :all && !options[:resumption_token]
      end

      def strip_legacy_prefix( selector )
        return selector if record_prefix_legacy.empty?
        prefix = "#{record_prefix_legacy}:"
        id = selector.to_s
        id.start_with?( prefix ) ? id[prefix.length..-1] : selector
      end

  end

end
