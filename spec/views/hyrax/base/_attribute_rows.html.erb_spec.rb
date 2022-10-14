# frozen_string_literal: true

require 'rails_helper'

require_relative '../../../../app/presenters/hyrax/data_set_presenter'

RSpec.describe 'hyrax/base/_attribute_rows.html.erb', type: :view do

  let(:main_app) { Rails.application.routes.url_helpers }

  let(:title)                 { 'The Work Title' }
  let(:curation_notes_admin)  { 'A curation note for the admin.' }
  let(:curation_notes_admins) { [curation_notes_admin, 'The second curation note for the admin.'] }
  let(:prior_identifier)      { 'priorID' }

  describe 'users' do
    let(:ability)            { double('ability') }
    let(:authoremail)        { 'authoremail@umich.edu' }
    let(:creator)            { 'Creator, A' }
    let(:creators)           { [creator, 'Another, B'] }
    let(:curation_notes_user)  { 'A curation note for the user.' }
    let(:curation_notes_users) { [curation_notes_user, 'The second curation note for the user.'] }
    let(:date_created)       { ['2018-02-28'] }
    let(:depositor)          { authoremail }
    let(:description)        { 'The Description' }
    let(:descriptions)       { [description, 'Part 2 of the description.'] }
    let(:fundedby)           { 'Funded By Big U' }
    let(:fundedbys)          { [fundedby, 'Funded By Corp'] }
    let(:methodology)        { 'The Methodology' }
    let(:methodologies)      { [methodology, 'The Methodology Part 2'] }
    let(:resource_type)      { 'Dataset' }
    let(:rights_license)     { 'http://creativecommons.org/publicdomain/zero/1.0/' }
    let(:subject_discipline) { 'The Subject Discipline' }
    let(:user)               { create(:user) }
    let(:current_user)       { user.user_key }
    let(:visibility_private) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let(:visibility_public)  { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

    context 'display various fields' do
      let(:work) do
        DataSet.new( title:            [title],
                     authoremail:      authoremail,
                     creator:          [creator],
                     curation_notes_admin: [curation_notes_admin],
                     curation_notes_user: [curation_notes_user],
                     date_created:     date_created,
                     depositor:        depositor,
                     description:      [description],
                     fundedby:         [fundedby],
                     methodology:      [methodology],
                     prior_identifier: [prior_identifier],
                     rights_license:   rights_license,
                     subject_discipline: [subject_discipline],
                     visibility:       visibility_public )
      end
      let(:solr_document) { SolrDocument.new(work.to_solr) }
      let(:data_set_controller) { Hyrax::DataSetsController.new }
      let(:presenter) do
        Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
          p.controller = data_set_controller
        end
      end
      let(:rendered)      { render 'hyrax/base/attribute_rows', presenter: presenter }
      let(:page)          { Capybara::Node::Simple.new(rendered) }

      before do
        allow(data_set_controller).to receive(:curation_concern).and_return work
        allow(ability).to receive(:admin?).and_return false
        assign( :presenter, presenter )
      end

      it { expect(page).to have_css(%(span[itemprop="url"][class="hide"]), text: work.data_set_url ) }
      # it { expect(page.find(css: %(span[itemprop="url"][class="hide"]).present?)).to eq true }

      it { expect(page).to have_content authoremail }
      it { expect(page).to have_link authoremail }
      it { expect(page).to have_css(%(li[class="attribute attribute-authoremail"] a[href="mailto:#{authoremail}"]),
                                    text: authoremail ) }
      it { expect(page).to have_link(creator) }
      it { expect(page).to have_content curation_notes_user }
      it { expect(page).to have_selector '.attribute-curation_note_user' }
      it { expect(page).to have_content description }
      it { expect(page).to have_css('li[class="attribute attribute-description"] span[itemprop="description"] span[class="more"]'),
                           text: description }
      it { expect(page).to have_content depositor }
      it { expect(page).to have_selector '.attribute-depositor' }
      it { expect(page).to have_content fundedby }
      it { expect(page).to have_selector '.attribute-fundedby' }
      it { expect(page).to have_content methodology }
      it { expect(page).to have_selector '.attribute-methodology' }
      it { expect(page).to have_css('li[class="attribute attribute-methodology"] span[itemprop="methodology"] span[class="more"]') }
      it { expect(page).to have_content resource_type }
      it { expect(page).to have_link resource_type }
      it { expect(page).to have_selector '.attribute-resource_type' }
      it { expect(page).to have_selector '.attribute-rights_license' }
      it { expect(page).to have_link(rights_license, href: rights_license) }
      it { expect(page).to have_content subject_discipline }
      it { expect(page).to have_selector '.attribute-subject_discipline' }

      # title doesn't show up as metadata attribute
      # it 'title' do
      #   expect(page).to have_content title
      #   expect(page).to have_selector '.work_description_title'
      # end

      # not have admin only content
      it { expect(page).to_not have_selector '.attribute-curation_note_admin' }
      it { expect(page).to_not have_content prior_identifier }
      it { expect(page).to_not have_selector '.attribute-prior_identifier' }
      it { expect(page).to_not have_selector '.attribute-read_users' }
      it { expect(page).to_not have_selector '.attribute-edit_users' }
      it { expect(page).to_not have_selector '.attribute-read_groups' }
      it { expect(page).to_not have_selector '.attribute-edit_groups' }

      # not have any of the secondary attributes
      it { expect(page).to_not have_selector '.attribute-description_abstract' }
      it { expect(page).to_not have_selector '.attribute-identifier_orcid' }
      it { expect(page).to_not have_selector '.attribute-academic_affiliation' }
      it { expect(page).to_not have_selector '.attribute-ther_affiliation' }
      it { expect(page).to_not have_selector '.attribute-contributor_affiliationumcampus' }
      it { expect(page).to_not have_selector '.attribute-alt_title' }
      it { expect(page).to_not have_selector '.attribute-date_issued' }
      it { expect(page).to_not have_selector '.attribute-identifier_source' }
      it { expect(page).to_not have_selector '.attribute-peerreviewed' }
      it { expect(page).to_not have_selector '.attribute-bibliographic_citation' }
      it { expect(page).to_not have_selector '.attribute-relation_ispartofseries' }
      it { expect(page).to_not have_selector '.attribute-rights_statement' }
      it { expect(page).to_not have_selector '.attribute-type_none' }
      it { expect(page).to_not have_selector '.attribute-language_none' }
      it { expect(page).to_not have_selector '.attribute-description_mapping' }
      it { expect(page).to_not have_selector '.attribute-description_sponsorship' }

    end

    context "when work is a member of a collection" do
      let(:collection_title) { 'A good title' }
      let(:collection) { build(:collection_lw, user: user, title: [collection_title], with_permission_template: true) }
      let(:work) do
        DataSet.new( title:            [title],
                     authoremail:      authoremail,
                     creator:          [creator],
                     curation_notes_admin: [curation_notes_admin],
                     curation_notes_user: [curation_notes_user],
                     date_created:     date_created,
                     depositor:        depositor,
                     description:      [description],
                     fundedby:         [fundedby],
                     methodology:      [methodology],
                     prior_identifier: [prior_identifier],
                     rights_license:   rights_license,
                     subject_discipline: [subject_discipline],
                     visibility:       visibility_public )
      end

      let(:solr_document) { SolrDocument.new(work.to_solr) }
      let(:data_set_controller) { Hyrax::DataSetsController.new }
      let(:presenter) do
        Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
          p.controller = data_set_controller
        end
      end
      let(:rendered)      { render 'hyrax/base/relationships', presenter: presenter }
      let(:page)          { Capybara::Node::Simple.new(rendered) }

      before do
        allow(data_set_controller).to receive(:curation_concern).and_return work
        allow(view).to receive(:current_ability).and_return(ability)
        allow(ability).to receive(:admin?).and_return false
        allow(ability).to receive(:user_groups).and_return []
        allow(ability).to receive(:current_user).and_return nil
        work.member_of_collections = [collection]
        work.save!
        assign( :presenter, presenter )
      end

      it { expect(page).to have_content 'In Collection:' }
      it { expect(page).to have_content collection_title }
    end

    context 'display various fields multiple', skip: false do
      let(:work) do
        DataSet.new( title:          [title],
                     creator:        creators,
                     curation_notes_user: curation_notes_users,
                     description:    descriptions,
                     fundedby:       fundedbys,
                     methodology:    methodologies,
                     subject_discipline: [subject_discipline] )
      end
      let(:solr_document) { SolrDocument.new(work.to_solr) }
      let(:data_set_controller) { Hyrax::DataSetsController.new }
      let(:presenter) do
        Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
          p.controller = data_set_controller
        end
      end
      let(:rendered)      { render 'hyrax/base/attribute_rows', presenter: presenter }
      let(:page)          { Capybara::Node::Simple.new(rendered) }

      before do
        allow(data_set_controller).to receive(:curation_concern).and_return work
        allow(ability).to receive(:admin?).and_return false
        assign( :presenter, presenter )
      end

      it { expect(page).to have_css(%(li[class="attribute attribute-creator"]), count: 2) }
      it { expect(page).to have_content creators[0] }
      it { expect(page).to have_content creators[1] }
      it { expect(page).to have_link(creators[0]) }
      it { expect(page).to have_link(creators[1]) }
      it { expect(page).to have_css(%(li[class="attribute attribute-curation_note_user"]), count: 2) }
      it { expect(page).to have_content curation_notes_user[0] }
      it { expect(page).to have_content curation_notes_user[1] }
      it { expect(page).to have_css(%(li[class="attribute attribute-description"]), count: 2) }
      it { expect(page).to have_content descriptions[0] }
      it { expect(page).to have_content descriptions[1] }
      it { expect(page).to have_content fundedbys[0] }
      it { expect(page).to have_content fundedby[1] }
      it { expect(page).to have_selector '.attribute-fundedby' }
      it { expect(page).to have_content methodologies[0] }
      it { expect(page).to have_content methodologies[2] }
      it { expect(page).to have_selector '.attribute-methodology' }
      it { expect(page).to have_content resource_type }
      it { expect(page).to have_link resource_type }
      it { expect(page).to have_selector '.attribute-resource_type' }
      it { expect(page).to have_content subject_discipline }
      it { expect(page).to have_selector '.attribute-subject_discipline' }

      # title doesn't show up as metadata attribute
      # it 'title' do
      #   expect(page).to have_content title
      #   expect(page).to have_selector '.work_description_title'
      # end

    end

    context 'do not display various fields', skip: false do
      let(:current_user)        { user.user_key }
      let(:work)                { DataSet.new( title: [title] ) }
      let(:solr_document)       { SolrDocument.new(work.to_solr) }
      let(:data_set_controller) { Hyrax::DataSetsController.new }
      let(:presenter) do
        Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
          p.controller = data_set_controller
        end
      end
      let(:rendered)      { render 'hyrax/base/attribute_rows', presenter: presenter }
      let(:page)          { Capybara::Node::Simple.new(rendered) }

      before do
        allow(data_set_controller).to receive(:curation_concern).and_return work
        allow(ability).to receive(:admin?).and_return false
        assign( :presenter, presenter )
      end

      it { expect(page).to_not have_content authoremail }
      it { expect(page).to_not have_link authoremail }
      it { expect(page).to_not have_selector '.attribute-authoremail' }
      it { expect(page).to_not have_content creator }
      it { expect(page).to_not have_link(creator) }
      it { expect(page).to_not have_content description }
      it { expect(page).to_not have_selector '.attribute-description' }
      it { expect(page).to_not have_content depositor }
      it { expect(page).to_not have_selector '.attribute-depositor' }
      it { expect(page).to_not have_content fundedby }
      it { expect(page).to_not have_selector '.attribute-fundedby' }
      it { expect(page).to_not have_content methodology }
      it { expect(page).to_not have_selector '.attribute-methodology' }
      it { expect(page).to have_content resource_type }
      it { expect(page).to have_link resource_type }
      it { expect(page).to have_selector '.attribute-resource_type' }
      it { expect(page).to_not have_selector '.attribute-rights_license' }
      it { expect(page).to_not have_link(rights_license, href: rights_license) }
      it { expect(page).to_not have_content subject_discipline }
      it { expect(page).to_not have_selector '.attribute-subject_discipline' }

    end

    # context 'with rights statement', skip: true do
    #   # don't use rights statement in DBD
    #   let(:url) { "http://example.com" }
    #   let(:rights_statement_uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
    #   let(:work) do
    #     stub_model(DataSet,
    #                depositor: user.user_key,
    #                related_url: [url],
    #                rights_license: rights_statement_uri)
    #   end
    #   let(:solr_document) do
    #     SolrDocument.new(id: work.id,
    #                      has_model_ssim: 'DataSet',
    #                      depositor_tesim: user.user_key,
    #                      rights_license_tesim: rights_statement_uri,
    #                      related_url_tesim: [url])
    #   end
    #   let(:data_set_controller) { Hyrax::DataSetsController.new }
    #   let(:presenter) do
    #     Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
    #       p.controller = data_set_controller
    #     end
    #   end
    #   let(:rendered)      { render 'hyrax/base/attribute_rows', presenter: presenter }
    #   let(:page)          { Capybara::Node::Simple.new(rendered) }
    #
    #   let(:page) do
    #     render 'hyrax/base/attribute_rows', presenter: presenter
    #     Capybara::Node::Simple.new(rendered)
    #   end
    #   # let(:work_url) { "umrdr-testing.hydra.lib.umich.edu/concern/work/#{work.id}" }
    #   let(:work_url) { "/concern/work/#{work.id}" }
    #
    #   before do
    #     allow(data_set_controller).to receive(:curation_concern).and_return work
    #     allow(ability).to receive(:admin?).and_return false
    #     assign( :presenter, presenter )
    #   end
    #
    #   it 'shows external link with icon for related url field' do
    #     expect(page).to have_selector '.glyphicon-new-window'
    #     expect(page).to have_link(url)
    #   end
    #
    #   it 'shows rights statement with link to statement URL' do
    #     expect(page).to have_link("In Copyright", href: rights_statement_uri)
    #   end
    # end
    #
    # context 'rights statement other', skip: true do
    #   let(:url) { "http://example.com" }
    #   let(:rights_statement_other) { 'The value displayed for Other license.' }
    #   let(:ability) { double }
    #   let(:work) do
    #     stub_model(DataSet,
    #                depositor: user.user_key,
    #                related_url: [url],
    #                rights_license: 'Other',
    #                rights_license_other: rights_statement_other )
    #   end
    #   let(:solr_document) do
    #     SolrDocument.new(id: work.id,
    #                      has_model_ssim: 'DataSet',
    #                      rights_license_tesim: 'Other',
    #                      rights_license_other_tesim: rights_statement_other)
    #   end
    #   let(:data_set_controller) { Hyrax::DataSetsController.new }
    #   let(:presenter) do
    #     Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
    #       p.controller = data_set_controller
    #     end
    #   end
    #   let(:rendered)      { render 'hyrax/base/attribute_rows', presenter: presenter }
    #   let(:page)          { Capybara::Node::Simple.new(rendered) }
    #
    #   let(:page) do
    #     render 'hyrax/base/attribute_rows', presenter: presenter
    #     Capybara::Node::Simple.new(rendered)
    #   end
    #   let(:work_url) { "/concern/work/#{work.id}" }
    #
    #   before do
    #     allow(data_set_controller).to receive(:curation_concern).and_return work
    #     allow(ability).to receive(:admin?).and_return false
    #     assign( :presenter, presenter )
    #   end
    #
    #   it 'shows rights statement with other value' do
    #     expect(page).to have_content rights_statement_other
    #   end
    # end

  end

  describe 'admin users', skip: false do
    let(:user) { create(:admin) }

    context 'do not display various fields', skip: true do
      let(:current_user)        { user.user_key }
      let(:work)                { DataSet.new( title: [title],
                                               curation_notes_admin: [curation_notes_admin],
                                               prior_identifier: [prior_identifier] ) }
      let(:solr_document)       { SolrDocument.new(work.to_solr) }
      let(:data_set_controller) { Hyrax::DataSetsController.new }
      let(:presenter) do
        Hyrax::DataSetPresenter.new(solr_document, ability).tap do |p|
          p.controller = data_set_controller
        end
      end
      let(:rendered)      { render 'hyrax/base/attribute_rows', presenter: presenter }
      let(:page)          { Capybara::Node::Simple.new(rendered) }

      before do
        allow(data_set_controller).to receive(:curation_concern).and_return work
        allow(ability).to receive(:admin?).and_return false
        assign( :presenter, presenter )
      end

      it { expect(page).to have_content curation_notes_admin }
      it { expect(page).to have_selector '.attribute-curation_note_admin' }

      it { expect(page).to have_content prior_identifier }
      it { expect(page).to have_selector '.attribute-prior_identifier' }

      it { expect(page).to have_selector '.attribute-read_users' }
      it { expect(page).to have_selector '.attribute-edit_users' }
      it { expect(page).to have_selector '.attribute-read_groups' }
      it { expect(page).to have_selector '.attribute-edit_groups' }

    end

  end

end
