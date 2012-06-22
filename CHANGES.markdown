## 0.11.2

* The request body in POST, PUT and PATCH is now actually sent in HttpVerbs. Thanks to @nleguen for finding this embarrassing bug. That's what happens when you don't have proper tests, kids!

## 0.11.1

* Since some users don't have access to my local hard-drive we now really require representable-1.2.2.

## 0.11.0

* Using representable-1.2.2 now. Be warned that in 1.2 parsing and rendering slightly changed. When a property is not found in the incoming document, it is ignored and thus might not be initialised in your represented model (empty collections are still set to an empty array). Also, the way `false` and `nil` values are rendered changed. Quoted from the representable CHANGES file:
* A property with false value will now be included in the rendered representation. Same applies to parsing, false values will now be included. That particularly means properties that used to be unset (i.e. nil) after parsing might be false now.
* You can include nil values now in your representations since #property respects :represent_nil => true.

* The `:except` option got deprecated in favor of `:exclude`.
* Hyperlinks can now have arbitrary attributes. To render, just provide `#link` with the options 
<code>link :self, :title => "Mee!", "data-remote" => true</code>
When parsing, the options are avaible via `OpenStruct` compliant readers.
<code>link = Hyperlink.from_json({\"rel\":\"self\",\"data-url\":\"http://self\"} )
link.rel #=> "self"
link.send("data-url") #=> "http://self"
</code>

## 0.10.2

* You can now pass values from outside to the render method (e.g. `#to_json`), they will be available as block parameters inside `#link`.

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
