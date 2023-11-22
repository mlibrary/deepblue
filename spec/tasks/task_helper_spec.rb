# frozen_string_literal: true

require 'rails_helper'

require_relative "../../app/helpers/deepblue/task_helper"

RSpec.describe ::Deepblue::TaskHelper, skip: false do

  describe '.dbd_version_1?' do
    it "resolves" do
      expect( Rails.configuration.dbd_version == 'DBDv2' ).to eq true
      expect( described_class.dbd_version_1? ).to eq false
    end
  end

  describe '.dbd_version_2?' do
    it "resolves" do
      expect( Rails.configuration.dbd_version == 'DBDv2' ).to eq true
      expect( described_class.dbd_version_2? ).to eq true
    end
  end

  describe '.hydra_model_work?' do
    it "resolves" do
      expect( described_class.dbd_version_2? ).to eq true
      expect( described_class.hydra_model_work?( hydra_model: 'GenericWork' ) ).to eq false
      expect( described_class.hydra_model_work?( hydra_model: 'DataSet' ) ).to eq true
    end
  end

end
