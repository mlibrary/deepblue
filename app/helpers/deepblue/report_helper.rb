# frozen_string_literal: true

require './lib/irus_logger'
require_relative './logging_helper'

module Deepblue

  module ReportHelper

    mattr_accessor :report_helper_debug_verbose, default: false

    def self.expand_path_partials( path )
      return path unless path.present?
      now = Time.now
      path = path.gsub( /\%date\%/, "#{now.strftime('%Y%m%d')}" )
      path = path.gsub( /\%time\%/, "#{now.strftime('%H%M%S')}" )
      path = path.gsub( /\%timestamp\%/, "#{now.strftime('%Y%m%d%H%M%S')}" )
      path = path.gsub( /\%hostname\%/, "#{Rails.configuration.hostname}" )
      return path
    end

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
      when /^now\s+([+-])\s*([0-9]+)\s+(days?|weeks?|months?|years?)$/
        plus_minus = Regexp.last_match 1
        number = Regexp.last_match 2
        number = number.to_i
        units = Regexp.last_match 3
        if '-' == plus_minus
          case units
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

  end

end
