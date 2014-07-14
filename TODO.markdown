* alias Roar::Representer to Representer
Roar::Hypermedia
* Hyperlink representers => decrators. test hash representer with decorator (rpr)


* Add proxies, so nested models can be lazy-loaded.
* move #prepare_links! call to #_links or something so it doesn't need to be called in #serialize.
* remove #before_serialize and just overwrite #serialize
* abstract ::links_definition_options and move them out of the generic representers (JSON, XML).
* make 1.8 tests work, again (hash ordering!)

* release 1.0
* representable 1.8, only.
* revise Hypermedia
* work on HAL-Object