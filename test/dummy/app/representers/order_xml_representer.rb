class OrderXmlRepresenter < ModelRepresenter
  
  include ActionController::UrlFor
  include Rails.application.routes.url_helpers
  
  #include Roar::Representer::Feature::Hypermedia
  
  
  #include Roar::Representer::Feature::HttpVerbs  # get, post, ...
  
  
  self.representation_name= :order
  
  self.representable_property :id
  self.representable_property :client_id
  #self.representable_property :items, :tag => :item, :as => [ItemXmlRepresenter]
  
  link :self do
    order_url( :id => id)
  end
  
  link :checkout do
    "http://test.host/orders/#{id}/checkout"
  end
  
  link "items-search" do
    "http://localhost:3001/articles/starts_with/{query}"
  end
end
