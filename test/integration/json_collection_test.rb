require 'test_helper'

require 'roar/json/collection'
require 'roar/client'

class JsonCollectionTest < MiniTest::Spec
  class Band < OpenStruct; end

  module BandRepresenter
    include Roar::JSON

    property :name
    property :label
  end

  module BandsRepresenter
    include Roar::JSON::Collection

    items extend: BandRepresenter, class: Band
  end
  
  class Bands < Array
    include Roar::JSON::Collection
    include BandsRepresenter
    include Roar::Client
  end

  let(:bands) { Bands.new }

  # "[{\"name\":\"Slayer\",\"label\":\"Canadian Maple\"},{\"name\":\"Nirvana\",\"label\":\"Sub Pop\"}])"
  it 'fetches lonely collection of existing bands' do
    bands.get(uri: 'http://localhost:4567/bands', as: 'application/json')
    bands.size.must_equal(2)
    bands[0].name.must_equal('Slayer')
  end
end
