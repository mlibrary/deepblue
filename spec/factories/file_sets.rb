# frozen_string_literal: true
# Update: hyrax4
FactoryBot.define do

  factory :file_set do
    transient do
      user         { create(:user) }
      content      { nil }
      fixture_path { './spec/fixtures' }
      file_path    { nil }
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key
    end

    after(:create) do |file, evaluator|
      Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
    end

    trait :public do
      read_groups { ["public"] }
    end

    trait :registered do
      read_groups { ["registered"] }
    end

    trait :image do
      content { File.open(Hyrax::Engine.root + 'spec/fixtures/world.png') }
    end

    trait :with_original_file do
      after(:create) do |file_set, _evaluator|
        Hydra::Works::AddFileToFileSet
          .call(file_set, File.open(Hyrax::Engine.root + 'spec/fixtures/world.png'), :original_file)
      end
    end

    factory :file_with_work do
      after(:build) do |file, _evaluator|
        file.title ||= ['testfile']
      end
      after(:create) do |file, evaluator|
        Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
        work = create( :data_set_work,
                creator: [ "Dr. Creator" ],
                rights_license: "The Rights License",
                title: ['test title'],
                user: evaluator.user )
        work.ordered_members << file
        work.save
        # work.members << file
        work
      end
    end

    factory :file_set_with_files do
      after(:create) do |file_set, evaluator|
        # puts "file_set_with_files -- after(:create) file_set=#{file_set}"
        # allow(file_set).to receive(:warn) # suppress virus warnings
        file_name = evaluator.label
        file_name ||= 'world.png'
        file_path = evaluator.file_path
        file_path ||= File.join evaluator.fixture_path, file_name
        file = File.open(file_path).tap do |file|
          file.define_singleton_method( :original_name ) { file_name }
          # file.define_singleton_method( :current_user ) { user }
        end
        # Hydra::Works::AddFileToFileSet.add_file_to_file_set_debug_verbose = true
        # ::Deepblue::LoggingHelper.echo_to_puts = true
        Hydra::Works::AddFileToFileSet.call_enhanced_version(file_set, file, :original_file)
        # ::Deepblue::LoggingHelper.echo_to_puts = false
        # Hydra::Works::AddFileToFileSet.add_file_to_file_set_debug_verbose = false
        # puts "file_set_with_files -- after(:create) last"
      end
    end

  end

end
