# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::CleanDerivativesDirService do

  # let(:sched_helper) { class_double( Hyrax::EmbargoHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'constants' do
    it "resolves them" do
      expect( described_class.clean_derivatives_dir_service_debug_verbose ).to eq false
    end
  end

  describe 'shared' do

    RSpec.shared_examples 'CleanDerivativesDirService' do |debug_verbose_count|
      let(:dbg_verbose)   { debug_verbose_count > 0 }
      let(:time_before)   { DateTime.now }
      let(:base_dir)      {Pathname.new ::Deepblue::DiskUtilitiesHelper.tmp_derivatives_path}
      before do
        if 0 < debug_verbose_count
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
      end

      it 'it calls the service' do
        save_debug_verbose = described_class.clean_derivatives_dir_service_debug_verbose
        described_class.clean_derivatives_dir_service_debug_verbose = dbg_verbose
        time_after = DateTime.now
        expect(::Deepblue::DiskUtilitiesHelper).to receive(:tmp_derivatives_path).twice.and_call_original
        expect(::Deepblue::DiskUtilitiesHelper).to receive(:delete_dirs_glob_regexp).with( base_dir: base_dir,
                                                                                           glob: '?' * 9,
                                                                                           filename_regexp: /^[0-9a-z]{9}$/,
                                                                                           days_old: days_old,
                                                                                           recursive: false )
        expect(::Deepblue::DiskUtilitiesHelper).to receive(:delete_files_glob_regexp).with( base_dir: base_dir,
                                                                                            glob: "mini_magick*",
                                                                                            filename_regexp: nil,
                                                                                            days_old: days_old )
        expect(::Deepblue::DiskUtilitiesHelper).to receive(:delete_files_glob_regexp).with( base_dir: base_dir,
                                                                                            glob: "apache-tika-*.tmp",
                                                                                            filename_regexp: nil,
                                                                                            days_old: days_old )
        service = described_class.new( days_old: days_old,
                                       job_msg_queue: job_msg_queue,
                                       to_console: false,
                                       verbose: verbose )
        allow(service).to receive(:report_du).and_return "disk usage"
        service.run
        # expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
        described_class.clean_derivatives_dir_service_debug_verbose = save_debug_verbose
      end

    end

  end

  describe 'calls the service' do
    let(:days_old)      { 7 }
    let(:job_msg_queue) { [] }
    let(:to_console)    { false }
    let(:verbose)       { true }
    debug_verbose_count = 0
    it_behaves_like 'CleanDerivativesDirService', debug_verbose_count
  end

end
