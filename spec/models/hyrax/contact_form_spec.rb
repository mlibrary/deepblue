require 'rails_helper'

RSpec.describe Hyrax::ContactForm, type: :model do

  let(:category) { 'Depositing content' }
  let(:name) { 'Rose Tyler' }
  let(:email) { 'rose@timetraveler.org' }
  let(:subject) { 'The Doctor' }
  let(:message) { 'Run' }

  let(:contact_method) { nil } # filled in for spam
  let(:contact_method_spam) { "Hi! I'm a bot" }

  let(:contact_form) { described_class.new(category: category,
                                       name: name,
                                       email: email,
                                       subject: subject,
                                       message: message,
                                       contact_method: contact_method) }

  let(:contact_form_spam) { described_class.new(category: category,
                                       name: name,
                                       email: email,
                                       subject: subject,
                                       message: message,
                                       contact_method: contact_method_spam) }

  it "has parameters" do
    expect(contact_form).to respond_to(:category)
    expect(contact_form).to respond_to(:name )
    expect(contact_form).to respond_to(:email)
    expect(contact_form).to respond_to(:subject)
    expect(contact_form).to respond_to(:message)

    expect(contact_form).to respond_to(:contact_method)

    expect(contact_form.category).to eq category
    expect(contact_form.name).to eq name
    expect(contact_form.email).to eq email
    expect(contact_form.subject).to eq subject
    expect(contact_form.message).to eq message

    expect(contact_form.contact_method).to eq contact_method
  end

  describe "validations", :clean_repo do

    it "ensures all error fields are empty when valid" do
      expect(contact_form).to be_valid
      expect(contact_form.spam?).to eq false

      expect(contact_form.errors.messages[:category]).to be_empty
      expect(contact_form.errors.messages[:name]).to be_empty
      expect(contact_form.errors.messages[:email]).to be_empty
      expect(contact_form.errors.messages[:subject]).to be_empty
      expect(contact_form.errors.messages[:message]).to be_empty

    end

    it "ensures the required fields have values" do
      contact_form.category = nil
      contact_form.name = nil
      contact_form.email = nil
      contact_form.subject = nil
      contact_form.message = nil

      expect(contact_form).not_to be_valid
      expect(contact_form.spam?).to eq false

      expect(contact_form.errors.messages[:category]).not_to be_empty
      expect(contact_form.errors.messages[:name]).not_to be_empty
      expect(contact_form.errors.messages[:email]).not_to be_empty
      expect(contact_form.errors.messages[:subject]).not_to be_empty
      expect(contact_form.errors.messages[:message]).not_to be_empty

    end

    it "ensures that it is still valid if contact_method has a value" do
      contact_form.contact_method = 'This is a valid value.'

      expect(contact_form).to be_valid
      expect(contact_form.spam?).to eq true

      expect(contact_form.errors.messages[:category]).to be_empty
      expect(contact_form.errors.messages[:name]).to be_empty
      expect(contact_form.errors.messages[:email]).to be_empty
      expect(contact_form.errors.messages[:subject]).to be_empty
      expect(contact_form.errors.messages[:message]).to be_empty
    end

  end

  describe "spam", :clean_repo do

    it "is spam" do
      expect(contact_form_spam.contact_method).to_not be_empty

      expect(contact_form_spam).to be_valid
      expect(contact_form_spam.spam?).to eq true

      expect(contact_form_spam.errors.messages[:category]).to be_empty
      expect(contact_form_spam.errors.messages[:name]).to be_empty
      expect(contact_form_spam.errors.messages[:email]).to be_empty
      expect(contact_form_spam.errors.messages[:subject]).to be_empty
      expect(contact_form_spam.errors.messages[:message]).to be_empty

    end

  end

end
