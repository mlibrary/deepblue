require 'rails_helper'

class MockService < ::Deepblue::AbstractService

  def initialize( msg_handler:, options: {} )
    super( msg_handler: msg_handler, options: options )
  end

end

RSpec.describe ::Deepblue::AbstractService do

  describe 'constants' do
    # it { expect( ::Deepblue::AbstractService::DEFAULT_QUIET ).to eq false }
    # it { expect( ::Deepblue::AbstractService::DEFAULT_TO_CONSOLE ).to eq false }
    # it { expect( ::Deepblue::AbstractService::DEFAULT_VERBOSE ).to eq false }
  end

  describe 'new' do
    let( :default_logger )        { Rails.logger }
    let( :default_options_error ) { nil }
    let( :default_quiet )         { ::Deepblue::MessageHandler::DEFAULT_QUIET }
    let( :default_subscription_service_id ) { nil }
    let( :default_to_console )    { false }
    let( :default_verbose )       { ::Deepblue::MessageHandler::DEFAULT_VERBOSE }
    let( :error )                 { "an error" }
    let( :service )               { MockService.allocate }
    let(:subscription_service_id) { "subscriptionServiceID" }

    context 'empty initializer' do
      let( :msg_handler ) { ::Deepblue::MessageHandler.new }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_debug)
        expect(msg_handler).to_not receive(:msg_error)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        # allow(msg_handler).to receive(:msg)
        service.send(:initialize, msg_handler: msg_handler)
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq default_quiet
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'rake task, empty options' do
      let( :msg_handler ) { ::Deepblue::MessageHandler.msg_handler_for( task: true ) }
      let(:service) { MockService.allocate }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_debug)
        expect(msg_handler).to_not receive(:msg_error)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq default_quiet
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options :error' do
      let( :msg_handler )           { ::Deepblue::MessageHandler.new }
      # let( :error_msg ) { "WARNING: options error #{error}" }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_debug)
        expect(msg_handler).to_not receive(:msg_error)
        expect(msg_handler).to_not receive(:msg_verbose)
        # expect(msg_handler).to_not receive(:msg_warn)
        expect(msg_handler).to receive(:msg_warn).with ("options error an error")
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler, options: { error: error } )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq error
        expect(service.quiet).to         eq default_quiet
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options "error"' do
      let( :msg_handler )           { ::Deepblue::MessageHandler.new }
      # let( :error_msg ) { "WARNING: options error #{error}" }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_debug)
        expect(msg_handler).to_not receive(:msg_error)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to receive(:msg_warn).with("options error an error")
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler, options: { "error" => error } )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq error
        expect(service.quiet).to         eq default_quiet
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options unparsable string' do
      let( :msg_handler )           { ::Deepblue::MessageHandler.new }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg_debug)
        expect(msg_handler).to_not receive(:msg_error)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to receive(:msg_warn).with("options error unexpected token at 'garbage'")
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler, options: "garbage" )
        expect(service.logger).to        eq default_logger
        expect(service.options_error.message).to match /unexpected token at 'garbage'/
        expect(service.quiet).to         eq default_quiet
        expect(service.verbose).to       eq default_verbose
      end
    end

    context 'with options quiet' do
      let( :msg_handler )           { ::Deepblue::MessageHandler.new }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_error)
        #expect(msg_handler).to receive(:msg_debug).with("set key quiet to true")
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler, options: { "quiet" => true } )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq true
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq false
      end
    end

    context 'with options quiet as string' do
      let( :msg_handler )           { ::Deepblue::MessageHandler.new }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_error)
        #expect(msg_handler).to receive(:msg_verbose).with("set key quiet to true")
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        service.send(:initialize,
                     msg_handler: msg_handler,
                     options: ActiveSupport::JSON.encode( { "quiet" => true } ) )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq true
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq false
      end
    end

    context 'with options quiet and verbose true' do
      let( :msg_handler ) { ::Deepblue::MessageHandler.new }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_error)
        #expect(msg_handler).to receive(:msg_debug).with("set key quiet to true")
        #expect(msg_handler).to receive(:msg_debug).with("set key verbose to true")
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler, options: { "quiet" => true, "verbose" => true } )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq true
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq false
      end
    end

    context 'with verbose true' do
      let( :msg_handler ) { ::Deepblue::MessageHandler.new( verbose: true ) }
      before do
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_error)
        expect(msg_handler).to receive(:msg_debug).with("set key verbose to true")
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        service.send(:initialize, msg_handler: msg_handler, options: { "verbose" => true } )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq false
        expect(service.subscription_service_id).to eq default_subscription_service_id
        expect(service.verbose).to       eq true
      end
    end

    context 'with the rest of known options' do
      let( :msg_handler ) { ::Deepblue::MessageHandler.new }
      before do
        # expect(msg_handler).to receive(:msg).with("set key subscription_service_id to #{subscription_service_id}")
        expect(msg_handler).to_not receive(:buffer)
        expect(msg_handler).to_not receive(:msg)
        expect(msg_handler).to_not receive(:msg_verbose)
        expect(msg_handler).to_not receive(:msg_error)
        # expect(msg_handler).to_not receive(:msg_verbose)
        #expect(msg_handler).to receive(:msg_debug).with("set key verbose to true")
        #expect(msg_handler).to receive(:msg_verbose).with("set key subscription_service_id to subscriptionServiceID")
        expect(msg_handler).to_not receive(:msg_warn)
      end
      it 'has default values' do
        service.send(:initialize,
                     msg_handler: msg_handler,
                     options: { "verbose" => true, "subscription_service_id" => subscription_service_id } )
        expect(service.logger).to        eq default_logger
        expect(service.options_error).to eq default_options_error
        expect(service.quiet).to         eq false
        expect(service.subscription_service_id).to eq subscription_service_id
        expect(service.verbose).to       eq true
      end
    end

  end

end
