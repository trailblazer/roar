## 0.10.1

* Adding the Coercion feature.

## 0.10.0

* Requiring representable-0.1.3.
* Added JSON-HAL support.
* Links are no longer rendered when `href` is `nil` or `false`.
* `Representer.link` class method now accepts either the `rel` value, only, or a hash of link attributes (defined in `Hypermedia::Hyperlink.params`), like `link :rel => :self, :title => "You're good" do..`
* API CHANGE: `Representer#links` no longer returns the `href` value but the link object. Use it like `object.links[:self].href` to retrieve the URL.
* `#from_json` won't throw an exception anymore when passed an empty json document.

## 0.9.2

* Using representable-1.1.

## 0.9.1

* Removed @Representer#to_attributes@ and @#from_attributes@.
* Using representable-1.0.1 now.

## 0.9.0

* Using representable-0.12.x.
* `Representer::Base` is now simply `Representer`.
* Removed all the class methods from `HttpVerbs` except for `get`.


## 0.8.3

* Maintenance release for representable compat.

## 0.8.2

* Removing `restfulie` dependency - we now use `Net::HTTP`.

## 0.8.1

* Added the :except and :include options to `#from_*`.
