require 'roar/rails/controller_methods'
require 'roar/rails/representer_methods'

module Roar
  module Rails
    
  end
end

# FIXME: don't like monkey-patching:
# TODO: assure we don't overwrite anything here, as people might want to do things without AR/DM.
Roar::Representer::Base.class_eval do
  puts "mixin in ModelRepresenting"
  #include Roar::Representer::Feature::ModelRepresenting
  include Roar::Representer::Feature::ActiveRecordMethods  # to_nested_attributes
  #include Roar::Rails::RepresenterMethods
end
