Dummy::Application.routes.draw do
  match ':controller(/:action(/:id(.:format)))'
  root :to => 'musician#index'
  resources :albums
  resources :songs
  get "articles/starts_with/{query}", :to => "albums#search",:class => :album_search
end
