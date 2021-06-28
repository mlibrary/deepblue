# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::DiskUtilitiesHelper do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.disk_utilities_helper_debug_verbose ).to eq( false )
    end
  end


  describe '.delete_dir' do

    context 'nonexistent directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:nonexistent_dir) { File.join( base_dir, 'missing_dir') }
      before do
        expect( Dir.exist? base_dir ).to eq true
        expect( Dir.exist? nonexistent_dir ).to eq false
      end
      after { Dir.delete base_dir if Dir.exist? base_dir }
      it 'returns 0' do
        expect( described_class.delete_dir nonexistent_dir ).to eq 0
      end
    end

    context 'not a directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:not_a_dir) { File.join( base_dir, 'file' ) }
      before do
        expect( Dir.exist? base_dir ).to eq true
        FileUtils.touch not_a_dir
        expect( File.exist? not_a_dir ).to eq true
      end
      after do
        File.delete not_a_dir if File.exist? not_a_dir
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns 0' do
        expect( described_class.delete_dir not_a_dir ).to eq 0
      end
    end

    context 'existing but empty directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      before { expect( Dir.exist? base_dir ).to eq true }
      after { Dir.delete base_dir if Dir.exist? base_dir }
      it 'returns an empty array' do
        expect( described_class.delete_dir base_dir ).to eq 1
      end
    end

    context 'existing directory with files' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'deletes the files and directory' do
        expect( described_class.delete_dir( base_dir ) ).to eq 1
        expect( Dir.exist? base_dir ).to eq false
      end
    end

    context 'existing directory with only subdirs' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        subdirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        expect( described_class.delete_dir( base_dir ) ).to eq 0
        subdirs.each { |dir| expect( Dir.exist? dir ).to eq true }
        expect( described_class.delete_dir( base_dir, recursive: true ) ).to eq 3
        subdirs.each { |dir| expect( Dir.exist? dir ).to eq false }
        expect( Dir.exist? base_dir ).to eq false
      end
    end

    context 'existing directory with files and subdirs' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        subdirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        files = filenames.map { |filename| File.join( base_dir, filename ) }.sort
        expect( described_class.delete_dir( base_dir ) ).to eq 0
        subdirs.each { |dir| expect( Dir.exist? dir ).to eq true }
        files.each { |file| expect( File.exist? file ).to eq false }
      end
    end

    context 'existing directory with files and subdirs recursive' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        subdirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        files = filenames.map { |filename| File.join( base_dir, filename ) }.sort
        expect( described_class.delete_dir( base_dir, recursive: true ) ).to eq 3
        subdirs.each { |dir| expect( Dir.exist? dir ).to eq false }
        files.each { |file| expect( File.exist? file ).to eq false }
      end
    end

  end


  describe '.delete_file', skip: false do

    context 'an existing file' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      before { expect( File.exist? file1 ).to eq true }
      after { File.delete file1 if File.exist? file1 }
      it 'deletes it' do
        expect( File ).to receive( :file? ).with( file1 ).and_call_original
        expect( File ).to receive( :delete ).with( file1 ).and_call_original
        expect( described_class.delete_file file1 ).to eq 1
        expect( File.exist? file1 ).to eq false
      end
    end

    context 'an existing dir' do
      let(:dir1) { File.absolute_path Dir.mktmpdir( 'dir1' ) }
      before { expect( Dir.exist? dir1 ).to eq true }
      after { Dir.delete dir1 if Dir.exist? dir1 }
      it 'does not deletes it' do
        expect( described_class.delete_file dir1 ).to eq 0
        expect( Dir.exist? dir1 ).to eq true
      end
    end

    context 'a non-existent file' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      before do
        expect( File.exist? file1 ).to eq true
        expect( File.delete file1 ).to eq 1
      end
      after { File.delete file1 if File.exist? file1 }
      it 'returns 0' do
        expect( File ).to receive( :file? ).with( file1 ).and_call_original
        expect( File ).to_not receive( :delete ).with( file1 ).and_call_original
        expect( File.exist? file1 ).to eq false
        expect( described_class.delete_file file1 ).to eq 0
      end
    end

  end

  describe '.delete_files' do

    context 'empty array' do
      let(:files) { [] }
      it 'it returns 0' do
        expect( described_class.delete_files files ).to eq 0
      end
    end

    context 'nil' do
      let(:files) { nil }
      it 'it returns 0' do
        expect( described_class.delete_files files ).to eq 0
      end
    end

    context 'one file' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:files) { file1 }
      before { expect( File.exist? file1 ).to eq true }
      after { File.delete file1 if File.exist? file1 }
      it 'deletes it' do
        expect( described_class ).to receive( :delete_file ).with( file1 ).and_call_original
        expect( described_class.delete_files files ).to eq 1
      end
    end

    context 'one file as array' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:files) { [file1] }
      before { expect( File.exist? file1 ).to eq true }
      after { File.delete file1 if File.exist? file1 }
      it 'deletes it' do
        expect( described_class ).to receive( :delete_file ).with( file1 ).and_call_original
        expect( described_class.delete_files *files ).to eq 1
      end
    end

    context 'two files' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:file2) { File.absolute_path Tempfile.new( 'file2' ) }
      before do
        expect( File.exist? file1 ).to eq true
        expect( File.exist? file2 ).to eq true
      end
      after do
        File.delete file1 if File.exist? file1
        File.delete file2 if File.exist? file2
      end
      it 'deletes them' do
        expect( described_class ).to receive( :delete_file ).with( file1 ).and_call_original
        expect( described_class ).to receive( :delete_file ).with( file2 ).and_call_original
        expect( described_class.delete_files file1, file2 ).to eq 2
      end
    end

    context 'two files as array' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:file2) { File.absolute_path Tempfile.new( 'file2' ) }
      let(:files) { [file1, file2] }
      before do
        expect( File.exist? file1 ).to eq true
        expect( File.exist? file2 ).to eq true
      end
      after do
        File.delete file1 if File.exist? file1
        File.delete file2 if File.exist? file2
      end
      it 'deletes them' do
        expect( described_class ).to receive( :delete_file ).with( file1 ).and_call_original
        expect( described_class ).to receive( :delete_file ).with( file2 ).and_call_original
        expect( described_class.delete_files *files ).to eq 2
      end
    end

  end

  describe '.delete_files_older_than' do

    context 'one file older than 0 days' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      before { expect( File.exist? file1 ).to eq true }
      after { File.delete file1 if File.exist? file1 }
      it 'deletes it' do
        expect( described_class ).to receive( :delete_files ).with( file1 ).and_call_original
        expect( described_class.delete_files_older_than( file1, days_old: 0 ) ).to eq 1
      end
    end

    context 'two files' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:file2) { File.absolute_path Tempfile.new( 'file2' ) }
      before do
        expect( File.exist? file1 ).to eq true
        expect( File.exist? file2 ).to eq true
      end
      after do
        File.delete file1 if File.exist? file1
        File.delete file2 if File.exist? file2
      end
      it 'deletes them' do
        expect( described_class.delete_files_older_than( file1, file2, days_old: 0 ) ).to eq 2
      end
    end

    context 'does not delete file older than 1 day' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:files) { file1 }
      before { expect( File.exist? file1 ).to eq true }
      after { File.delete file1 if File.exist? file1 }
      it 'deletes it' do
        expect( described_class.delete_files_older_than( files, days_old: 1 ) ).to eq 0
      end
    end

    context 'does not delete twos file older than 1 day' do
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:file2) { File.absolute_path Tempfile.new( 'file2' ) }
      before do
        expect( File.exist? file1 ).to eq true
        expect( File.exist? file2 ).to eq true
      end
      after do
        File.delete file1 if File.exist? file1
        File.delete file2 if File.exist? file2
      end
      it 'deletes them' do
        expect( described_class.delete_files_older_than( file1, file2, days_old: 1 ) ).to eq 0
      end
    end

    context 'does not delete one of two files older than 1 day' do
      let(:days_old) { 2 }
      let(:file1) { File.absolute_path Tempfile.new( 'file1' ) }
      let(:file2) { File.absolute_path Tempfile.new( 'file2' ) }
      before do
        expect( File.exist? file1 ).to eq true
        expect( File.exist? file2 ).to eq true
        mod_time = Time.new - days_old.days
        File.utime( mod_time, mod_time, file2 )
      end
      after do
        File.delete file1 if File.exist? file1
        File.delete file2 if File.exist? file2
      end
      it 'deletes only one of them' do
        expect( described_class.delete_files_older_than( file1, file2, days_old: days_old - 1 ) ).to eq 1
        expect( File.exist? file1 ).to eq true
        expect( File.exist? file2 ).to eq false
      end
    end

  end
  describe '.dirs_in_dir' do

    context 'nonexistent directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:nonexistent_dir) { File.join( base_dir, 'missing_dir') }
      before do
        expect( Dir.exist? base_dir ).to eq true
        expect( Dir.exist? nonexistent_dir ).to eq false
      end
      after { Dir.delete base_dir if Dir.exist? base_dir }
      it 'returns an empty array' do
        expect( described_class.dirs_in_dir nonexistent_dir ).to eq []
      end
    end

    context 'existing directory but empty directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      before { expect( Dir.exist? base_dir ).to eq true }
      after { Dir.delete base_dir if Dir.exist? base_dir }
      it 'returns an empty array' do
        expect( described_class.dirs_in_dir base_dir ).to eq []
      end
    end

    context 'existing directory with files' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        expect( described_class.dirs_in_dir( base_dir ).sort ).to eq []
      end
    end

    context 'existing directory with only subdirs' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        expected_dirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        expect( described_class.dirs_in_dir( base_dir ).sort ).to eq expected_dirs
      end
    end

    context 'existing directory with files and subdirs' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        expected_dirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        expected_files = filenames.map { |filename| File.join( base_dir, filename ) }.sort
        expect( described_class.dirs_in_dir( base_dir ).sort ).to eq expected_dirs
      end
    end

  end

  describe '.files_in_dir' do

    context 'nonexistent directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:nonexistent_dir) { File.join( base_dir, 'missing_dir') }
      before do
        expect( Dir.exist? base_dir ).to eq true
        expect( Dir.exist? nonexistent_dir ).to eq false
      end
      after { Dir.delete base_dir if Dir.exist? base_dir }
      it 'returns an empty array' do
        expect( described_class.files_in_dir nonexistent_dir ).to eq []
      end
    end

    context 'existing directory but empty directory' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      before { expect( Dir.exist? base_dir ).to eq true }
      after { Dir.delete base_dir if Dir.exist? base_dir }
      it 'returns an empty array' do
        expect( described_class.files_in_dir base_dir ).to eq []
      end
    end

    context 'existing directory with files' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        expected_files = filenames.map { |filename| File.join( base_dir, filename ) }.sort
        expect( described_class.files_in_dir( base_dir ).sort ).to eq expected_files
        expect( described_class.files_in_dir( base_dir, include_dirs: false ).sort ).to eq expected_files
        expect( described_class.files_in_dir( base_dir, include_dirs: true ).sort ).to eq expected_files
      end
    end

    context 'existing directory with only subdirs' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        expect( described_class.files_in_dir( base_dir ).sort ).to eq []
        expect( described_class.files_in_dir( base_dir, include_dirs: false ).sort ).to eq []
        expected_dirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        expect( described_class.files_in_dir( base_dir, include_dirs: true ).sort ).to eq expected_dirs
      end
    end

    context 'existing directory with files and subdirs' do
      let(:base_dir) { File.absolute_path Dir.mktmpdir( 'basedir' ) }
      let(:dirnames) { %w[ dir1 dir2 ] }
      let(:filenames) { %w[ file1 file2 ] }
      before do
        expect( Dir.exist? base_dir ).to eq true
        dirnames.each { |dirname| Dir.mkdir( File.join( base_dir, dirname ) ) }
        filenames.each { |filename| FileUtils.touch( File.join( base_dir, filename ) ) }
      end
      after do
        dirnames.each do |dirname|
          dir = File.join( base_dir, dirname )
          Dir.delete dir if Dir.exist? dir
        end
        filenames.each do |filename|
          file = File.join( base_dir, filename )
          File.delete file if File.exist? file
        end
        Dir.delete base_dir if Dir.exist? base_dir
      end
      it 'returns correct arrays' do
        expected_dirs = dirnames.map { |dirname| File.join( base_dir, dirname ) }.sort
        expected_files = filenames.map { |filename| File.join( base_dir, filename ) }.sort
        expected_all = expected_dirs + expected_files
        expected_all.sort
        expect( described_class.files_in_dir( base_dir ).sort ).to eq expected_files
        expect( described_class.files_in_dir( base_dir, include_dirs: false ).sort ).to eq expected_files
        expect( described_class.files_in_dir( base_dir, include_dirs: true ).sort ).to eq expected_all
      end
    end

  end

  describe '.tmp_derivatives_path' do
    it 'has the right value' do
      expect(described_class.tmp_derivatives_path).to eq File.join Rails.root, 'tmp/derivatives'
    end
  end

end
