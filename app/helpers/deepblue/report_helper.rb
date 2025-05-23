# frozen_string_literal: true

require './lib/irus_logger'
require_relative './logging_helper'

module Deepblue

  module ReportHelper

    mattr_accessor :report_helper_debug_verbose, default: false

    HOSTNAME_SHORT_MAP = { 'deepblue.local' => 'local',
                           'testing.deepblue.lib.umich.edu' => 'testing',
                           'staging.deepblue.lib.umich.edu' => 'staging',
                           'deepblue.lib.umich.edu' => 'production' }.freeze unless const_defined? :HOSTNAME_SHORT_MAP

    def self.expand_path_partials( path, task: nil )
      return path unless path.present?
      now = Time.now
      path = path.gsub( /\%report_path\%/,   "#{report_path}" )
      path = path.gsub( /\%date\%/,          "#{now.strftime('%Y%m%d')}" )
      path = path.gsub( /\%time\%/,          "#{now.strftime('%H%M%S')}" )
      path = path.gsub( /\%timestamp\%/,     "#{now.strftime('%Y%m%d%H%M%S')}" )
      path = path.gsub( /\%hostname\%/,      "#{hostname_short}" )
      path = path.gsub( /\%hostname_full\%/, "#{Rails.configuration.hostname}" )
      path = path.gsub( /\%task\%/,          task ) if task.present?
      return path
    end

    def self.hostname_short( hostname: Rails.configuration.hostname )
      rv = HOSTNAME_SHORT_MAP[hostname]
      rv ||= hostname
      return rv
    end

    def self.report_path
      hostname = hostname_short
      return './data/reports/' if 'local' == hostname
      return '/deepbluedata-prep/reports/'
    end

    # date: 'now'
    # date: 'now +/- # minute/hour/day/week/month/year'
    def self.to_datetime( date:, format: nil, msg_handler:, raise_errors: true, msg_postfix: '' )
      return nil if date.blank?
      if format.present?
        begin
          return DateTime.strptime( date, format )
        rescue ArgumentError => e
          msg_handler.msg_error "Failed to format the date string '#{date}' using format '#{format}'#{msg_postfix}"
          raise e if raise_errors
        end
      end
      case date
      when /^now$/
        return DateTime.now
      when /^now\s+([+-])\s*([0-9]+)\s+(minutes?|hours?|days?|weeks?|months?|years?)$/
        plus_minus = Regexp.last_match 1
        number = Regexp.last_match 2
        number = number.to_i
        units = Regexp.last_match 3
        if '-' == plus_minus
          case units
          when 'minute'
            return DateTime.now - number.minute
          when 'minutes'
            return DateTime.now - number.minutes
          when 'hour'
            return DateTime.now - number.hour
          when 'hours'
            return DateTime.now - number.hours
          when 'day'
            return DateTime.now - number.day
          when 'days'
            return DateTime.now - number.days
          when 'week'
            return DateTime.now - number.week
          when 'weeks'
            return DateTime.now - number.weeks
          when 'month'
            return DateTime.now - number.month
          when 'months'
            return DateTime.now - number.months
          when 'year'
            return DateTime.now - number.year
          when 'years'
            return DateTime.now - number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        else
          case units
          when 'day'
            return DateTime.now + number.day
          when 'days'
            return DateTime.now + number.days
          when 'week'
            return DateTime.now + number.week
          when 'weeks'
            return DateTime.now + number.weeks
          when 'month'
            return DateTime.now + number.month
          when 'months'
            return DateTime.now + number.months
          when 'year'
            return DateTime.now + number.year
          when 'years'
            return DateTime.now + number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        end
      else
        begin
          return DateTime.parse( date )
        rescue ArgumentError => e
          msg_handler.msg_error "Failed parse relative ('now') date string '#{date}' (ignoring format '#{format}')#{msg_postfix}"
          raise e if raise_errors
        end
      end
    end

    # duration: number string of seconds
    # duration: '+/-? # minute/hour/day/week/month/year'
    def self.to_duration( duration:, raise_errors: true, msg_postfix: '' )
      return 0 if duration.blank?
      case duration
      when /^([+-]?)\s*([0-9_]+)\s+(minutes?|hours?|days?|weeks?|months?|years?)$/
        plus_minus = Regexp.last_match 1
        number = Regexp.last_match 2
        number = Integer( number )
        units = Regexp.last_match 3
        if '-' == plus_minus
          case units
          when 'minute'
            return number.minute
          when 'minutes'
            return - number.minutes
          when 'hour'
            return - number.hour
          when 'hours'
            return - number.hours
          when 'day'
            return - number.day
          when 'days'
            return - number.days
          when 'week'
            return - number.week
          when 'weeks'
            return - number.weeks
          when 'month'
            return - number.month
          when 'months'
            return - number.months
          when 'year'
            return - number.year
          when 'years'
            return - number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        else
          case units
          when 'day'
            return  number.day
          when 'days'
            return  number.days
          when 'week'
            return  number.week
          when 'weeks'
            return  number.weeks
          when 'month'
            return  number.month
          when 'months'
            return  number.months
          when 'year'
            return  number.year
          when 'years'
            return  number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        end
      else
        begin
          return Integer( duration ).seconds
        rescue ArgumentError => e
          msg_handler.msg_error "Failed to parse integer duration string '#{duration}'#{msg_postfix}"
          raise e if raise_errors
        end
      end
    end

  end

end
