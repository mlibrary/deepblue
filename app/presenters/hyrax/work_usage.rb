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

      attributes = %w{date count}
      CSV.generate(headers: true) do |csv|
        csv << attributes

        data.uniq.each do |sub_array|
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
