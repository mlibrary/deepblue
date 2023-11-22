# frozen_string_literal: true

require 'rails_helper'

require_relative '../../app/tasks/deepblue/task_pacifier'

RSpec.describe ::Deepblue::TaskPacifier do
  let( :out ) { double("out") }
  let( :count_nl_default ) { 100 }
  let( :pacify_default ) { '.' }
  let( :pacify_str ) { 'pacify this' }
  let( :pacify_longer_than_count_nl ) { '.' * ( count_nl_default + 1 ) }
  let( :bracket_open_default ) { '(' }
  let( :bracket_close_default ) { ')' }

  context "default newline count" do
    let( :pacifier ) { described_class.new( out: out ) }

    before do
      # initial state
      expect(pacifier.active).to eq true
      expect(pacifier.active?).to eq true
      expect(pacifier.count).to eq 0
      expect(pacifier.count_nl).to eq 100
      expect(pacifier.out).to eq out
    end

    it ".active?" do
      expect(pacifier.active?).to eq true
    end

    describe ".nl" do

      it "with no prior prints" do
        expect(out).to receive(:print).with("\n")
        expect(out).to receive(:flush).with(no_args)
        pacifier.nl
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 0
      end

      it "with prior prints" do
        expect(out).to receive(:print).with("\n")
        expect(out).to receive(:flush).with(no_args)
        pacifier.nl
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 0
      end

    end

    describe ".pacify" do

      it "default" do
        expect(out).to receive(:print).with('.')
        expect(out).to receive(:flush)
        pacifier.pacify
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 1

        expect(out).to receive(:print).with('.')
        expect(out).to receive(:flush)
        pacifier.pacify
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 2
      end

      it "with string" do
        expect(out).to receive(:print).with(pacify_str)
        expect(out).to receive(:flush).with(no_args)
        pacifier.pacify pacify_str
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq pacify_str.size
      end

      it "with string longer than count_nl" do
        expect(out).to receive(:print).with(pacify_longer_than_count_nl)
        expect(out).to receive(:print).with("\n")
        expect(out).to receive(:flush).with(no_args).twice
        pacifier.pacify pacify_longer_than_count_nl
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 0
      end

    end

    describe ".pacify_bracket" do
      let( :default_bracket_str ) { "#{bracket_open_default}#{pacify_str}#{bracket_close_default}" }
      let( :square_bracket_str ) { "[#{pacify_str}]" }

      it "default brackets" do
        expect(out).to receive(:print).with(default_bracket_str)
        expect(out).to receive(:flush).with(no_args)
        pacifier.pacify_bracket pacify_str
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq default_bracket_str.size
      end

      it "with square brackets" do
        expect(out).to receive(:print).with(square_bracket_str)
        expect(out).to receive(:flush).with(no_args)
        pacifier.pacify_bracket( pacify_str, bracket_open: '[', bracket_close: ']' )
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq square_bracket_str.size
      end

    end

    describe ".reset" do

      it "with no prior prints" do
        pacifier.reset
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 0
      end

      it "with prior prints" do
        pacifier.reset
        expect(pacifier.active?).to eq true
        expect(pacifier.count).to eq 0
      end

    end

  end

end
