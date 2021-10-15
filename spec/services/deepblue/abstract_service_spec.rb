require 'rails_helper'

class MockService < ::Deepblue::AbstractService

  def initialize( rake_task: false, options: {} )
    super( rake_task: rake_task, options: options )
  end

end

RSpec.describe ::Deepblue::AbstractService do

  describe 'constants' do
    it do
      expect( ::Deepblue::AbstractService::DEFAULT_QUIET ).to eq false
      expect( ::Deepblue::AbstractService::DEFAULT_TO_CONSOLE ).to eq false
      expect( ::Deepblue::AbstractService::DEFAULT_VERBOSE ).to eq false
    end
  end

  describe 'new' do
    let( :default_logger )        { Rails.logger }
    let( :default_options_error ) { nil }
    let( :default_quiet )         { ::Deepblue::AbstractService::DEFAULT_QUIET }
    let( :default_rake_task )     { false }
    let( :default_subscription_service_id ) { nil }
    let( :default_to_console )    { ::Deepblue::AbstractService::DEFAULT_TO_CONSOLE }
    let( :default_verbose )       { ::Deepblue::AbstractService::DEFAULT_VERBOSE }
    let( :error )                 { "an error" }
    let( :service )               { MockService.allocate }
    let( :subscription_service_id ) { "subscriptionServiceID" }

    context 'empty initialzer' do
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize)
        expect(service).to_not have_received(:console_puts)
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq default_quiet
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq default_to_console
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'rake task, empty options' do
      let(:service) { MockService.allocate }
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, rake_task: true )
        expect(service).to_not have_received(:console_puts)
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq default_quiet
        expect(service.rake_task).to     eq true
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq default_to_console
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options :error' do
      let( :error_msg ) { "WARNING: options error #{error}" }
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: { error: error } )
        expect(service).to have_received(:console_puts).with( error_msg )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq error
        expect(service.quiet).to         eq default_quiet
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq default_to_console
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options "error"' do
      let( :error_msg ) { "WARNING: options error #{error}" }
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: { "error" => error } )
        expect(service).to have_received(:console_puts).with( error_msg )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq error
        expect(service.quiet).to         eq default_quiet
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq default_to_console
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options unparsable string' do
      # let( :error_msg ) { "WARNING: options error 859: unexpected token at 'garbage'" }
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: "garbage" )
        # expect(service).to have_received(:console_puts).with( error_msg )
        expect(service).to have_received(:console_puts)  do |args|
          expect( args ).to match /WARNING: options error 8\d\d: unexpected token at 'garbage'/
        end
        expect(service.logger).to        eq default_logger
        expect(service.options_error.message).to match /8\d\d: unexpected token at 'garbage'/
        expect(service.quiet).to         eq default_quiet
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq default_to_console
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options quiet' do
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: { "quiet" => true } )
        expect(service).to_not have_received(:console_puts)
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq true
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq false
        expect(service.verbose).to       eq false
      end
    end

    context 'with options quiet as string' do
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: ActiveSupport::JSON.encode( { "quiet" => true } ) )
        expect(service).to_not have_received(:console_puts)
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq true
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq false
        expect(service.verbose).to       eq false
      end
    end

    context 'with options quiet and verbose true' do
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: { "quiet" => true, "verbose" => true } )
        expect(service).to_not have_received(:console_puts)
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq true
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq false
        expect(service.verbose).to       eq false
      end
    end

    context 'with verbose true' do
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: { "verbose" => true } )
        expect(service).to have_received(:console_puts).with("@verbose=true")
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq false
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.to_console).to    eq false
        expect(service.verbose).to       eq true
      end
    end

    context 'with the rest of known options' do
      it 'has default values' do
        allow(service).to receive(:console_puts)
        service.send(:initialize, options: { "verbose" => true, "subscription_service_id" => subscription_service_id } )
        expect(service).to have_received(:console_puts).with("set key subscription_service_id to #{subscription_service_id}")
        expect(service).to have_received(:console_puts).with("@verbose=true")
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq false
        expect(service.rake_task).to     eq default_rake_task
        expect(service.subscription_service_id).to eq subscription_service_id
        expect(service.to_console).to    eq false
        expect(service.verbose).to       eq true
      end
    end

  end

end
