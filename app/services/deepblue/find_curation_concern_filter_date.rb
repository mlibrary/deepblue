# frozen_string_literal: true

module Deepblue

class FindCurationConcernFilterDate < AbstractFindCurationConcern

  attr_reader :begin_date, :end_date

  def to_datetime( date, format: nil )
    # TODO: see ReportHelper.to_datetime
    return nil if date.blank?
    date = date.strip
    date = date.downcase
    if format.nil?
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
        return DateTime.parse( date ) if format.nil?
      end
    end
    rv = nil
    begin
      rv = DateTime.strptime( date, format )
    rescue ArgumentError => e
      msg_handler.msg_error "ArgumentError in FindAndFixCurationConcernFilterDate.to_datetime( #{date}, #{format} )"
      raise e
    end
    return rv
  end

  def initialize( begin_date:, end_date: )
    @begin_date = to_datetime( begin_date )
    @end_date = to_datetime( end_date )
  end

  def include?( date )
    return false if date.nil?
    return date >= @begin if @end_date.nil?
    return date <= @end if @begin_date.nil?
    rv = date.between?( @begin_date, @end_date )
    return rv
  end

end

end
