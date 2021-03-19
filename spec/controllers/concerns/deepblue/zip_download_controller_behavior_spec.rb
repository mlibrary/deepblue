require 'rails_helper'


require_relative '../../../../app/controllers/hyrax/deepblue_controller'
require_relative '../../../../app/controllers/concerns/deepblue/zip_download_controller_behavior'

class MockDeepblueZipDownloadControllerBehavior

  include Deepblue::ZipDownloadControllerBehavior

  attr_accessor :curation_concern, :current_user, :current_ability, :params

  def zip_download_rest( curation_concern: )
    super(curation_concern: curation_concern)
  end

  def target_dir_name_id( dir, id, ext = '' )
    # see DataSetController#target_dir_name_id
    dir.join "#{id}#{ext}"
  end

  def send_file( filename )

  end

end


RSpec.describe Deepblue::ZipDownloadControllerBehavior, skip: false do

  include Devise::Test::ControllerHelpers
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:user) { create(:user) }

  before { sign_in user }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.zip_download_controller_behavior_debug_verbose ).to eq( false )
    end
  end

  describe '.zip_download_enabled?' do
    subject { MockDeepblueZipDownloadControllerBehavior.new }
    it { expect( subject.zip_download_enabled? ).to eq ::Deepblue::ZipDownloadService.zip_download_enabled }
  end

  describe '.zip_download_rest', skip: false do
    subject { MockDeepblueZipDownloadControllerBehavior.new }

    RSpec.shared_examples 'it calls zip_download_rest' do |debug_verbose|
      let(:work) { create(:data_set_with_two_children, total_file_size: 1.kilobyte, user: user) }
      let(:zip_msg) { nil }
      let(:tmp)     { ENV['TMPDIR'] || "/tmp" }
      let(:tmp_dir) { Pathname.new(tmp) }
      let(:target_dir) { tmp_dir.join "#{work.id}" }
      let(:target_file) { target_dir.join "#{work.id}.zip" }

      before do
        if debug_verbose
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once)
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
        expect(subject).to receive(:target_dir_name_id).with( tmp_dir, work.id ).and_call_original
        expect(subject).to receive(:target_dir_name_id).with( target_dir, work.id, '.zip' ).and_call_original
        expect(subject).to receive(:send_file).with( target_file.to_s ).and_return nil
        expect(File).to_not receive(:delete)
        expect(Zip::File).to receive(:open).with(target_file.to_s, Zip::File::CREATE).and_call_original
        expect(::Deepblue::ExportFilesHelper).to receive(:export_file_sets) do |args|
          expect( args[:target_dir]).to eq target_dir
          expect( args[:file_sets] ).to eq work.file_sets
          expect( args[:log_prefix] ).to eq "Zip: "
           # do_export_predicate: ->(_target_file_name, _target_file) { true },
           # quiet: !zip_download_controller_behavior_debug_verbose )
        end.and_call_original
      end

      it 'it calls zip_download_rest' do
        # expect(subject).to receive(:zip_download_rest).with(curation_concern: work).and_call_original
        save_debug_verbose = described_class.zip_download_controller_behavior_debug_verbose
        described_class.zip_download_controller_behavior_debug_verbose = debug_verbose
        expect(subject.zip_download_rest(curation_concern: work)).to eq zip_msg
        described_class.zip_download_controller_behavior_debug_verbose = save_debug_verbose
      end

    end

    context 'normal' do
      it_behaves_like 'it calls zip_download_rest', false
    end
    context 'debug verbose' do
      it_behaves_like 'it calls zip_download_rest', true
    end

  end

end
