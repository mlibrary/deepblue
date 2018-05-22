require 'rails_helper'

RSpec.describe Hyrax::DataSetsController do

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

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context 'someone elses private work' do
    # let(:work) { create(:private_data_set) }
    #
    # it 'shows unauthorized message' do
    #   get :show, params: { id: work }
    #   expect(response.code).to eq '401'
    #   expect(response).to render_template(:unauthorized)
    # end
  end

end
