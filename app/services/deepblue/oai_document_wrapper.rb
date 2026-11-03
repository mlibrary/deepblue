# frozen_string_literal: true

module Deepblue

  class OaiDocumentWrapper < BlacklightOaiProvider::SolrDocumentWrapper

    attr_reader :record_local_prefix, :record_prefix_legacy

    def initialize( controller, options = {} )
      options = options.dup
      @record_local_prefix  = options.delete( :record_local_prefix ).to_s
      @record_prefix_legacy = options.delete( :record_prefix_legacy ).to_s
      super( controller, options )
    end

    def find( selector, options = {} )
      if selector == :all || options[:resumption_token]
        decorate_result( super )
      else
        local_id = local_identifier_for( selector )
        raise OAI::IdException.new if local_id.nil?

        record = super( local_id, options )
        record.nil? ? record : decorate_record( record )
      end
    end

    private

    def local_identifier_for( selector )
      id = selector.to_s
      [ record_local_prefix, legacy_full_prefix ].each do |prefix|
        next if prefix.empty?
        next unless id.start_with?( prefix )

        local = id[prefix.length..-1]
        return local.empty? ? nil : local
      end
      nil
    end

    def legacy_full_prefix
      record_prefix_legacy.empty? ? '' : "#{record_prefix_legacy}:"
    end

    def decorate_result( result )
      case result
      when OAI::Provider::PartialResult
        OAI::Provider::PartialResult.new( decorate_records( result.records ), result.token )
      when Array
        decorate_records( result )
      when nil
        result
      else
        decorate_record( result )
      end
    end

    def decorate_records( records )
      records.map { |record| decorate_record( record ) }
    end

    def decorate_record( record )
      Deepblue::OaiRecord.new( record, record_local_prefix )
    end

  end

end
