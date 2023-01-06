# frozen_string_literal: true

# keywords: example send

require 'rails_helper'

require_relative "../../../app/services/deepblue/new_content_append_service"

# Use this mock to create instances that are not fully instantiated in order
# to test methods that are independent of the state of the object.
# And to get access to protected and private methods without using "send".
class MockNewContentAppendService < ::Deepblue::NewContentAppendService

  def initialize_with_msg( options:,
                           path_to_yaml_file:,
                           cfg_hash:,
                           base_path:,
                           mode: nil,
                           ingester: nil,
                           use_rails_logger: false,
                           user_create: DEFAULT_USER_CREATE,
                           msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE",
                           **config )

    # ignore for testing purposes
  end

  def update_cc_attribute( curation_concern:, attribute:, value: )
    super( curation_concern: curation_concern, attribute: attribute, value: value )
  end

  def update_cc_edit_users( curation_concern:, edit_users: )
    super( curation_concern: curation_concern, edit_users: edit_users )
  end

  def update_cc_read_users( curation_concern:, read_users: )
    super( curation_concern: curation_concern, read_users: read_users )
  end

  def update_visibility( curation_concern:, visibility: )
    super( curation_concern: curation_concern, visibility: visibility )
  end

  def valid_restricted_vocab( value, var:, vocab:, error_class: RestrictedVocabularyError )
    super( value, var: var, vocab: vocab, error_class: error_class )
  end

  def visibility_curation_concern( vis )
    super( vis )
  end

end

RSpec.describe ::Deepblue::NewContentAppendService, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.new_content_append_service_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.new_content_append_service_add_debug_verbose ).to eq false }
    it { expect( described_class.new_content_append_service_touch_debug_verbose ).to eq false }
  end

  describe 'module variables' do
    it { expect( described_class.new_content_append_service_touch_debug_verbose ).to eq false }
  end

end
