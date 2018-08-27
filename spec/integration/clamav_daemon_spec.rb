# frozen_string_literal: true

require 'umich_clamav_daemon_scanner'

RSpec.describe UMichClamAVDaemonScanner do

  let(:clamd_running) { !!/\S/.match(`pgrep clamd`) }

  let(:basic_av_connection) { described_class.new(__FILE__) }

  it "can scan a harmless file" do
    skip("ClamAV Daemon not running") unless basic_av_connection.alive?
    scanner = described_class.new(__FILE__)
    expect(scanner.scan_response).to be_a(ClamAV::SuccessResponse)
  end

  it "reports an error on a bad file (directory in this case)" do
    skip("ClamAV Daemon not running") unless basic_av_connection.alive?
    scanner = described_class.new(__dir__)
    expect(scanner.scan_response).to be_a(ClamAV::ErrorResponse)
  end

  it "errors out if the file doesn't exist" do
    skip("ClamAV Daemon not running") unless basic_av_connection.alive?
    scanner = described_class.new('asdfadsfasdfasdfasdf')
    expect { scanner.infected? }.to raise_error(RuntimeError, /Can't open file/)
  end

end
