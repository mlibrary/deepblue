# frozen_string_literal: true

class EmailSubscription < ApplicationRecord

  serialize :subscription_parameters, JSON

end
