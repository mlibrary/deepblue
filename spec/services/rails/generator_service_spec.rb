# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../app/services/rails/generator_service'


class MockGenerator < Rails::Generators::Base
  hide!

  def initialize(*)
    super
  end

end

RSpec.describe GeneratorService do

  let(:cli_options) { {} }
  let(:debug_verbose) { false }
  let(:generator) { MockGenerator.new }
  let(:generator_name) { "GeneratorName" }

  let(:tmp_path) { "/tmp" }
  let(:fixture_path) { "./spec/fixtures" }
  let(:filename) { "samples_controller.rb" }
  let(:filename2) { "sample_twos_controller.rb" }
  let(:filename3) { "sample_threes_controller.rb" }
  let(:path_to_original_test_file) { File.join( fixture_path, "hyrax", filename ) }
  let(:path_to_original_test_file2) { File.join( fixture_path, "hyrax", filename2 ) }
  let(:path_to_original_test_file3) { File.join( fixture_path, "hyrax", filename3 ) }
  let(:path_to_non_existent_file) { File.join( fixture_path, "non-existent-fixture-file.tx" ) }
  let(:path_to_test_file) { File.join( tmp_path, filename ) }
  let(:path_to_test_file2) { File.join( tmp_path, filename2 ) }
  let(:path_to_test_file3) { File.join( tmp_path, filename3 ) }

  let(:code_class_declaration) { 'class SamplesController < ApplicationController' }
  let(:code_class_declaration2) { 'class SampleTwosController < ApplicationController' }
  let(:code_class_declaration3) { 'class SampleThreesController < ApplicationController' }
  let(:code_class_declaration_missing) { 'class SomeOtherController < ApplicationController' }

  before do
    expect( File.exist? path_to_non_existent_file ).to eq false
  end

  describe ".already_includes?" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}

    before do
      FileUtils.copy_file( path_to_original_test_file, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
    end

    it "finds existing line" do
      expect( helper.already_includes?( path_to_test_file, code_class_declaration ) ).to eq true
    end

    it "it does not find non-existent line" do
      expect( helper.already_includes?( path_to_test_file, code_class_declaration_missing ) ).to eq false
    end

    it "it does not find in non-existent file" do
      expect( helper.already_includes?( path_to_non_existent_file, code_class_declaration ) ).to eq false
    end

  end

  describe ".already_matches?" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}

    before do
      FileUtils.copy_file( path_to_original_test_file2, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
    end

    it "finds existing line" do
      expect( helper.already_matches?( path_to_test_file, /#{Regexp.escape code_class_declaration2}/ ) ).to eq true
    end

    it "finds existing lines" do
      regex = /\n\s*def show\n\s*super\n\s+end\n/m
      expect( helper.already_matches?( path_to_test_file, regex ) ).to eq true
    end

    it "it does not find non-existent line" do
      expect( helper.already_matches?( path_to_test_file, /#{Regexp.escape code_class_declaration_missing}/ ) ).to eq false
    end

    it "it does not find in non-existent file" do
      expect( helper.already_matches?( path_to_non_existent_file, /#{Regexp.escape code_class_declaration2}/ ) ).to eq false
    end

  end

  describe ".first_line_including" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}

    before do
      FileUtils.copy_file( path_to_original_test_file, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
    end

    it "finds existing line" do
      expect( helper.first_line_including( path_to_test_file,
                                                    'Sample' ) ).to eq "  #{code_class_declaration}"
    end

    it "it does not find non-existent line" do
      expect( helper.first_line_including( path_to_test_file, code_class_declaration_missing ) ).to eq nil
    end

    it "it does not find in non-existent file" do
      expect( helper.first_line_including( path_to_non_existent_file, code_class_declaration ) ).to eq nil
    end

  end

  describe ".first_line_matching" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}

    before do
      FileUtils.copy_file( path_to_original_test_file, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
    end

    it "finds existing line" do
      expect( helper.first_line_matching( path_to_test_file,
                                                   /Sample/ ) ).to eq "  #{code_class_declaration}"
    end

    it "it does not find non-existent line" do
      expect( helper.first_line_matching( path_to_test_file, /SampleTwo/ ) ).to eq nil
    end

    it "it does not find in non-existent file" do
      expect( helper.first_line_matching( path_to_non_existent_file, /SampleTwo/ ) ).to eq nil
    end

  end

  describe ".inject_after" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}
    let(:include_code) { 'include "something"' }

    before do
      FileUtils.copy_file( path_to_original_test_file, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
      FileUtils.copy_file( path_to_original_test_file2, path_to_test_file2 )
      expect( File.exist? path_to_test_file2 ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
      File.delete path_to_test_file2 if File.exist? path_to_test_file2
    end

    context 'injects after existing line' do
      let(:test_file_path) { path_to_test_file }

      before do
        expect(generator).to receive(:inject_into_file).with(any_args).and_call_original
        allow(generator).to receive(:say_status)
      end

      it 'succeeds' do
        existing_line = helper.last_line_matching( test_file_path, /include / )
        expect( helper.already_includes?( test_file_path, include_code ) ).to eq false
        expect( helper.inject_line( test_file_path, include_code, after: existing_line ) ).to eq true
        expect( helper.already_includes?( test_file_path, include_code ) ).to eq true
      end

    end

    context 'injects after existing line with regex special characters' do
      let(:test_file_path) { path_to_test_file2 }

      before do
        expect(generator).to receive(:inject_into_file).with(any_args).and_call_original
        allow(generator).to receive(:say_status)
      end

      it 'succeeds' do
        regexp_target = /\n\s*def show\n\s*super\n\s+end\n/m
        include_this = <<EOS

  def new_method
    puts
  end
EOS
        regexp_include_this = /\n\s*def new_method\n\s*puts\n\s+end\n/m
        expect( include_this =~ regexp_include_this ).to eq 0
        expect( helper.already_matches?( test_file_path, regexp_target ) ).to eq true
        expect( helper.already_matches?( test_file_path, regexp_include_this ) ).to eq false
        expect( helper.inject_lines( test_file_path, include_this, after: regexp_target ) ).to eq true
        expect( helper.matches?( test_file_path, regexp_include_this ) ).to eq true
        regexp_both = /\n\s*def show\n\s*super\n\s+end\n\n\s*def new_method\n\s*puts\n\s+end\n/m
        expect( helper.matches?( test_file_path, regexp_both ) ).to eq true
      end

    end

    context 'injects after existing lines' do
      let(:test_file_path) { path_to_test_file2 }

      before do
        expect(generator).to receive(:inject_into_file).with(any_args).and_call_original
        allow(generator).to receive(:say_status)
      end

      it 'succeeds' do
        existing_line = helper.last_line_matching( test_file_path, /include / )
        expect( helper.already_includes?( test_file_path, include_code ) ).to eq false
        expect( helper.inject_line( test_file_path, include_code, after: existing_line ) ).to eq true
        expect( helper.already_includes?( test_file_path, include_code ) ).to eq true
      end

    end

  end

  describe ".last_line_including" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}

    before do
      FileUtils.copy_file( path_to_original_test_file, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
    end

    it "finds last existing line" do
      expect( helper.last_line_including( path_to_test_file,
                                                   'Sample' ) ).to eq '    self.show_presenter = Hyrax::SamplesPresenter'
    end

    it "it does not find non-existent line" do
      expect( helper.last_line_including( path_to_test_file, code_class_declaration_missing ) ).to eq nil
    end

    it "it does not find in non-existent file" do
      expect( helper.last_line_including( path_to_non_existent_file, 'Sample' ) ).to eq nil
    end

  end

  describe ".last_line_matching" do
    let(:helper) { described_class.new(generator: generator, generator_name: generator_name, debug_verbose: debug_verbose, cli_options: cli_options )}

    before do
      FileUtils.copy_file( path_to_original_test_file, path_to_test_file )
      expect( File.exist? path_to_test_file ).to eq true
    end

    after do
      File.delete path_to_test_file if File.exist? path_to_test_file
    end

    it "finds existing line" do
      expect( helper.last_line_matching( path_to_test_file,
                                                  /Sample/ ) ).to eq '    self.show_presenter = Hyrax::SamplesPresenter'
    end

    it "it does not find non-existent line" do
      expect( helper.last_line_matching( path_to_test_file, /^class / ) ).to eq nil
    end

    it "it does not find in non-existent file" do
      expect( helper.last_line_matching( path_to_non_existent_file, /^\s+class / ) ).to eq nil
    end

  end

end
