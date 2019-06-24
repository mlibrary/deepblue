# Generated via
#  `rails generate hyrax:work Doc`
class Doc < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = DocIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  #include ::Hyrax::BasicMetadata
  #include ::Deepblue::DefaultMetadata

  include Umrdr::UmrdrWorkBehavior
  include Umrdr::UmrdrWorkMetadata


  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Deepblue::DefaultMetadata

  include ::Deepblue::MetadataBehavior
  include ::Deepblue::EmailBehavior
  include ::Deepblue::ProvenanceBehavior
  include ::Deepblue::DoiBehavior
  include ::Deepblue::WorkflowEventBehavior


end