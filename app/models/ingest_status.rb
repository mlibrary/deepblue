# frozen_string_literal: true

class IngestStatus < ApplicationRecord

  mattr_accessor :ingest_status_debug_verbose, default: Rails.configuration.ingest_status_debug_verbose

  ATTACHED = 'attached'.freeze unless const_defined? :ATTACHED
  FINISHED = 'finished'.freeze unless const_defined? :FINISHED
  STARTED = 'started'.freeze unless const_defined? :STARTED

  serialize :additional_parameters, JSON

  def self.ingest_attached?( cc_id: )
    IngestStatus.where( cc_id: cc_id, status: ATTACHED ).exists?
  end

  def self.ingest_finished?( cc_id: )
    IngestStatus.where( cc_id: cc_id, status: FINISHED ).exists?
  end

  def self.ingest_started?( cc_id: )
    IngestStatus.where( cc_id: cc_id, status: STARTED ).exists?
  end

  def self.ingesting?( cc_id: )
    ingest_started?( cc_id: cc_id ) && !ingest_finished?( cc_id: cc_id )
  end

end
