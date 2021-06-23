# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/tasks/yaml_populate_for_collection'

RSpec.describe ::Deepblue::YamlPopulateFromAllCollections, skip: false do

  # describe 'constants' do
  #   it "resolves them" do
  #   end
  # end

  describe '.run' do
    let( :options ) { {} }
    let( :populate ) { ::Deepblue::YamlPopulateFromAllCollections.new( options: options ) }

    before do
      expect( populate ).to receive( :run_all ).with( no_args ).once
      expect( populate ).to receive( :report_stats ).once
      expect( populate ).to receive( :report_collection ).with( any_args) .once
    end

    it "it invokes run_all" do
      populate.ids = ['id123']
      populate.run
    end
  end

end

RSpec.describe ::Deepblue::YamlPopulateFromCollection, skip: false do

  # describe 'constants' do
  #   it "resolves them" do
  #   end
  # end

  describe '.run' do
    let( :options ) { {} }
    let( :id ) { 'id123' }
    let( :populate ) { ::Deepblue::YamlPopulateFromCollection.new( id: id, options: options ) }

    before do
      expect( populate ).to receive( :run_one ).with( id: id ).once
      expect( populate ).to receive( :report_stats ).once
      expect( populate ).to receive( :report_collection ).with( any_args) .once
    end

    it "it invokes run_all" do
      populate.run
    end
  end

end

RSpec.describe ::Deepblue::YamlPopulateFromMultipleCollections, skip: false do

  # describe 'constants' do
  #   it "resolves them" do
  #   end
  # end

  describe '.run' do
    let( :options ) { {} }
    let( :ids ) { 'id123 id234' }
    let( :populate ) { Deepblue::YamlPopulateFromMultipleCollections.new( ids: ids, options: options ) }

    before do
      expect( populate ).to receive( :run_multiple ).with( ids: ['id123', 'id234'] ).once
      expect( populate ).to receive( :report_stats ).once
      expect( populate ).to receive( :report_collection ).with( any_args) .once
    end

    it "it invokes run_all" do
      populate.run
    end
  end

end
