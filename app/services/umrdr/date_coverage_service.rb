require 'date'
require 'edtf'

module Umrdr
  class DateCoverageService  

    # EDTF's notation for interval begin and end when unspecified.
    EDTF_OPEN_BEGIN = :unknown
    EDTF_OPEN_END = :open

    class << self
      # Given a parameters hash with date coverage keys
      # Returns an EDTF Interval or nil.
      def params_to_interval( params )
        begin_date = make_begin_date(
                      year:  safe_to_i(params[:date_coverage_begin_year]),
                      month: safe_to_i(params[:date_coverage_begin_month]),
                      day:   safe_to_i(params[:date_coverage_begin_day])
        )
        end_date = make_end_date(
                      year:  safe_to_i(params[:date_coverage_end_year]),
                      month: safe_to_i(params[:date_coverage_end_month]),
                      day:   safe_to_i(params[:date_coverage_end_day])
        )
        interv = EDTF::Interval.new(begin_date, end_date)
        interv unless interval_reversed?(interv) || interval_both_ends_open?(interv)
      end

      # Given an EDTF Interval
      # Returns a corresponding hash of parameters for an edit form.
      def interval_to_params( interv )
        return unless interv.is_a?(EDTF::Interval)
        return if interval_reversed?(interv)
        make_begin_params(interv.begin).merge(make_end_params(interv.end))
      end

      private

      # Determines if an intervals endings are reverse.  Specifically, where the begin 
      # date is later that the end date.  An interval with reversed starting and ending
      # dates will have from and to attributes, but begin and end will be nil
      # == Parameters:
      # interv::
      #   [EDTF::Interval] The interval to be tested. 
      # == Returns:
      #   [Boolean] True if the interval boundaries were reversed
      def interval_reversed?(interv)
        return false if interv.from == EDTF_OPEN_BEGIN || interv.to == EDTF_OPEN_END 
        (interv.from && !interv.begin) && (interv.to && !interv.end)
      end

      def interval_both_ends_open?(interv)
        interv.from == EDTF_OPEN_BEGIN && interv.to == EDTF_OPEN_END 
      end

      def make_begin_params(date)
        hsh = date_to_params date
        {date_coverage_begin_year:  hsh[:year],
         date_coverage_begin_month: hsh[:month],
         date_coverage_begin_day:   hsh[:day]}
      end

      def make_end_params( date )
        hsh = date_to_params date
        {date_coverage_end_year:  hsh[:year],
         date_coverage_end_month: hsh[:month],
         date_coverage_end_day:   hsh[:day]}
      end

      # Given edtf date
      # return hash with possible keys :year, :month, :day
      def date_to_params( date )
        return {} unless date
        hsh = case date.precision
        when :year
          {year: date.year}
        when :month
          {year: date.year, month: date.month}
        when :day
          {year: date.year, month: date.month, day: date.day}
        end
        hsh[:year] = year_to_s hsh[:year]
        hsh.each{|k,v| hsh[k] = v.to_s}
      end

      def year_to_s(val)
        str = val.abs.to_s.rjust(4,"0")
        val < 0 ? "-" + str : str
      end

      # Given input
      # Return the corresponding integer or nil
      def safe_to_i(input)
        Integer(input,10) rescue nil
      end

      # Until 8601-2 gets finalized, edtf ranges do not accept :open for begin.
      def make_begin_date(year: nil, month: nil, day: nil)
        make_date(year: year, month: month, day: day) || EDTF_OPEN_BEGIN
      end

      def make_end_date(year: nil, month: nil, day: nil)
        make_date(year: year, month: month, day: day) || EDTF_OPEN_END
      end

      # Takes year, month, and day integers.
      # Returns edtf date or nil
      def make_date(year: nil, month: nil, day: nil)
        if year && month && day
          Date.new(year,month,day).day_precision!
        elsif year && month
          Date.new(year,month).month_precision!
        elsif year
          Date.new(year).year_precision!
        end
      end
    end
  end
end
