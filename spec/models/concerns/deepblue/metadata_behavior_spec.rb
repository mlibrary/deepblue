# frozen_string_literal: true

require_relative '../../../../app/models/concerns/deepblue/abstract_event_behavior'
require_relative '../../../../app/models/concerns/deepblue/metadata_behavior'

class CurationConcernEmptyMock
  include ::Deepblue::MetadataBehavior
end

class CurationConcernMock
  include ::Deepblue::MetadataBehavior

  def description
    ['The Description']
  end

  def id
    'id123'
  end

  def title
    ['The Title', 'Part 2']
  end

  def visiblity
    Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  end

  def metadata_keys_all
    %i[ id title description ]
  end

  def metadata_keys_brief
    %i[ id title ]
  end

  def metadata_hash_override( key:, ignore_blank_values:, key_values: )
    value = nil
    handled = case key.to_s
              when 'description'
                value = description
                true
              else
                false
              end
    return false unless handled
    if ignore_blank_values
      key_values[key] = value if value.present?
    else
      key_values[key] = value
    end
    return true
  end

end

RSpec.describe Deepblue::AbstractEventBehavior do

  let( :empty_mock ) { CurationConcernEmptyMock.new }
  let( :mock ) { CurationConcernMock.new }

  describe 'constants' do
    it do
      expect( Deepblue::MetadataBehavior::METADATA_FIELD_SEP ).to eq '; '
      expect( Deepblue::MetadataBehavior::METADATA_REPORT_DEFAULT_DEPTH ).to eq 2
      expect( Deepblue::MetadataBehavior::METADATA_REPORT_DEFAULT_FILENAME_POST ).to eq '_metadata_report'
      expect( Deepblue::MetadataBehavior::METADATA_REPORT_DEFAULT_FILENAME_EXT ).to eq '.txt'
    end
  end

  describe 'default values' do
    it do
      expect( empty_mock.metadata_keys_all ).to eq []
      expect( empty_mock.metadata_keys_brief ).to eq []
      expect( empty_mock.metadata_hash_override( key: 'key', ignore_blank_values: false, key_values: [ key: 'value' ] ) ).to eq false
      expect( empty_mock.metadata_report_label_override(metadata_key: 'key', metadata_value: 'value' ) ).to eq nil
      ignore_blank_key_values, keys = empty_mock.metadata_report_keys
      expect( ignore_blank_key_values ).to eq ::Deepblue::AbstractEventBehavior::IGNORE_BLANK_KEY_VALUES
      expect( keys ).to eq []
      expect( empty_mock.metadata_report_contained_objects ).to eq []
      expect( empty_mock.metadata_report_title_pre ).to eq ''
      expect( empty_mock.metadata_report_title_field_sep ).to eq ' '
    end
  end

  describe 'metadata_hash' do
    let( :empty_hash ) { {} }
    let( :expected_hash_all ) { { id: mock.id, title: mock.title, description: mock.description } }
    let( :expected_hash_brief ) { { id: mock.id, title: mock.title } }
    let( :expected_kv_hash_all ) { { key: 'value', id: mock.id, title: mock.title, description: mock.description } }
    let( :expected_kv_hash_brief ) { { key: 'value', id: mock.id, title: mock.title } }
    context 'empty' do
      it do
        expect( mock.metadata_hash( metadata_keys: [], ignore_blank_values: false ) ).to eq empty_hash
        expect( mock.metadata_hash( metadata_keys: [], ignore_blank_values: false, **empty_hash ) ).to eq empty_hash
      end
    end
    context 'returns correct value for id, title' do
      it do
        expect( mock.metadata_hash( metadata_keys: mock.metadata_keys_brief, ignore_blank_values: false ) ).to eq expected_hash_brief
        expect( mock.metadata_hash( metadata_keys: mock.metadata_keys_all, ignore_blank_values: false ) ).to eq expected_hash_all
        kv_hash = { key: 'value' }
        expect( mock.metadata_hash( metadata_keys: mock.metadata_keys_brief, ignore_blank_values: false, **kv_hash ) ).to eq expected_kv_hash_brief
        kv_hash = { key: 'value' }
        expect( mock.metadata_hash( metadata_keys: mock.metadata_keys_all, ignore_blank_values: false, **kv_hash ) ).to eq expected_kv_hash_all
      end
    end
  end

  describe 'metadata_report_filename' do
    let( :pathname_dir ) { "/some/path" }
    let( :filename_pre ) { "pre_" }
    context 'basic parms' do
      it do
        expect( mock.metadata_report_filename( pathname_dir: Pathname.new( pathname_dir ),
                                               filename_pre: filename_pre ) ).to eq Pathname.new "/some/path/pre_id123_metadata_report.txt"
      end
    end
    context 'all parms' do
      it do
        expect( mock.metadata_report_filename( pathname_dir: Pathname.new( pathname_dir ),
                                               filename_pre: filename_pre,
                                               filename_post: "_post",
                                               filename_ext: ".ext" ) ).to eq Pathname.new "/some/path/pre_id123_post.ext"
      end
    end
  end

end
