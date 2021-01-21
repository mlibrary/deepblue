require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a DataSet', type: :feature, js: true, workflow: true, clean_repo: true, skip: ENV['CIRCLECI'].present? do

  before(:all ) do
    # puts "DataSet ids before=#{DataSet.all.map { |ds| ds.id }}"
    #puts "FileSet ids before=#{FileSet.all.map { |fs| fs.id }}"
  end

  after(:all ) do
    #puts "FileSet ids after=#{FileSet.all.map { |fs| fs.id }}"
    # puts "DataSet ids after=#{DataSet.all.map { |ds| ds.id }}"
    # clean up created DataSet
    DataSet.all.each { |ds| ds.delete }
    #FileSet.all.each { |fs| fs.delete }
  end

  context 'a logged in user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let(:workflow) { Sipity::Workflow.create!(active: true, name: 'test-workflow', permission_template: permission_template) }
    let(:work_title) { 'My Test Work Data Set' }
    let(:edit_note) { 'Please provide information about your data set (referred to as a "work") in the following fields, keeping in mind that your responses will enable people to discover, identify, and understand your data. If you are uncertain of how to complete any of these fields, we recommend that you read or refer to the Guide to Metadata in Deep Blue Data’s Help pages.' }
    let(:add_files_note) { 'If you have more than 100 files or files larger than 5 GB please Contact Us for assistance in uploading your data.' }

    before do
      # Create a single action that can be taken
      Sipity::WorkflowAction.create!(name: 'submit', workflow: workflow)

      # Grant the user access to deposit into the admin set.
      Hyrax::PermissionTemplateAccess.create!(
        permission_template_id: permission_template.id,
        agent_type: 'user',
        agent_id: user.user_key,
        access: 'deposit'
      )
      login_as user
      allow(CharacterizeJob).to receive(:perform_later)
    end

    scenario do
      visit '/dashboard'
      click_link "Works"
      expect(page).to have_content "Add new work"
      click_link "Add new work"

      page.find_link( 'Description', wait: 10 )
      expect(page).to have_content edit_note
      within('div#savewidget') do
        expect(page).to have_checked_field('data_set_visibility_open')
        expect(page).to have_field('data_set_visibility_embargo')
        expect(page).to_not have_checked_field('data_set_visibility_embargo')
        expect(page).to_not have_field('data_set_visibility_authenticated')
        expect(page).to_not have_field('data_set_visibility_lease')
        expect(page).to_not have_field('data_set_visibility_restricted')
      end

      fill_in 'Title', with: work_title
      fill_in 'Creator', with: 'Dr. Creator'
      fill_in 'Contact Information', with: user.email
      fill_in 'Methodology', with: 'The Method.'
      fill_in 'Description', with: 'The Description.'
      fill_in 'Keyword', with: 'testing'
      choose 'data_set_rights_license_httpcreativecommonsorgpublicdomainzero10'
      select 'Arts', from: 'Discipline'

      click_link "Files" # switch tab
      expect(page).to have_content( add_files_note, wait: 10 )
      expect(page).to have_content "Add files"
      # not in DBD:
      # expect(page).to have_content "Add folder"
      within('span#addfiles') do
        attach_file("files[]", File.join(fixture_path, 'image.jp2'), visible: false)
        attach_file("files[]", File.join(fixture_path, 'jp2_fits.xml'), visible: false)
      end
      expect(page).to have_content( 'image.jp2', wait: 10 )
      expect(page).to have_content 'jp2_fits.xml'

      # # With selenium and the chrome driver, focus remains on the
      # # select box. Click outside the box so the next line can't find
      # # its element
      # find('body').click
      # This is the default value for DBD
      # choose('data_set_visibility_open')

      click_link "Descriptions" # switch tab
      page.find_link( 'Files', wait: 10 )

      # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
      check('agreement')

      click_button 'Save Work'
      expect(page).to have_content( 'Work Description', wait: 60 )

      expect(page).to have_content( work_title )
      expect(page).to have_content( 'Dr. Creator')

      expect(page).to have_link( 'Review and Approval', wait: 10 )
      expect(page).to_not have_link( 'Edit Work/Add Files' )
      expect(page).to_not have_link( 'Delete Work' )
      # this is not enabled in test
      # expect(page).to_not have_link( 'Mint DOI' )

      expect(page).to have_link( 'View Work Analytics' )
      # this is not enabled in test
      # expect(page).to have_link( 'Subscribe to Monthly Analytics Report' )

      expect(page).to_not have_link( 'Append Files' )
      expect(page).to_not have_link( 'Feature' )
      # this is not enabled in test?
      # expect(page).to_not have_link( 'Tombstone' )

      # this is not enabled in test
      # expect(page).to have_link( 'Create Download Single-Use Link' )
      # expect(page).to have_link( 'Create View Single-Use Link' )

      page.title =~ /^.*ID:\s([^\s]+)\s.*$/
      id = Regexp.last_match 1

      expect(page).to have_content( work_title )
      expect(page).to have_content "Your files are being processed by Deep Blue Data in the background."
    end
  end

end
