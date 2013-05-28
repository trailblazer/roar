* Add proxies, so nested models can be lazy-loaded.
* move #prepare_links! call to #_links or something so it doesn't need to be called in #serialize.
* alias Roar::Representer to Representer
* remove #before_serialize and just overwrite #serialize
* abstract ::links_definition_options and move them out of the generic representers (JSON, XML).
* make 1.8 tests work, again (hash ordering!)