# frozen_string_literal: true

class Aptrust::Event < ApplicationRecord

  mattr_accessor :aptrust_event_debug_verbose, default: false

end
