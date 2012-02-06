h2. 0.9.2

* Using representable-1.1.

h2. 0.9.1

* Removed @Representer#to_attributes@ and @#from_attributes@.
* Using representable-1.0.1 now.

h2. 0.9.0

* Using representable-0.12.x.
* `Representer::Base` is now simply `Representer`.
* Removed all the class methods from `HttpVerbs` except for `get`.


h2. 0.8.3

* Maintenance release for representable compat.

h2. 0.8.2

* Removing `restfulie` dependency - we now use `Net::HTTP`.

h2. 0.8.1

* Added the :except and :include options to `#from_*`.
