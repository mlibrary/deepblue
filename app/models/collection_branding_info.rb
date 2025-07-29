# frozen_string_literal: true
# Reviewed: hyrax4

class CollectionBrandingInfo < ApplicationRecord

  # create_table :collection_branding_infos do |t|
  #   t.string :collection_id
  #   t.string :role
  #   t.string :local_path
  #   t.string :alt_text
  #   t.string :target_url
  #   t.integer :height
  #   t.integer :width
  #
  #   t.timestamps
  # end

  # attr_accessor :alt_txt # don't hide record columns with accessors
  attr_accessor :filename
  #after_initialize :set_collection_attributes

  mattr_accessor :collection_branding_info_debug_verbose, default: false

  def self.create( collection_id:,
                   filename:,
                   role:,
                   alt_txt: "",
                   target_url: "" )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "collection_id=#{collection_id}",
                                           "role=#{role}",
                                           "alt_txt=#{alt_txt}",
                                           "target_url=#{target_url}",
                                           "filename=#{filename}",
                                           "" ] if collection_branding_info_debug_verbose
    rec = CollectionBrandingInfo.new()
    # rec = CollectionBrandingInfo.new( collection_id: collection_id,
    #                                   filename: filename,
    #                                   role: role,
    #                                   alt_txt: alt_txt,
    #                                   target_url: target_url )
    rec.collection_id = collection_id
    rec.role = role
    rec.alt_text = alt_txt
    rec.target_url = target_url
    rec.local_path = File.join(role, filename)
    return rec
  end

  # def initialize(collection_id:,
  #                filename:,
  #                role:,
  #                alt_txt: "",
  #                target_url: "")
  #
  #   super()
  #   self.collection_id = collection_id
  #   self.role = role
  #   self.alt_text = alt_txt
  #   self.target_url = target_url
  #   self.local_path = File.join(role, filename)
  # end

  def save(file_location, upload_file = true)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_location=#{file_location}",
                                           "File.exist?(file_location)=#{File.exist?(file_location)}",
                                           "upload_file=#{upload_file}",
                                           "" ] if collection_branding_info_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "self.collection_id=#{self.collection_id}",
                                           "self.role=#{self.role}",
                                           "self.alt_text=#{self.alt_text}",
                                           "self.target_url=#{self.target_url}",
                                           "self.local_path=#{self.local_path}",
                                           "" ] if collection_branding_info_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "local_path=#{local_path}",
                                           "" ] if collection_branding_info_debug_verbose
    filename = File.split(local_path).last
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "" ] if collection_branding_info_debug_verbose
    role_and_filename = File.join(role, filename)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "role_and_filename=#{role_and_filename}",
                                           "" ] if collection_branding_info_debug_verbose
    if upload_file
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "storage.class.name=#{storage.class.name}",
                                             "" ] if collection_branding_info_debug_verbose
      rvStorage = storage
      rvStorage.upload(resource: Hyrax::PcdmCollection.new(id: collection_id),
                     file: File.open(file_location),
                     original_filename: role_and_filename)
    end

    self.local_path = find_local_filename(collection_id, role, filename)

    FileUtils.remove_file(file_location) if File.exist?(file_location) && upload_file
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "about to call super()",
                                           "self.collection_id=#{self.collection_id}",
                                           "self.role=#{self.role}",
                                           "self.alt_text=#{self.alt_text}",
                                           "self.target_url=#{self.target_url}",
                                           "self.local_path=#{self.local_path}",
                                           "" ] if collection_branding_info_debug_verbose
    super()
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "after call super()",
                                           "" ] if collection_branding_info_debug_verbose
  end

  def delete(location_path = nil)
    id = if location_path
           Deprecation.warn('Passing an explict location path is ' \
                            'deprecated. Call without arguments instead.')
           location_path
         else
           local_path
         end
    storage.delete(id: id)
  end

  def find_local_filename(collection_id, role, filename)
    local_dir = find_local_dir_name(collection_id, role)
    File.join(local_dir, filename)
  end

  def find_local_dir_name(collection_id, role)
    File.join(Hyrax.config.branding_path, collection_id.to_s, role.to_s)
  end

  private

  # def set_collection_attributes
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                          ::Deepblue::LoggingHelper.called_from,
  #                                          "collection_id=#{collection_id}",
  #                                          "role=#{role}",
  #                                          "alt_txt=#{alt_txt}",
  #                                          "filename=#{filename}",
  #                                          "rec.pretty_inspect=" ] + rec.pretty_inspect if collection_branding_info_debug_verbose
  #   self.alt_text ||= alt_txt || ''
  #   self.local_path ||= File.join(role, filename)
  # end

  def storage
    Hyrax.config.branding_storage_adapter
  end
end
