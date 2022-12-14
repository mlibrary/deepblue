# frozen_string_literal: true

module Deepblue

  module JobsHelper

    def self.job_queue_available?
      !Rails.env == 'development'
    end

    def self.jobs_running
      if job_queue_available?
        return MsgHelper.t( 'hyrax.jobs.do_not_run_in_dev' )
      else
        jobs = Resque::Worker.all.map(&:job).select { |j| !j.empty? }
        return MsgHelper.t( 'hyrax.jobs.running', job_count: jobs.size, now: MsgHelper.display_now  )
      end
    end

    def self.jobs_running_by( key:, value: )
      return [] unless job_queue_available?
      rv = Resque::Worker.all.map(&:job).select { |j| j[key].present? && value == j[key] }
      return rv
    end

    def self.jobs_running_if( key: )
      return [] unless job_queue_available?
      rv = Resque::Worker.all.map(&:job).select { |j| j[key].present? }
      return rv
    end

    def self.jobs_running_by_class( klass: )
      return [] unless job_queue_available?
      jobs_running_by( key: 'job_class', value: klass.name )
    end

    def self.jobs_running_by_id( job_id: )
      return [] unless job_queue_available?
      Resque::Worker.all.each { |j| job = j.job; return job if job['job_id'] == job_id }
      return nil
    end

    def self.job_by_job_id( job_id: )
      return nil unless job_queue_available?
      # TODO
      return nil
    end

    def self.job_running?( job_id )
      return false unless job_queue_available?
      # TODO
      return false
    end

    def self.jobs_running_by_queue( queue: )
      return [] unless job_queue_available?
      jobs_running_by( key: 'queue_name', value: queue )
    end

    def self.jobs_select_job_class( job_rv: true )
      return [] unless job_queue_available?
      rv = jobs_running_if( key: 'job_class' )
      return rv if job_rv
      rv.map { |j| j['job_class'] }
    end

    def self.jobs_select_queue( job_rv: true )
      return [] unless job_queue_available?
      rv = jobs_running_if( key: 'queue' )
      return rv if job_rv
      rv.map { |j| j['queue'] }
    end

    def self.jobs_select_payload( job_rv: true )
      return [] unless job_queue_available?
      rv = jobs_running_if( key: 'payload' )
      return rv if job_rv
      rv.map { |j| j['payload'] }
    end

    def self.jobs_select_payload_args( job_rv: true )
      return [] unless job_queue_available?
      rv = Resque::Worker.all.map(&:job).select { |j| !j['payload'].nil? && j['payload']['args'].nil? } #; puts j['payload']['args'] };true
      return rv if job_rv
      rv.map { |j| j['payload']['args'] }
    end

    def self.jobs_select_payload_args2( job_rv: true )
      return [] unless job_queue_available?
      rv = Resque::Worker.all.map(&:job).select { |j| next if j['payload'].nil?;next if j['payload']['args'].nil?; puts "#{j['queue']}/#{j['payload']['args']}" };true
      return rv if job_rv
      rv.map { |j| j['queue'] }
    end

  end

end
