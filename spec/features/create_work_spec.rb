require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Creating a new Work', type: :feature, js: true, workflow: true, clean_repo: true, skip: true || ENV['CIRCLECI'].present? do

  include Devise::Test::IntegrationHelpers

  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let!(:uploaded_file1) { Hyrax::UploadedFile.create(file: file1, user: user) }
  let!(:uploaded_file2) { Hyrax::UploadedFile.create(file: file2, user: user) }
  let(:work_title) { 'My Test Work' }
  let(:edit_note) { 'Please provide information about your data set (referred to as a "work") in the following fields, keeping in mind that your responses will enable people to discover, identify, and understand your data. If you are uncertain of how to complete any of these fields, we recommend that you read or refer to the Guide to Metadata in Deep Blue Data’s Help pages.' }
  let(:add_files_note) { 'If you have more than 100 files or files larger than 5 GB please Contact Us for assistance in uploading your data.' }

  describe 'as normal user' do

    let(:user) { create(:user) }
    let!(:ability) { ::Ability.new(user) }

    before do
      # Grant the user access to deposit into an admin set.
      create(:permission_template_access,
             :deposit,
             permission_template: create(:permission_template, with_admin_set: true, with_active_workflow: true),
             agent_type: 'user',
             agent_id: user.user_key)
      allow(CharacterizeJob).to receive(:perform_later)
    end

    context "when the user is not a proxy" do
      before do
        sign_in user
        visit '/'
        # click_link 'Works'
        # click_link "Add new work"
        # click_link 'Deposit Your Work'
        # find(:xpath, "//a[contains(text(),'Deposit Your Work')]").click()
        # page.find_link( /Deposit Your Work/ ).click()
        page.find_link( 'Deposit Your Work', exact: false ).click()
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
      end

      it 'creates the work' do

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
        expect(page).to_not have_content "Add folder"
        expect(page).to_not have_content 'image.jp2'
        expect(page).to_not have_content 'jp2_fits.xml'
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

        click_link "Descriptions" # switch tab back
        page.find_link( 'Files', wait: 10 )
        # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        check('agreement')

        # These lines are for debugging, should this test fail
        # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
        # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
        # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
        click_button 'Save Work'
        expect(page).to have_content( 'Work Description', wait: 60 )
        expect(page).to_not have_link( 'Edit Work/Add Files' )

        page.title =~ /^.*ID:\s([^\s]+)\s.*$/
        id = Regexp.last_match 1

        expect(page).to have_content( work_title )
        expect(page).to have_content "Your files are being processed by Deep Blue Data in the background."
        expect(page).to_not have_link( 'Edit Work/Add Files' )
      end
    end

    context 'when the user is a proxy', perform_enqueued: [ContentDepositorChangeEventJob, AttachFilesToWorkJob, IngestJob], skip: true do
      let(:second_user) { create(:user) }

      before do
        ProxyDepositRights.create!(grantor: second_user, grantee: user)
        # sign_in user
        login_as user
        visit '/'
        page.find_link( 'Deposit Your Work', exact: false ).click()
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
      end

      # have to explore proxy deposits
      it "allows on-behalf-of deposit", skip: true do
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
        within('span#addfiles') do
          attach_file("files[]", File.join(fixture_path, 'image.jp2'), visible: false)
          attach_file("files[]", File.join(fixture_path, 'jp2_fits.xml'), visible: false)
        end

        # With selenium and the chrome driver, focus remains on the
        # select box. Click outside the box so the next line can't find
        # its element
        find('body').click
        choose('data_set_visibility_open')
        expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
        select(second_user.user_key, from: 'On behalf of')

        expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        check('agreement')

        # These lines are for debugging, should this test fail
        # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
        # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
        # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
        click_on('Save')
        expect(page).to have_content('My Test Work')
        expect(page).to have_content "Your files are being processed by Hyrax in the background."

        sign_in second_user
        click_link 'Works'
        expect(page).to have_content "My Test Work"
      end
    end

    context "when a file uploaded and then deleted", skip: true do
      before do
        login_as user
        visit '/'
        page.find_link( 'Deposit Your Work', exact: false ).click()
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
      end

      it 'updates the required file check status' do

        fill_in 'Title', with: work_title
        fill_in 'Creator', with: 'Dr. Creator'
        fill_in 'Contact Information', with: user.email
        fill_in 'Methodology', with: 'The Method.'
        fill_in 'Description', with: 'The Description.'
        fill_in 'Keyword', with: 'testing'
        choose 'data_set_rights_license_httpcreativecommonsorgpublicdomainzero10'
        select 'Arts', from: 'Discipline'

        click_link "Files" # switch to the Files tab
        expect(page).to have_content( add_files_note, wait: 10 )
        expect(page).to have_content "Add files"
        expect(page).to_not have_content 'image.jp2'
        within('span#addfiles') do
          attach_file("files[]", File.join(fixture_path, 'image.jp2'), visible: false)
        end
        expect(page).to have_content( 'image.jp2', wait: 10 )
        # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        # check('agreement')

        # in DBD, files are not required
        # page.find_link( 'Add files', exact: false )
        # expect(page).to have_css('ul li#required-files.complete', text: 'Add files')
        # expect(page).to have_css('ul li#required-files.incomplete', text: 'Add files')
        # page.find_link( 'Add files', exact: false )

        click_button 'Delete' # delete the file
        expect(page).to_not have_content( 'image.jp2', wait: 10 )

        click_link "Descriptions" # switch tab back
        page.find_link( 'Files', wait: 10 )
        # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        check('agreement')

        # These lines are for debugging, should this test fail
        # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
        # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
        # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
        click_button 'Save Work'
        expect(page).to have_content( 'Work Description', wait: 60 )
        expect(page).to_not have_link( 'Edit Work/Add Files' )

        page.title =~ /^.*ID:\s([^\s]+)\s.*$/
        id = Regexp.last_match 1

        expect(page).to have_content( work_title )
        expect(page).to have_content "Your files are being processed by Deep Blue Data in the background."
        expect(page).to_not have_link( 'Edit Work/Add Files' )
      end
    end

  end

  describe 'as admin user', skip: true do

    let(:user) { create(:admin) }
    let!(:ability) { ::Ability.new(user) }

    before do
      # Grant the user access to deposit into an admin set.
      create(:permission_template_access,
             :deposit,
             permission_template: create(:permission_template, with_admin_set: true, with_active_workflow: true),
             agent_type: 'user',
             agent_id: user.user_key)
      # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
      allow(CharacterizeJob).to receive(:perform_later)
    end

    context "normal create work" do
      before do
        sign_in user
        visit '/'
        # click_link 'Works'
        # click_link "Add new work"
        # click_link 'Deposit Your Work'
        # find(:xpath, "//a[contains(text(),'Deposit Your Work')]").click()
        # page.find_link( /Deposit Your Work/ ).click()
        page.find_link( 'Deposit Your Work', exact: false ).click()
        page.find_link( 'Description', wait: 10 )
        expect(page).to have_content edit_note
        within('div#savewidget') do
          expect(page).to have_checked_field('data_set_visibility_open')
          expect(page).to have_field('data_set_visibility_embargo')
          expect(page).to_not have_checked_field('data_set_visibility_embargo')
          expect(page).to have_field('data_set_visibility_authenticated')
          expect(page).to have_field('data_set_visibility_lease')
          expect(page).to have_field('data_set_visibility_restricted')
        end
      end

      it 'creates the work' do

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
        expect(page).to_not have_content "Add folder"
        expect(page).to_not have_content 'image.jp2'
        expect(page).to_not have_content 'jp2_fits.xml'
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

        click_link "Descriptions" # switch tab back
        page.find_link( 'Files', wait: 10 )
        # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        check('agreement')

        # These lines are for debugging, should this test fail
        # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
        # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
        # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
        click_button 'Save Work'
        expect(page).to have_content( 'Work Description', wait: 60 )

        expect(page).to have_content( work_title )
        expect(page).to have_content( 'Dr. Creator')

        expect(page).to have_link( 'Review and Approval', wait: 10 )
        expect(page).to have_link( 'Edit Work/Add Files' )
        expect(page).to have_link( 'Delete Work' )
        # this is not enabled in test
        # expect(page).to have_link( 'Mint DOI' )

        expect(page).to have_link( 'View Work Analytics' )
        # this is not enabled in test
        # expect(page).to have_link( 'Subscribe to Monthly Analytics Report' )

        expect(page).to have_link( 'Append Files' )
        expect(page).to have_link( 'Feature' )
        # this is not enabled in test?
        # expect(page).to have_link( 'Tombstone' )

        # this is not enabled in test
        # expect(page).to have_link( 'Create Download Single-Use Link' )
        # expect(page).to have_link( 'Create View Single-Use Link' )

        page.title =~ /^.*ID:\s([^\s]+)\s.*$/
        id = Regexp.last_match 1

        expect(page).to have_content( work_title )
        expect(page).to have_content "Your files are being processed by Deep Blue Data in the background."
      end
    end

    context "when a file uploaded and then deleted", skip: true do
      before do
        login_as user
        visit '/'
        page.find_link( 'Deposit Your Work', exact: false ).click()
        page.find_link( 'Description', wait: 10 )
        expect(page).to have_content edit_note
        within('div#savewidget') do
          expect(page).to have_checked_field('data_set_visibility_open')
          expect(page).to have_field('data_set_visibility_embargo')
          expect(page).to_not have_checked_field('data_set_visibility_embargo')
          expect(page).to have_field('data_set_visibility_authenticated')
          expect(page).to have_field('data_set_visibility_lease')
          expect(page).to have_field('data_set_visibility_restricted')
        end
      end

      it 'updates the required file check status' do
        click_link "Files" # switch to the Files tab
        expect(page).to have_content( add_files_note, wait: 10 )
        expect(page).to have_content "Add files"
        expect(page).to_not have_content 'image.jp2'
        within('span#addfiles') do
          attach_file("files[]", File.join(fixture_path, 'image.jp2'), visible: false)
        end
        expect(page).to have_content( 'image.jp2', wait: 10 )
        # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        # check('agreement')

        # in DBD, files are not required
        # page.find_link( 'Add files', exact: false )
        # expect(page).to have_css('ul li#required-files.complete', text: 'Add files')
        # expect(page).to have_css('ul li#required-files.incomplete', text: 'Add files')
        # page.find_link( 'Add files', exact: false )

        click_button 'Delete' # delete the file
        expect(page).to_not have_content( 'image.jp2', wait: 10 )
        click_link "Descriptions" # switch tab back
        page.find_link( 'Files', wait: 10 )
        # expect(page).to have_content 'I have read and agree to the Deposit Agreement'
        check('agreement')

        # These lines are for debugging, should this test fail
        # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
        # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
        # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
        click_button 'Save Work'
        expect(page).to have_content( 'Work Description', wait: 60 )
        expect(page).to have_link( 'Edit Work/Add Files' )

        page.title =~ /^.*ID:\s([^\s]+)\s.*$/
        id = Regexp.last_match 1

        expect(page).to have_content( work_title )
        expect(page).to have_content "Your files are being processed by Deep Blue Data in the background."
        expect(page).to have_link( 'Edit Work/Add Files' )
      end
    end

  end

end
