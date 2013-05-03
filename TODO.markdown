* Add proxies, so nested models can be lazy-loaded.
* move #prepare_links! call to #_links or something so it doesn't need to be called in #serialize.
* alias Roar::Representer to Representer
* remove #before_serialize and just overwrite #serialize
* abstract ::links_definition_options and move them out of the generic representers (JSON, XML). remove lambdas when :representer_exec calls methods in decorator ctx, also