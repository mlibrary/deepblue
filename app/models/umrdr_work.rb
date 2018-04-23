# Generated via
#  `rails generate hyrax:work UmrdrWork`
class UmrdrWork < ActiveFedora::Base

  ## begin `rails generate hyrax:work UmrdrWork`
  include ::Hyrax::WorkBehavior

  self.indexer = UmrdrWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  #validates :title, presence: { message: 'Your work must have a title.' }
  ## end `rails generate hyrax:work UmrdrWork`

  self.human_readable_type = 'Generic Work'
  include Umrdr::UmrdrWorkBehavior
  include Umrdr::UmrdrWorkMetadata
  validates :title, presence: { message: 'Your work must have a title.' }
  validates :creator, presence: { message: 'Your work must have a creator.' }
  validates :description, presence: { message: 'Your work must have a description.' }
  validates :methodology, presence: { message: 'Your work must have a description of the method for collecting the dataset.' }
  validates :rights_statement, presence: { message: 'You must select a license for your work.' }
  validates :authoremail, presence: { message: 'You must have author contact information.' }

  ## begin `rails generate hyrax:work UmrdrWork`
  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  ## end `rails generate hyrax:work UmrdrWork`

  after_initialize :set_defaults

  PENDING = 'pending'.freeze

  def set_defaults
    return unless new_record?
    self.resource_type = ["Dataset"]
  end

  # Visibility helpers
  def private?
    visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  end

  def public?
    visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end

  #
  # handle the list of creators as ordered
  #
  def creator
    values = super
    values = MetadataHelper.ordered( ordered_values: self.creator_ordered, values: values )
    return values
  end

  def creator= values
    self.creator_ordered = MetadataHelper.ordered_values( ordered_values: self.creator_ordered, values: values )
    super values
  end

  #
  # handle the list of description as ordered
  #
  def description
    values = super
    values = MetadataHelper.ordered( ordered_values: self.description_ordered, values: values )
    return values
  end

  def description= values
    self.description_ordered = MetadataHelper.ordered_values( ordered_values: self.description_ordered, values: values )
    super values
  end

  #
  # Make it so work does not show up in search result for anyone, not even admins.
  #
  def entomb!(epitaph)
    self.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    self.depositor = 'TOMBSTONE-' + depositor
    self.tombstone = [epitaph]

    file_sets.each do |file_set|
      file_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    save
  end

  #
  # handle the list of isReferencedBy as ordered
  #
  def isReferencedBy
    values = super
    values = MetadataHelper.ordered( ordered_values: self.isReferencedBy_ordered, values: values )
    return values
  end

  def isReferencedBy= values
    self.isReferencedBy_ordered = MetadataHelper.ordered_values( ordered_values: self.isReferencedBy_ordered, values: values )
    super values
  end

  #
  # handle the list of keyword as ordered
  #
  def keyword
    values = super
    values = MetadataHelper.ordered( ordered_values: self.keyword_ordered, values: values )
    return values
  end

  def keyword= values
    self.keyword_ordered = MetadataHelper.ordered_values( ordered_values: self.keyword_ordered, values: values )
    super values
  end

  #
  # handle the list of language as ordered
  #
  def language
    values = super
    values = MetadataHelper.ordered( ordered_values: self.language_ordered, values: values )
    return values
  end

  def language= values
    self.language_ordered = MetadataHelper.ordered_values( ordered_values: self.language_ordered, values: values )
    super values
  end

  #
  # handle the list of title as ordered
  #
  def title
    values = super
    values = MetadataHelper.ordered( ordered_values: self.title_ordered, values: values )
    return values
  end

  def title= values
    self.title_ordered = MetadataHelper.ordered_values( ordered_values: self.title_ordered, values: values )
    super values
  end

end
