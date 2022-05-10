# frozen_string_literal: true

# monkey override

# class WorkUsage follows the model established by FileUsage
# Called by the stats controller, it finds cached work pageview data,
# and prepares it for visualization in /app/views/stats/work.html.erb
module Hyrax
  class WorkUsage < StatsUsagePresenter
    def initialize(id)
      self.model = Hyrax::WorkRelation.new.find(id)
    end

    alias work model
    delegate :to_s, to: :model

    def total_pageviews
      pageviews.reduce(0) { |total, result| total + result[1].to_i }
    end

    def to_csv
      data = self.to_flot[0][:data] 

      #This was used to test logic
      #data=[["a", 1], ["a", 2], ["b", 3], ["x", 7], ["c", 4], ["c", 5], ["y", 100]]

      cnt = 0
      final_data = []
      data.uniq.each do |sub_array|
        time = sub_array[0]
        count = sub_array[1]
        if cnt < 1 
           final_data << [time, count]
        else
          sample = final_data.last
          if ( cnt < data.size ) && ( sample[0].eql? time )
            final_data.last[1] = final_data.last[1] + count
          else
            final_data << [time, count]
          end
        end
        cnt += 1
       end

       title = ["title => " + self.work.title.first]
       attributes = %w{date count}

       CSV.generate(headers: true) do |csv|
         csv << title
         csv << attributes

         final_data.uniq.each do |sub_array|
          time = Time.at sub_array[0].to_i/1000
          count = sub_array[1]

          csv << [time, count]
         end
       end
    end

    # Package data for visualization using JQuery Flot
    def to_flot
      [
        { label: "Pageviews", data: pageviews }
      ]
    end

    private

      def pageviews
        to_flots WorkViewStat.statistics(model, created, user_id)
      end
  end
end
