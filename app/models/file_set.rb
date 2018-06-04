# frozen_string_literal: true

class FileSet < ActiveFedora::Base
  include Deepblue::FileSetMetadata # must be before `include ::Hyrax::FileSetBehavior`
  include ::Hyrax::FileSetBehavior
  include Deepblue::FileSetBehavior
end
