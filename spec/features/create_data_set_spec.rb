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

  let(:wait_after_click)  { 30 }
  let(:wait_after_save)   { 60 }
  let(:wait_after_upload) { 20 }

  # TODO: changes in javascript have led to forced filling in of non-required fields (well, they're required if other
  # fields are filled, i.e. 'other' values)
  context 'a logged in user', skip: true do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end
    let(:ability) { ::Ability.new(user) }
    let(:permission_template) { create(:permission_template, with_admin_set: true, with_active_workflow: true) }

    let(:work_title) { 'My Test Work Data Set' }
    let(:edit_note) { 'Please provide information about your data set (referred to as a "work") in the following fields, keeping in mind that your responses will enable people to discover, identify, and understand your data. If you are uncertain of how to complete any of these fields, we recommend that you read or refer to the Guide to Metadata in Deep Blue Data’s Help pages.' }
    let(:add_files_note) { 'If you have more than 100 files or files larger than 5 GB please Contact Us for assistance in uploading your data.' }

    before do
      allow(Hyrax.config).to receive(:browse_everything?).and_return(false) # still broken without browse everything
      expect(permission_template).to_not eq nil
      create(:permission_template_access,
             :deposit,
             permission_template: permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      login_as user
      allow(IngestJob).to receive(:perform_later)
      allow(IngestJob).to receive(:perform_now)
    end

    scenario do
      visit '/dashboard'
      click_link( "Works", wait: wait_after_click )
      expect(page).to have_content "Add new work" # if this fails, the admin set may be missing
      click_link( "Add new work", wait: wait_after_click )

      page.find_link( 'Description', wait: wait_after_click )
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

      click_link "Add Files" # switch tab
      expect(page).to have_content( add_files_note, wait: wait_after_click )
      expect(page).to have_content "Add files"
      # not in DBD:
      expect(page).to_not have_content "Add folder"
      within('span#addfiles') do
        attach_file("files[]", File.join(fixture_path, 'image.jp2'), visible: false)
        attach_file("files[]", File.join(fixture_path, 'jp2_fits.xml'), visible: false)
      end
      # TODO: why did this stop working?
      # expect(page).to have_content( 'image.jp2', wait: wait_after_upload )
      # expect(page).to have_content 'jp2_fits.xml'

      # # With selenium and the chrome driver, focus remains on the
      # # select box. Click outside the box so the next line can't find
      # # its element
      # find('body').click
      # This is the default value for DBD
      # choose('data_set_visibility_open')

      click_link( "Descriptions", wait: wait_after_click) # switch tab
      page.find_link( 'Add Files', wait: wait_after_click )

      # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
      check('agreement', wait: wait_after_click)

      click_button( 'Save Work', wait: wait_after_save )
      expect(page).to have_content( 'Work Description', wait: wait_after_save )

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
