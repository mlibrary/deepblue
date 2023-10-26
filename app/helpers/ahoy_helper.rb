# frozen_string_literal: true

module AhoyHelper

  mattr_accessor :ahoy_helper_debug_verbose, default:false # Rails.configuration.ahoy_helper_debug_verbose

  # def self.add_ip( ips, visit, event_count )
  #   ips ||= {}
  #   ip = visit.ip
  #   ip_info = ips[ip];ip_info ||= { visit_ids: [], event_count: 0 }
  #   ip_info[:visit_ids] << visit.id
  #   ip_info[:event_count] = ip_info[:event_count] + event_count
  #   ips[ip] = ip_info
  #   return ips
  # end
  #
  # def self.crawler_ip( ip )
  #   return true if ip.start_with?("66.249.6")
  #   return true if ip.start_with?("66.249.7")
  #   return false
  # end
  #
  # def self.delete_visit( visit_id )
  #   visit = Ahoy::Visit.where(id: visit_id);return if visit.blank?
  #   Ahoy::Event.where(visit_id: visit_id).each { |row| row.delete }
  #   visit.each { |visit| visit.delete }
  # end
  #
  # def self.delete_visit_reason( ips, ip )
  #   return "crawler_ip" if crawler_ip(ip)
  #   return "high_visit_count" if high_visit_count(ips,ip)
  #   return "high_event_count" if high_event_count(ips,ip)
  #   return ""
  # end
  #
  # def self.delete_visits(ips,delete)
  #   return unless delete
  #   ips.keys.each do |ip|
  #     delete_visits_by_ip(ips,ip) unless delete_visit_reason(ips,ip).blank?
  #   end
  # end
  #
  # def self.delete_visits_by_ip(ips,ip); ips[ip][:visit_ids].each { |visit_id| delete_visit( visit_id ) }; end
  #
  # def self.events( begin_date, end_date ) Ahoy::Event.where(['time >= ? AND time < ?', begin_date, end_date]); end
  #
  # def self.high_visit_count(ips,ip); ips[ip][:visit_ids].size > 999; end
  #
  # def self.high_event_count(ips,ip); ips[ip][:event_count] > 9999; end
  #
  # def self.save_ips( ips, file )
  #   CSV.open( file, 'w', {:force_quotes=>true} ) do |out|
  #     out << %w[ ip visit_count event_count delete_visit_reason ]
  #     ips.keys.each do |ip|
  #       ip_info = ips[ip]; out << [ ip, ip_info[:visit_ids].size, ip_info[:event_count], delete_visit_reason(ips,ip) ]
  #     end
  #   end
  # end
  #
  # def self.save_rows( ips, file, rows )
  #   CSV.open( file, 'w', {:force_quotes=>true} ) do |out|
  #     out << %w[ started_at id ip event_count user_agent ]
  #     rows.each do |row|
  #       event_count = Ahoy::Event.where(visit_id: row.id).size
  #       out << [ row.id, row.started_at, row.ip, event_count, row.user_agent ]
  #       ips = add_ip( ips, row,event_count )
  #     end
  #   end
  #   return ips
  # end
  #
  # def self.visits( begin_date, end_date ) Ahoy::Visit.where(['started_at >= ? AND started_at < ?', begin_date, end_date]); end
  #
  # def self.by_day
  #
  # end
  #
  # def self.by_month
  #   begin_date=DateTime.new(2021,1,1)
  #   inc=32.days
  #   end_date=begin_date + inc;end_date=end_date.beginning_of_month
  #   final_date=DateTime.now + 1.day
  #   dir="/deepbluedata-prep/ahoy/";base="month_visits.csv"
  #   ips = {}
  #   delete=false
  #   while ( final_date > begin_date )
  #     puts "Starting: >= #{begin_date} to < #{end_date}"
  #     rows = visits( begin_date, end_date )
  #     if 0 == rows.size
  #       puts "  Skipped: >= #{begin_date} to < #{end_date}"
  #     else
  #       puts "  Processing #{rows.size} rows..."
  #       ips = save_rows( ips, "#{dir}#{begin_date.strftime('%Y%m%d')}_#{base}", rows )
  #       save_ips( ips, "#{dir}#{begin_date.strftime('%Y%m%d')}_ip_#{base}" )
  #       delete_visits(ips,delete)
  #       ips = {}
  #       puts "  Finished: >= #{begin_date} to < #{end_date}"
  #     end
  #     begin_date = end_date
  #     end_date=begin_date + inc;end_date=end_date.beginning_of_month
  #   end
  # end
  #
  # def self.by_week
  #   begin_date=DateTime.now.beginning_of_day - (10*7.days)
  #   inc=7.days
  #   #trim_date=begin_date + inc
  #   trim_date=DateTime.now + 1.day
  #   dir="/deepbluedata-prep/ahoy/";base="week_visits.csv"
  #   ips = {}
  #   delete=false
  #   while ( trim_date > begin_date )
  #     puts "Starting: >= #{begin_date} to < #{begin_date + inc}"
  #     rows = visits( begin_date, begin_date + inc )
  #     if 0 == rows.size
  #       puts "  Skipped: >= #{begin_date} to < #{begin_date + inc}"
  #     else
  #       puts "  Processing #{rows.size} rows..."
  #       ips = save_rows( ips, "#{dir}#{begin_date.strftime('%Y%m%d')}_#{base}", rows )
  #       save_ips( ips,"#{dir}#{begin_date.strftime('%Y%m%d')}_ip_#{base}" )
  #       delete_visits(ips,delete)
  #       ips = {}
  #       puts "  Finished: >= #{begin_date} to < #{begin_date + inc}"
  #     end
  #     begin_date = begin_date + inc
  #   end
  # end
  #
  # def self.clean_dangling_events
  #   span = 1
  #   inc=1.day
  #   @delete=true
  #
  #   begin_date=DateTime.new(2021,1,1).beginning_of_day
  #   trim_date=DateTime.now + 1.day
  #   @ips = {}
  #   while ( trim_date > begin_date )
  #     puts "Starting: >= #{begin_date} to < #{begin_date + inc}"
  #     rows = events( begin_date, begin_date + inc );true
  #     if 0 == rows.size
  #       puts "  Skipped: >= #{begin_date} to < #{begin_date + inc}"
  #     else
  #       processed = 0
  #       puts "  Processing #{rows.size} rows..."
  #       rows.each do |row|
  #         visit = Ahoy::Visit.where( id: row.visit_id )
  #         if visit.blank?
  #           processed += 1
  #           row.delete if @delete
  #         end
  #       end
  #       puts "  Finished: >= #{begin_date} to < #{begin_date + inc} -- processed #{processed} rows."
  #     end
  #     begin_date = begin_date + inc
  #   end
  # end

end
