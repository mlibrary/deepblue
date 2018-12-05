# frozen_string_literal: true

RSpec.configure do |config|
  config.filter_run_excluding globus_enabled: :true unless DeepBlueDocs::Application.config.globus_enabled
end

describe GlobusJob, "GlobusJob globus_enabled: :true", globus_enabled: :true do # rubocop:disable RSpec/DescribeMethod

  let( :globus_dir ) { Pathname.new "/tmp/deepbluedata-globus" }
  let( :globus_download_dir ) { globus_dir.join 'download' }
  let( :globus_prep_dir ) { globus_dir.join 'prep' }
  let( :globus_target_download_dir ) { globus_download_dir.join 'DeepBlueData_id321' }
  let( :globus_target_prep_dir ) { globus_prep_dir.join "#{GlobusJob.server_prefix(str: '_')}DeepBlueData_id321" }
  let( :globus_target_prep_tmp_dir ) { globus_prep_dir.join "#{GlobusJob.server_prefix(str: '_')}DeepBlueData_id321" }
  let( :error_file ) { globus_prep_dir.join '.test.error.DeepBlueData_id321' }
  let( :lock_file ) { globus_prep_dir.join '.test.lock.DeepBlueData_id321' }

  describe "GlobusJob#copy_complete?" do
    context "directory exists in download dir" do
      before do
        allow( Dir ).to receive( :exist? ).with( globus_target_download_dir ).and_return( true )
      end
      it "returns true." do expect( GlobusJob.copy_complete?( "id321" ) ).to eq( true ); end
    end
  end

  describe "GlobusJob#external_url" do
    it "returns a globus external url." do
      url = GlobusJob.external_url "id321"
      expect( url ).to eq( "https://app.globus.org/file-manager?origin_id=99d8c648-a9ff-11e7-aedd-22000a92523b&origin_path=%2Fdownload%2FDeepBlueData_id321%2F" )
    end
  end

  describe "GlobusJob#files_prepping?" do
    context "directory exists in prep dir" do
      before do
        allow( Dir ).to receive( :exist? ).with( globus_target_download_dir ).and_return( false )
        allow( File ).to receive( :exist? ).with( error_file ).and_return( false )
        allow( GlobusJob ).to receive( :locked? ).with( "id321" ).and_return( true )
      end
      it "returns true." do expect( GlobusJob.files_prepping?( "id321" ) ).to eq( true ); end
    end
  end

  describe "GlobusJob#locked?" do
    context "lock file does not exist" do
      before do
        allow( File ).to receive( :exist? ).with( error_file ).and_return( false )
        allow( File ).to receive( :exist? ).with( lock_file ).and_return( false )
      end
      it "returns true." do expect( GlobusJob.locked?( "id321" ) ).to eq( false ); end
    end
    ## see context "#globus_locked?" for more tests
  end

  describe "GlobusJob#files_target_file_name" do
    it "returns target file name." do
      url = GlobusJob.files_target_file_name "id321"
      expect( url ).to eq( "DeepBlueData_id321" )
    end
  end

  describe "GlobusJob#globus_lock_file" do
    it "returns the lock file name." do
      expect( GlobusJob.lock_file("id321" ) ).to eq(lock_file )
    end
  end

  describe "GlobusJob#target_base_name" do
    it "returns a target base name." do
      expect( GlobusJob.target_base_name( "id321" ) ).to eq( "DeepBlueData_id321" )
    end
  end

  describe "GlobusJob#target_file_name" do
    it "returns a target base name." do
      expect( GlobusJob.target_file_name( Pathname.new( 'aDir' ), "aFile" ) ).to eq( Pathname.new( 'aDir' ).join( 'aFile' ) )
    end
  end

  describe "GlobusJob#target_file_name_env" do
    let( :file ) { Pathname.new( 'aDir' ).join( '.test.atype.basename' ) }
    it "returns a target base name." do
      expect( GlobusJob.target_file_name_env( Pathname.new( 'aDir' ), "atype", "basename" ) ).to eq( file )
    end
  end

  describe "#globus_acquire_lock?" do
    let( :job ) do
      j = described_class.new
      j.perform( "id321" )
      j
    end
    context "when globus is locked" do
      before do
        allow( job ).to receive( :globus_locked? ).and_return( true )
      end
      it "returns false." do
        expect( job.send( :globus_acquire_lock? ) ).to eq( false )
      end
    end
    context "when globus is not locked" do
      before do
        allow( job ).to receive( :globus_locked? ).and_return( false )
        allow( job ).to receive( :globus_lock ).and_return( true )
      end
      it "returns true." do
        expect( job.send( :globus_acquire_lock? ) ).to eq( true )
      end
    end
  end

  describe "#globus_copy_job_complete?" do
    let( :job ) do
      j = described_class.new
      j.perform( "abc" )
      j
    end
    before do
      allow( Dir ).to receive( :exist? ).with( globus_target_download_dir ).and_return( true )
    end
    it "returns true." do expect( job.send( :globus_copy_job_complete?, "id321" ) ).to eq( true ); end
  end

  describe "#globus_error_file" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    it "returns the error file name." do
      expect( job.send( :globus_error_file ) ).to eq( error_file )
    end
  end

  describe "#globus_error" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    let( :error_file_tmp ) { Tempfile.new( ".test.error.DeepBlueData_id321", globus_dir ) }
    let( :error_msg ) { "An error message." }
    before do
      allow( job ).to receive( :globus_error_file ).and_return( error_file_tmp.path )
      open( error_file_tmp.path, 'w' ) { |f| f << error_msg << "\n" }
      msg = "Globus:  writing error message to #{error_file_tmp.path}"
      allow( Rails.logger ).to receive( :debug ).with( msg )
    end
    after do
      error_file_tmp.delete
    end
    it "writes out the error" do
      expect( job.send( :globus_error, error_msg ) ).to eq( error_file_tmp.path )
      file_contents = nil
      open( error_file_tmp.path, 'r' ) { |f| file_contents = f.read.chomp! }
      expect( file_contents ).to eq( error_msg )
    end
  end

  context "#globus_error_file_exists?" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    context "error file exists" do
      before do
        allow( File ).to receive( :exist? ).with( error_file ).and_return( true )
      end
      it "returns true if error file exists." do
        expect( job.send( :globus_error_file_exists? ) ).to eq( true )
      end
    end
    context "error file exists and write to log flag is true" do
      let( :job2 ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      let( :error_file_tmp ) { Tempfile.new( ".test.error.DeepBlueData_id321", globus_dir ) }
      let( :error_msg ) { "An error message." }
      before do
        allow( job2 ).to receive( :globus_error_file ).and_return( error_file_tmp.path )
        allow( GlobusJob ).to receive( :error_file ).and_return( error_file_tmp.path )
        open( error_file_tmp.path, 'w' ) { |f| f << error_msg << "\n" }
        allow( Rails.logger ).to receive( :debug ).with( "Globus:  error file contains: #{error_msg}" )
      end
      after do
        error_file_tmp.delete
      end
      it "writes to the log when error file exists" do
        expect( job2.send( :globus_error_file_exists?, write_error_to_log: true ) ).to eq( true )
      end
    end
    context "error file does not exist" do
      before do
        allow( File ).to receive( :exist? ).with( error_file ).and_return( false )
      end
      it "returns true if error file exists." do
        expect( job.send( :globus_error_file_exists? ) ).to eq( false )
      end
    end
  end

  describe "#globus_error_reset" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    context "when error file exists." do
      before do
        allow( File ).to receive( :exist? ).with( error_file ).and_return( true )
        allow( File ).to receive( :delete ).with( error_file )
      end
      it "return true when file exists." do
        expect( job.send( :globus_error_reset ) ).to eq( true )
      end
    end
    context "when error file doesn't exist." do
      before do
        allow( File ).to receive( :exist? ).with( error_file ).and_return( false )
      end
      it "return true when file doesn't exist." do
        expect( File ).not_to receive( :delete )
        expect( job.send( :globus_error_reset ) ).to eq( true )
      end
    end
  end

  context "#globus_job_complete" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    let( :complete_file_tmp ) { Tempfile.new( ".test.complete.DeepBlueData_id321", globus_dir ) }
    before do
      job.define_singleton_method( :globus_job_complete_file ) do "let the expect define the return value"; end
      allow( job ).to receive( :globus_job_complete_file ).and_return( complete_file_tmp.path )
      # log_msg = "Globus:  job complete at #{timestamp}"
      allow( Rails.logger ).to receive( :debug )
    end
    after do
      complete_file_tmp.delete
    end
    it "writes out the globus complete file." do
      before = Time.now.round(0) - 1.second
      expect( job.send( :globus_job_perform_complete ) ).to eq(complete_file_tmp.path )
      after = Time.now.round(0) + 1.second
      file_contents = nil
      open( complete_file_tmp.path, 'r' ) { |f| file_contents = f.read.chomp! }
      between = Time.parse file_contents
      expect( between ).to be_between( before, after )
    end
  end

  describe "#globus_job_perform" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    let( :globus_block ) { -> { job.inside_block } }
    let( :lock_file_msg ) { "Globus:  lock file #{lock_file}" }
    before do
      job.define_singleton_method( :globus_job_complete? ) do true; end
      job.define_singleton_method( :inside_block ) do true; end
    end

    context "when job complete" do
      before do
        allow( job ).to receive( :globus_job_complete? ).and_return( true )
        allow( Rails.logger ).to receive( :debug ).with( "Globus:  skipping already complete globus job" )
      end
      it "does not call globus block" do
        expect( GlobusJob.class_variable_get( :@@globus_enabled ) ).to eq( true )
        expect( job ).not_to receive( :globus_acquire_lock? )
        expect( job ).not_to receive( :inside_block )
        job.send( :globus_job_perform, concern_id: "id321", &globus_block )
      end
    end
    context "when can't acquire lock" do
      before do
        allow( job ).to receive( :globus_job_complete? ).and_return( false )
        allow( job ).to receive( :globus_acquire_lock? ).and_return( false )
        allow( job ).to receive( :globus_job_perform_in_progress )
        allow( Rails.logger ).to receive( :debug ).with( lock_file_msg )
      end
      it "does not call globus block." do
        expect( GlobusJob.class_variable_get( :@@globus_enabled ) ).to eq( true )
        expect( job ).not_to receive( :inside_block )
        job.send( :globus_job_perform, concern_id: "id321", &globus_block )
      end
    end
    context "when can acquire lock" do
      before do
        allow( job ).to receive( :globus_job_complete? ).and_return( false )
        allow( job ).to receive( :globus_acquire_lock? ).and_return( true )
        allow( Rails.logger ).to receive( :debug ).with( lock_file_msg )
        allow( job ).to receive( :globus_error_reset )
        allow( job ).to receive( :globus_job_perform_complete_reset )
        allow( job ).to receive( :inside_block )
        allow( job ).to receive( :globus_job_perform_complete )
        allow( job ).to receive( :globus_unlock )
      end
      it "calls globus block." do
        expect( GlobusJob.class_variable_get( :@@globus_enabled ) ).to eq( true )
        job.send( :globus_job_perform, concern_id: "id321", &globus_block )
        expect( job ).to have_received( :globus_unlock ).exactly( 2 ).times
      end
    end
    context "when can acquire lock and error is thrown inside block," do
      before do
        allow( job ).to receive( :globus_job_complete? ).and_return( false )
        allow( job ).to receive( :globus_acquire_lock? ).and_return( true )
        allow( Rails.logger ).to receive( :debug ).with( lock_file_msg )
        allow( job ).to receive( :globus_error_reset )
        allow( job ).to receive( :globus_job_perform_complete_reset )
        allow( job ).to receive( :inside_block ).and_raise( StandardError, "generated error" )
        allow( Rails.logger ).to receive( :error )
        allow( job ).to receive( :globus_error ).with( /^Globus:  StandardError: generated error at/ )
        allow( job ).to receive( :globus_unlock )
      end
      it "calls globus block." do
        expect( GlobusJob.class_variable_get( :@@globus_enabled ) ).to eq( true )
        expect( job ).not_to receive( :globus_job_perform_complete )
        job.send( :globus_job_perform, concern_id: "id321", &globus_block )
        expect( Rails.logger ).to have_received( :error ).with( /^Globus:  StandardError: generated error at/ )
      end
    end
  end

  describe "#globus_job_complete_reset" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    let( :complete_file ) { "#{globus_dir}/prep/.test.complete.DeepBlueData_id321" }
    context "when complete file exists." do
      before do
        job.define_singleton_method( :globus_job_complete_file ) do "let the expect define the return value"; end
        allow( job ).to receive( :globus_job_complete_file ).and_return( complete_file )
        allow( File ).to receive( :exist? ).with( complete_file ).and_return( true )
        allow( File ).to receive( :delete ).with( complete_file )
      end
      it "return true when file exists." do
        expect( job.send( :globus_job_perform_complete_reset ) ).to eq(true )
      end
    end
    context "when complete file doesn't exist." do
      before do
        job.define_singleton_method( :globus_job_complete_file ) do "let the expect define the return value"; end
        allow( job ).to receive( :globus_job_complete_file ).and_return( complete_file )
        allow( File ).to receive( :exist? ).with( complete_file ).and_return( false )
      end
      it "return true when file doesn't exist." do
        expect( File ).not_to receive( :delete )
        expect( job.send( :globus_job_perform_complete_reset ) ).to eq(true )
      end
    end
  end

  context "#globus_lock" do
    let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
    let( :lock_file_tmp ) { Tempfile.new( ".test.lock.DeepBlueData_id321", globus_dir ) }
    let( :current_token ) { GlobusJob.era_token }
    before do
      allow( GlobusJob ).to receive( :lock_file ).and_return( lock_file_tmp.path )
      log_msg = "Globus:  writing lock token #{current_token} to #{lock_file_tmp.path}"
      allow( Rails.logger ).to receive( :debug ).with( log_msg )
    end
    after do
      lock_file_tmp.delete
    end
    it "creates a lock file with the current token in it." do
      expect( job.send( :globus_lock ) ).to eq( true )
      file_lock_token = nil
      open( lock_file_tmp.path, 'r' ) { |f| file_lock_token = f.read.chomp! }
      expect( file_lock_token ).to eq( current_token )
    end
  end

  context "#globus_locked?" do
    context "If error file exists" do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      before do
        allow( GlobusJob ).to receive( :error_file_exists? ).and_return( true )
      end
      it "then return false if error file exists." do
        expect( job.send( :globus_locked? ) ).to eq( false )
      end
    end
    context "If lock file does not exist" do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      before do
        allow( GlobusJob ).to receive( :error_file_exists? ).and_return( false )
        allow( File ).to receive( :exist? ).with( lock_file ).and_return( false )
      end
      it "then return false." do
        expect( job.send( :globus_locked? ) ).to eq( false )
      end
    end
    context "lock file exists with different token." do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      let( :lock_file_tmp ) { Tempfile.new( ".test.lock.DeepBlueData_id321", globus_dir ) }
      let( :current_token ) { GlobusJob.era_token }
      let( :lock_token ) { "theToken" }
      before do
        allow( GlobusJob ).to receive( :error_file_exists? ).and_return( false )
        allow( GlobusJob ).to receive( :lock_file ).and_return( lock_file_tmp.path )
        open( lock_file_tmp.path, 'w' ) { |f| f << lock_token << "\n" }
        log_msg = "Globus:  testing token from #{lock_file_tmp.path}: current_token: #{current_token} == lock_token: #{lock_token}: false"
        allow( Rails.logger ).to receive( :debug ).with( log_msg )
      end
      after do
        lock_file_tmp.delete
      end
      it "then returns false when tokens are not equal." do
        expect( job.send( :globus_locked? ) ).to eq( false )
      end
    end
    context "lock file exists with same token." do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      let( :lock_file_tmp ) { Tempfile.new( ".test.lock.DeepBlueData_id321", globus_dir ) }
      let( :current_token ) { GlobusJob.era_token }
      let( :lock_token ) { GlobusJob.era_token }
      before do
        allow( GlobusJob ).to receive( :error_file_exists? ).and_return( false )
        allow( GlobusJob ).to receive( :lock_file ).and_return(lock_file_tmp.path )
        open( lock_file_tmp.path, 'w' ) { |f| f << lock_token << "\n" }
        log_msg = "Globus:  testing token from #{lock_file_tmp.path}: current_token: #{current_token} == lock_token: #{lock_token}: true"
        allow( Rails.logger ).to receive( :debug ).with( log_msg )
      end
      after do
        lock_file_tmp.delete
      end
      it "then returns true when tokens are equal." do
        expect( job.send( :globus_locked? ) ).to eq( true )
      end
    end
  end

  context "#globus_unlock" do
    context "when globus lock file is nil" do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      before do
        job.define_singleton_method( :set_globus_lock_file_nil ) do @globus_lock_file = nil; end
        job.set_globus_lock_file_nil
      end
      it "then return nil" do
        expect( job.send( :globus_unlock ) ).to eq( nil )
      end
    end
    context "when globus lock file does not exist" do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      before do
        allow( File ).to receive( :exist? ).with( lock_file ).and_return( false )
      end
      it "then return nil" do
        expect( File ).not_to receive( :delete )
        expect( job.send( :globus_unlock ) ).to eq( nil )
      end
    end
    context "when globus lock file exists" do
      let( :job ) { j = described_class.new; j.perform( "id321" ); j } # rubocop:disable Style/Semicolon
      before do
        allow( File ).to receive( :exist? ).with( lock_file ).and_return( true )
        allow( File ).to receive( :delete ).with( lock_file )
        log_msg = "Globus:  unlock by deleting file #{lock_file}"
        allow( Rails.logger ).to receive( :debug ).with( log_msg )
      end
      it "then return nil" do
        expect( job.send( :globus_unlock ) ).to eq( nil )
      end
    end
  end

  context "#target_dir_name" do
    let( :job ) { described_class.new }
    let( :dir ) { Pathname.new( 'aDir' ).join( 'aSubdir' ) }
    context "don't create dir." do
      it "returns a target base name." do
        expect( job.send(:target_dir_name2, Pathname.new('aDir' ), "aSubdir" ) ).to eq(dir )
      end
    end
    context "create dir if it doesn't exist." do
      before do
        allow( Dir ).to receive( :exist? ).with( dir ).and_return( false )
        allow( Dir ).to receive( :mkdir ).with( dir )
      end
      it "returns a target base name and creates the dir." do
        expect( job.send(:target_dir_name2, Pathname.new('aDir' ), "aSubdir", mkdir: true ) ).to eq(dir )
      end
    end
    context "don't create dir if it exists." do
      before do
        allow( Dir ).to receive( :exist? ).with( dir ).and_return( true )
      end
      it "returns a target base name and doesn't create the dir." do
        expect( job.send(:target_dir_name2, Pathname.new('aDir' ), "aSubdir", mkdir: false ) ).to eq(dir )
      end
    end
  end

  describe "#target_download_dir" do
    let( :job ) { described_class.new }
    it "returns target dowload dir name." do
      expect( job.send(:target_download_dir2, "id321" ) ).to eq(globus_target_download_dir )
    end
  end

  context "#target_prep_dir" do
    let( :job ) { described_class.new }
    let( :prefix ) { GlobusJob.server_prefix(str: '_') }
    let( :dir ) { globus_prep_dir.join "#{prefix}DeepBlueData_id321" }
    context "don't create prep dir." do
      it "returns a prep dir name." do
        expect( job.send(:target_prep_dir2, "id321", prefix: prefix ) ).to eq(dir )
      end
    end
    context "create prep dir if it doesn't exist." do
      before do
        allow( Dir ).to receive( :exist? ).with( dir ).and_return( false )
        allow( Dir ).to receive( :mkdir ).with( dir )
      end
      it "returns prep dir name and creates the dir." do
        expect( job.send(:target_prep_dir2, "id321", prefix: prefix, mkdir: true ) ).to eq(dir )
      end
    end
    context "don't create prep dir if it exists." do
      it "returns prep dir name name and doesn't create the dir." do
        expect( job.send(:target_prep_dir2, "id321", prefix: prefix, mkdir: false ) ).to eq(dir )
      end
    end
  end

  context "#target_prep_dir_tmp" do
    let( :job ) { described_class.new }
    let( :prefix ) { GlobusJob.server_prefix(str: '_') }
    let( :dir ) { globus_prep_dir.join "#{prefix}DeepBlueData_id321_tmp" }
    context "don't create tmp prep dir." do
      it "returns tmp prep dir name." do
        expect( job.send(:target_prep_tmp_dir2, "id321", prefix: prefix ) ).to eq(dir )
      end
    end
    context "create tmp prep dir if it doesn't exist." do
      before do
        allow( Dir ).to receive( :exist? ).with( dir ).and_return( false )
        allow( Dir ).to receive( :mkdir ).with( dir )
      end
      it "returns tmp prep dir name and creates the dir." do
        expect( job.send(:target_prep_tmp_dir2, "id321", prefix: prefix, mkdir: true ) ).to eq(dir )
      end
    end
    context "don't create tmp prep dir if it exists." do
      it "returns tmp prep dir name name and doesn't create the dir." do
        expect( job.send(:target_prep_tmp_dir2, "id321", prefix: prefix, mkdir: false ) ).to eq(dir )
      end
    end
  end

end
