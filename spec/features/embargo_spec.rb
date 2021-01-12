require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'embargo', :clean_repo do

  EMBARGO_SPEC_DEBUG_VERBOSE = false

  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    sign_in user
  end
  describe 'creating an embargoed object' do
    let(:work_title) { "Embargo test" }
    let(:future_date) { 5.days.from_now }
    let(:later_future_date) { 10.days.from_now }

    it 'can be created, displayed, but not updated', :clean_repo, :workflow do
      visit '/concern/data_sets/new'
      # puts "\npage.title=#{page.title}\n"
      # sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE
      fill_in 'Title', with: work_title
      fill_in 'Creator', with: 'Dr. Creator'
      fill_in 'Contact Information', with: user.email
      fill_in 'Methodology', with: 'The Method.'
      fill_in 'Description', with: 'The Description.'
      fill_in 'Keyword', with: 'testing'
      choose 'data_set_rights_license_httpcreativecommonsorgpublicdomainzero10'
      # The following two fields are marked as required, but javascript manages whether they really are or not
      # fill_in 'Other License', with: 'dummy, managed by javascript'
      # fill_in 'Enter other funding agency title', with: 'dummy, managed by javascript'
      select 'Arts', from: 'Discipline'
      choose 'Embargo'
      fill_in 'data_set_embargo_release_date', with: future_date.to_datetime.strftime("%m/%d/%Y")
      # DBD automatically does the following two things:
      # select 'Private', from: 'Restricted to'
      # select 'Public', from: 'then open it up to'
      check 'agreement'
      click_button 'Save Work'
      # puts "\npage.title=#{page.title}\n"

      page.title =~ /^.*ID:\s([^\s]+)\s.*$/
      id = Regexp.last_match 1

      sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE

      # chosen embargo date is on the show page
      expect(page).to have_content('Embargo release date')
      # puts "\nlater_future_date.to_date.to_datetime.strftime(\"%m/%d/%Y\")=#{later_future_date.to_datetime.strftime("%m/%d/%Y")}\n"
      expect(page).to have_content(future_date.to_datetime.strftime("%m/%d/%Y"))
      sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE

      # NOTE: normal depositors don't have edit access to works after adding them due to moderated deposit
      visit "/embargoes/#{id}/edit"

      # all this until I realized the user in question doesn't have rights to edit after create
      # review_links = page.all('a[href^="/concern/data_sets"]')
      # review_links = page.all('a[href^="/"]')
      # puts "\n"
      # puts "review_links.size=#{review_links.size}"
      # puts "review_links.map(&:text)=#{review_links.map(&:text)}"
      # puts "\n"
      #
      # expect(page).to have_link(href: /data_sets.*\/edit/)
      # page.find_link(href: /data_sets.*\/edit/)
      #
      # # find(:xpath, "//input[contains(@name, 'Edit Work')]").click()
      # # find(:xpath, "//input[contains(@text, 'Edit Work')]").click()
      # # find(:xpath, "//button[contains(text(),'Edit Work')]").click()
      # # find(:xpath, "//a[contains(text(),'Edit Work')]").click()
      # # page.find_link( /^Edit Work/ ).click()
      # # page.find( 'a', text: /^Edit Work/).click()
      #
      # # click_button 'Edit Work/Add Files'
      # # click_link 'Edit Work/Add Files'
      # click_link 'Embargo Management Page'
      #
      # puts "\npage.title=#{page.title}\n"

      expect(page).to have_content("Manage Embargoes for #{work_title} (Work)")
      expect(page).to have_xpath("//input[@name='data_set[embargo_release_date]' and @value='#{future_date.to_datetime.strftime("%Y-%m-%d")}']")

      fill_in 'data_set_embargo_release_date', with: later_future_date.to_datetime.strftime("%m/%d/%Y")
      sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE

      click_button 'Update Embargo'
      sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE
      # puts "\npage.title=#{page.title}\n"
      expect(page).to have_content("You do not have sufficient privileges for this")
      # expect(page).to have_content("Embargo release date")
      # expect(page).to have_content(later_future_date.to_datetime.strftime("%m/%d/%Y"))
    end
  end

  describe 'updating embargoed object' do
    let(:my_admin_set) do
      create(:admin_set,
             title: ['admin set with embargo range'],
             with_permission_template: { release_period: "6mos", with_active_workflow: true })
    end
    let(:default_admin_set) do
      create(:admin_set, id: AdminSet::DEFAULT_ID,
                         title: ["Default Admin Set"],
                         description: ["A description"],
                         with_permission_template: {})
    end
    let(:future_date) { 5.days.from_now }
    let(:later_future_date) { 10.days.from_now }
    let(:invalid_future_date) { 185.days.from_now } # More than 6 months
    let(:admin) { create(:admin) }
    let(:work) do
      create(:work, title: ['embargoed work1'],
                    embargo_release_date: future_date.to_datetime.iso8601,
                    admin_set_id: my_admin_set.id,
                    edit_users: [user])
    end

    it 'can be updated with a valid date' do
      visit "/concern/data_sets/#{work.id}"
      # sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('Manage Embargoes for embargoed work1 (Work)')
      # puts "\nfuture_date.to_datetime.strftime(\"%Y-%m-%d\")=#{future_date.to_datetime.strftime("%Y-%m-%d")}\n"
      # expect(page).to have_xpath("//input[@name='data_set[embargo_release_date]'") # current embargo date is pre-populated in edit field
      expect(page).to have_xpath("//input[@name='data_set[embargo_release_date]' and @value='#{future_date.to_datetime.strftime("%Y-%m-%d")}']") # current embargo date is pre-populated in edit field

      fill_in 'data_set_embargo_release_date', with: later_future_date.to_datetime.strftime("%m/%d/%Y")

      click_button 'Update Embargo'
      expect(page).to have_content("Embargo release date")
      expect(page).to have_content(later_future_date.to_date.to_formatted_s(:standard))
      # expect(page).to have_content(my_admin_set.title.first)
    end

    it 'cannot be updated with an invalid date' do
      visit "/concern/data_sets/#{work.id}"
      # sleep 30 if EMBARGO_SPEC_DEBUG_VERBOSE

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('Manage Embargoes for embargoed work1 (Work)')
      expect(page).to have_xpath("//input[@name='data_set[embargo_release_date]' and @value='#{future_date.to_datetime.strftime("%Y-%m-%d")}']") # current embargo date is pre-populated in edit field

      fill_in 'data_set_embargo_release_date', with: invalid_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content('Release date specified does not match permission template release requirements for selected AdminSet.')
    end
  end
end
