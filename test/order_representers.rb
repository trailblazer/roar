require 'roar/representer/json'
require 'roar/representer/feature/http_verbs'
require 'roar/representer/feature/hypermedia'

module JSON
  
  class Item
    include Roar::Representer::JSON
    
    property :article_id
    property :amount
    
    include Roar::Representer::Feature::HttpVerbs
    include Roar::Representer::Feature::Hypermedia
  end
  
  
  class Order
    include Roar::Representer::JSON
    property :client_id
    collection :items, :class => Item
    
    
    include Roar::Representer::Feature::HttpVerbs
    include Roar::Representer::Feature::Hypermedia
    
    
    link :items do
      items_url
    end
    
    link :self do
      order_url(represented)
    end
  end
  
end
