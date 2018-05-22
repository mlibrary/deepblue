require 'rails_helper'
include Warden::Test::Helpers

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.feature 'Create a DataSet', js: true do

  # before(:all ) do
  #   puts "DataSet ids before=#{DataSet.all.map { |ds| ds.id }}"
  #   #puts "FileSet ids before=#{FileSet.all.map { |fs| fs.id }}"
  # end
  #
  # after(:all ) do
  #   #puts "FileSet ids after=#{FileSet.all.map { |fs| fs.id }}"
  #   puts "DataSet ids after=#{DataSet.all.map { |ds| ds.id }}"
  #   # clean up created DataSet
  #   DataSet.all.each { |ds| ds.delete }
  #   #FileSet.all.each { |fs| fs.delete }
  # end

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
    end

    scenario do
      # visit '/dashboard'
      # click_link "Works"
      # expect(page).to have_content "Add new work"
      # click_link "Add new work"
      #
      # # If you generate more than one work uncomment these lines
      # choose "payload_concern", option: "DataSet"
      # click_button "Create work"
      # sleep 2 # seems to make this work
      # expect(page).to have_content "Add New Data Set"
      # click_link "Files" # switch tab
      # expect(page).to have_content "Add files"
      # expect(page).to have_content "Add folder"
      # within('span#addfiles') do
      #   attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      #   attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
      # end
      # click_link "Descriptions" # switch tab
      # fill_in('Title', with: 'My Test Work')
      # fill_in('Creator', with: 'Doe, Jane')
      # fill_in('Authoremail', with: 'test@test.com' )
      # fill_in('Keyword', with: 'testing')
      # fill_in('Abstract or Summary', with: 'This is the description.' )
      # select('In Copyright', from: 'Rights statement')
      #
      # # With selenium and the chrome driver, focus remains on the
      # # select box. Click outside the box so the next line can't find
      # # its element
      # find('body').click
      # choose('data_set_visibility_open')
      # expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      #
      # # the upload of files fails with:
      # # 2018-05-04 12:02:27 -0400: Rack app error handling request { POST /uploads/ }
      # # #<ActiveRecord::StatementInvalid: SQLite3::BusyException: database is locked: INSERT INTO "uploaded_files" ("file", "user_id", "created_at", "updated_at") VALUES (?, ?, ?, ?)>
      # # check('agreement')
      # # click_on('Save')
      # # expect(page).to have_content('My Test Work')
      # # expect(page).to have_content "Your files are being processed by Hyrax in the background."
    end
  end

end
