# frozen_string_literal: true

require_relative '../../app/tasks/deepblue/abstract_task'
require_relative '../../app/services/deepblue/doi_minting_service'

module Deepblue

  class DoiPendingListTask < AbstractTask

    attr_accessor :id

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      puts
      ruby_list = options['ruby_list']
      doi_pending=[]
      DataSet.all.each do |w|
        next if w.doi.blank?
        next unless w.doi =~ /pending/
        doi_pending << w.id
        puts "#{id} - #{w.doi}"
      end
      puts "doi_pending.size=#{doi_pending.size}"
      puts "%w[#{ids.join(' ')}]" if ruby_list
    end

  end

end
