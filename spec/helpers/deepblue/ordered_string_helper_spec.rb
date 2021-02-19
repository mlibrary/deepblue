# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::OrderedStringHelper, type: :helper do

  let( :item1 ) { "item1" }
  let( :item2 ) { "item2" }
  let( :item3 ) { "item3" }
  let( :empty_array ) { [] }
  let( :array1 ) { [item1] }
  let( :array2 ) { [item1, item2] }

  it "#deserialize" do
    expect( described_class.deserialize( "[]" ) ).to eq empty_array
    expect( described_class.deserialize( "[\"item1\"]" ) ).to eq array1
    expect( described_class.deserialize( "[\"item1\",\"item2\"]" ) ).to eq array2
  end

  it "#serialize" do
    expect( described_class.serialize( empty_array ) ).to eq "[]"
    expect( described_class.serialize( array1 ) ).to eq "[\"item1\"]"
    expect( described_class.serialize( array2 ) ).to eq "[\"item1\",\"item2\"]"
  end

end
