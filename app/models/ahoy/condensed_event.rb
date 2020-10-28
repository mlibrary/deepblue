class Ahoy::CondensedEvent < ApplicationRecord

  self.table_name = "ahoy_condensed_events"

  serialize :condensed_data, JSON

end
