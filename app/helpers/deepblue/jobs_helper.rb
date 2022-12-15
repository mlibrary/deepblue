# frozen_string_literal: true

module Deepblue

  module JobsHelper

    mattr_accessor :jobs_helper_debug_verbose, default: false

    def self.job_by_job_id( job_id )
      jobs = jobs_running_by_id( job_id: job_id )
      return nil unless jobs.present?
      return jobs[0]
    end

    def self.job_running?( job_id )
      jobs = jobs_running_by_id( job_id: job_id )
      rv = jobs.present?
      return rv
    end

    def self.job_value_by_keys( job:, keys: )
      max = keys.size - 1
      hash = job
      for index in 0..max do
        hash = hash[0] if hash.is_a? Array
        key = keys[index]
        return nil unless hash.key? key
        hash = hash[key]
      end
      return hash
    end

    def self.jobs_running
      rv = Resque::Worker.all.map(&:job).select { |j| !j.empty? }
      return rv
    end

    def self.jobs_running?
      jobs = jobs_running
      return jobs.present?
    end

    def self.jobs_running_msg
      jobs = jobs_running
      return MsgHelper.t( 'hyrax.jobs.running', job_count: jobs.size, now: MsgHelper.display_now  )
    end

    def self.jobs_running_by( key:, value: )
      rv = Resque::Worker.all.map(&:job).select { |j| j[key].present? && value == j[key] }
      return rv
    end

    def self.jobs_running_by_keys( keys: )
      keys = Array(keys)
      jobs = jobs_running_if( key: keys[0] )
      max = keys.size - 1
      for index in 0..max do
        rv = rv.map do |e|
          e = e[0] if e.is_a? Array
          e[keys[index]]
        end
      end
      return rv
    end

    def self.jobs_running_by_keys_value( keys:, value: )
      jobs = Resque::Worker.all.map(&:job)
      rv = jobs.select { |job| value == job_value_by_keys( job: job, keys: keys ) }
      return rv
    end

    def self.jobs_running_if( key: )
      rv = Resque::Worker.all.map(&:job).select { |j| j[key].present? }
      return rv
    end

    def self.jobs_running_by_class( klass: )
      jobs_running_by_keys_value( keys: ['payload', 'args', 'job_class' ], value: klass.name )
    end

    def self.jobs_running_by_id( job_id: )
      jobs_running_by_keys_value( keys: ['payload', 'args', 'job_id' ], value: job_id )
    end

    # def self.job_by_job_id( job_id )
    #   rv = Resque::Worker.find(job_id)
    #   return rv
    # end

    def self.jobs_running_by_queue( queue: )
      jobs_running_by( key: 'queue', value: queue )
    end

    def self.jobs_select_job_class( job_rv: true )
      rv = jobs_running_if( key: 'job_class' )
      return rv if job_rv
      rv.map { |j| j['job_class'] }
    end

    def self.jobs_select_queue( job_rv: true )
      rv = jobs_running_if( key: 'queue' )
      return rv if job_rv
      rv.map { |j| j['queue'] }
    end

    def self.jobs_select_payload( job_rv: true )
      rv = jobs_running_if( key: 'payload' )
      return rv if job_rv
      rv.map { |j| j['payload'] }
    end

    def self.jobs_select_payload_args( job_rv: true )
      rv = Resque::Worker.all.map(&:job).select { |j| !j['payload'].nil? && j['payload']['args'].nil? } #; puts j['payload']['args'] };true
      return rv if job_rv
      rv.map { |j| j['payload']['args'] }
    end

    def self.jobs_select_payload_args2( job_rv: true )
      rv = Resque::Worker.all.map(&:job).select { |j| next if j['payload'].nil?;next if j['payload']['args'].nil?; puts "#{j['queue']}/#{j['payload']['args']}" };true
      return rv if job_rv
      rv.map { |j| j['queue'] }
    end

  end

end
