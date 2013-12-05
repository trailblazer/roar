# ROAR

_Resource-Oriented Architectures in Ruby._

## Introduction

Roar is a framework for parsing and rendering REST documents. Nothing more.

Representers let you define your API document structure and semantics. They allow both rendering representations from your models _and_ parsing documents to update your Ruby objects. The bi-directional nature of representers make them interesting for both server and client usage.

Roar comes with built-in JSON, JSON::HAL and XML support. Its highly modulare architecture provides features like coercion, hypermedia, HTTP transport, client caching and more.

Roar is completely framework-agnostic and loves being used in web kits like Rails, Webmachine, Sinatra, Padrino, etc. If you use Rails, consider [roar-rails](https://github.com/apotonick/roar-rails) for an enjoyable integration.

## Representable

Roar is just a thin layer on top of the [representable](https://github.com/apotonick/representable) gem. While Roar gives you a DSL and behaviour for creating hypermedia APIs, representable implements all the mapping functionality.

If in need for a feature, make sure to check the [representable API docs](https://github.com/apotonick/representable) first.


## Defining Representers

Let's see how representers work. They're fun to use.

```ruby
require 'roar/representer/json'

module SongRepresenter
  include Roar::Representer::JSON

  property :title
end
```

API documents are defined using a representer module or decorator class. You can define plain attributes using the `::property` method.

Now let's assume we'd have `Song` which is an `ActiveRecord` class. Please note that Roar is not limited to ActiveRecord. In fact, it doesn't really care whether it's representing ActiveRecord, Datamapper or just an OpenStruct instance.

```ruby
class Song < ActiveRecord
end
```

## Rendering

To render a document, you apply the representer to your model.

```ruby
song = Song.new(title: "Fate")
song.extend(SongRepresenter)

song.to_json #=> {"title":"Fate"}
```

Here, the representer is injected into the actual model and gives us a new `#to_json` method.

## Parsing

The cool thing about representers is: they can be used for rendering and parsing. See how easy updating your model from a document is.

```ruby
song = Song.new
song.extend(SongRepresenter)

song.from_json('{"title":"Linoleum"}')

song.title #=> Linoleum
```

Again, `#from_json` comes from the representer and just updates the known properties.

Unknown attributes in the parsed document are simply ignored, making half-baked solutions like `strong_parameters` redundant.


## Decorator

Many people dislike `#extend` due to eventual performance issue or object polution. If you're one of those, just go with a decorator representer. They almost work identical to the module approach we just discovered.

```ruby
require 'roar/decorator'

class SongRepresenter < Roar::Decorator
  include Roar::Representer::JSON

  property :title
end
```
Instead of a module you use a class, the DSL inside is the same you already know.

```ruby
song = Song.new(title: "Medicine Balls")

SongRepresenter.new(song).to_json #=> {"title":"Medicine Balls"}
```

Here, the `song` objects gets wrapped (or "decorated") by the decorator. It is treated as immutuable - Roar won't mix in any behaviour.

Note that decorators and representer modules have identical features. You can parse, render, nest, go nuts with both of them.

However, in this README we'll use modules to illustrate this framework.


## Collections

Roar (or rather representable) also allows to map collections in documents.

```ruby
module SongRepresenter
  include Roar::Representer::JSON

  property :title
  collection :composers
end
```

Where `::property` knows how to handle plain attributes, `::collection` does lists.

```ruby
song = Song.new(title: "Roxanne", composers: ["Sting", "Stu Copeland"])
song.extend(SongRepresenter)

song.to_json #=> {"title":"Roxanne","composers":["Sting","Stu Copeland"]}
```

And, yes, this also works for parsing: `from_json` will create and populate the array of the `composers` attribute.


## Nesting

Now what if we need to tackle with collections of `Song`s? We need to implement an `Album` class.

```ruby
class Album < ActiveRecord
  has_many :songs
end
```

Another representer is needed to represent.

```ruby
module AlbumRepresenter
  include Roar::Representer::JSON

  property :title
  collection :songs, extend: SongRepresenter, class: Song
end
```

Both `::property` and `::collection` accept options for nesting representers into representers.

The `extend:` option tells Roar which representer to use for the nested objects (here, the array items of the `album.songs` field). When parsing a document `class:` defines the nested object type.

Consider the following object setup.

```ruby
album = Album.new(title: "True North")
album.songs << Song.new(title: "The Island")
album.songs << Song.new(:title => "Changing Tide")
```

You apply the `AlbumRepresenter` and you get a nested document.

```ruby
album.extend(AlbumRepresenter)

album.to_json #=> {"title":"True North","songs":[{"title":"The Island"},{"title":"Changing Tide"}]}
```

That also works vice-versa.

```ruby
album = Album.new
album.extend(AlbumRepresenter)

album.from_json('{"title":"Indestructible","songs":[{"title":"Tropical London"},{"title":"Roadblock"}]}')

puts album.songs[1] #=> #<Song title="Roadblock">
```

The nesting of two representers can map composed object as you cind them in many many APIs.


## Inline Representer

Sometimes you don't wanna create two separate representers - although it makes them reusable across your app. Use inline representers if you're not intending this.

```ruby
module AlbumRepresenter
  include Roar::Representer::JSON

  property :title

  collection :songs, class: Song do
    property :title
  end
end
```

This will give you the same rendering and parsing behaviour as in the previous example with just one module.


## Syncing Objects


Say your webshop consists of two completely separated apps. The REST backend, a Sinatra app, serves articles and processes orders. The frontend, being browsed by your clients, is a rich Rails application. It queries the services for articles, renders them nicely and reads or writes orders with REST calls. That being said, the frontend turns out to be a pure REST client.


h2. Representations

Representations are the pivotal elements of REST. Work in a REST system means working with representations, which can be put down to parsing or extracting representations and rendering the like.

Roar makes it easy to render and parse representations of resources after defining the formats.


h3. Creating Representations

Why not GET a particular article, what about a good beer?

@GET http://articles/lonestarbeer@

It's cheap and it's good. The response of a GET is a representation of the requested resource. A *representation* is always a *document*. In this example, it's a bit of JSON.

pre. { "article": {
  "title":  "Lonestar Beer",
  "id":     4711,
  "links":[
    { "rel":  "self",
      "href": "http://articles/lonestarbeer"}
  ]}
}

p. In addition to boring article data, there's a _link_ embedded in the document. This is *hypermedia*, yeah! We will learn more about that shortly.

So, how did the service render that JSON document? It could use an ERB template, @#to_json@, or maybe another gem. The document could also be created by a *representer*.

Representers are the key ingredience in Roar, so let's check them out!


h2. Representers

Representers are most usable when defined in a module, and then mixed into a host class. In our example, the host class is the article.

<pre>
class Article
  attr_accessor :title, :id
end
</pre>

To render a representational document from the article, the backend service has to define a representer.

<pre>
require 'roar/representer/json'
require 'roar/representer/feature/hypermedia'


module ArticleRepresenter
  include Roar::Representer::JSON
  include Roar::Representer::Feature::Hypermedia

  property :title
  property :id

  link :self do
    article_url(self)
  end
end
</pre>

Hooray, we can define plain properties and embedd links easily - and we can even use URL helpers (in Rails, using the "roar-rails gem":https://github.com/apotonick/roar-rails). There's even more, nesting, collections, but more on that later!


h3. Rendering Representations in the Service

In order to *render* an actual document, the backend service would have to do a few steps: creating a representer, filling in data, and then serialize it.

<pre>loney = Article.new.extend(ArticleRepresenter)
  loney.title = "Lonestar"
  loney.id    = 666
  loney.to_json # => "{\"article\":{\"id\":666, ...
</pre>

Articles itself are useless, so they may be placed into orders. This is the next example.


h3. Nesting Representations

What if we wanted to check an existing order? We'd @GET http://orders/1@, right?

<pre>{ "order": {
  "id":         1,
  "client_id":  "815",
  "articles":   [
    {"title": "Lonestar Beer",
    "id":     666,
    "links":[
      { "rel":  "self",
        "href": "http://articles/lonestarbeer"}
    ]}
  ],
  "links":[
    { "rel":  "self",
      "href": "http://orders/1"},
    { "rel":  "items",
      "href": "http://orders/1/items"}
  ]}
}
</pre>

The order model is simple.

<pre>
class Order
  attr_accessor :id, :client_id, :articles
end
</pre>

Since orders may contain a composition of articles, how would the order service define its representer?

<pre>
module OrderRepresenter
  include Roar::Representer::JSON
  include Roar::Representer::Feature::Hypermedia

  property :id
  property :client_id

  collection :articles, :class => Article

  link :self do
    order_url(represented)
  end

  link :items do
    items_url
  end
end
</pre>

Representers don't have to be in modules, but can be

The declarative @#collection@ method lets us define compositions of representers.


h3. Parsing Documents in the Service

Rendering stuff is easy: Representers allow defining the layout and serializing documents for us. However, representers can do more. They work _bi-directional_ in terms of rendering outgoing _and_ parsing incoming representation documents.

If we were to implement an endpoint for creating new orders, we'd allow POST to @http://orders/@. Let's explore the service code for parsing and creation.

<pre>
  post "/orders" do
    order = Order.new.extend(OrderRepresenter)
    order.from_json(request.body.string)
    order.to_json
  end
</pre>

Look how the @#from_json@ method helps extracting data from the incoming document and, again, @#to_json@ returns the freshly created order's representation. Roar's representers are truely working in both directions, rendering and parsing and thus prevent you from redundant knowledge sharing.


h2. Representers in the Client

The new representer abstraction layer seems complex and irritating first, where you used @params[]@ and @#to_json@ is a new OOP instance now. But... the cool thing is: You can package representers in gems and distribute them to your client layer as well. In our example, the web frontend can take advantage of the representers, too.


h3. Using HTTP

Communication between REST clients and services happens via HTTP - clients request, services respond. There are plenty of great gems helping out, namely Restfulie, HTTParty, etc. Representers in Roar provide support for HTTP as well, given you mix in the @HTTPVerbs@ feature module!

To create a new order, the frontend needs to POST to the REST backend. Here's how this could happen using a representer on HTTP.


<pre>
  order = Order.new(:client_id => current_user.id)
  order.post("http://orders/")
</pre>

A couple of noteworthy steps happen here.

# Using the constructor a blank order document is created.
# Initial values like the client's id are passed as arguments and placed in the document.
# The filled-out document is POSTed to the given URL.
# The backend service creates an actual order record and sends back the representation.
# In the @#post@ call, the returned document is parsed and attributes in the representer instance are updated accordingly,

After the HTTP roundtrip, the order instance keeps all the information we need for proceeding the ordering workflow.

<pre>
  order.id #=> 42
</pre>

h3. Discovering Hypermedia

Now that we got a fresh order, let's place some items! The system's API allows adding articles to an existing order by POSTing articles to a specific resource. This endpoint is propagated in the order document using *hypermedia*.

Where and what is this hypermedia?

First, check the JSON document we get back from the POST.

<pre>{ "order": {
  "id":         42,
  "client_id":  1337,
  "articles":   [],
  "links":[
    { "rel":  "self",
      "href": "http://orders/42"},
    { "rel":  "items",
      "href": "http://orders/42/items"}
  ]}
}
</pre>

Two hypermedia links are embedded in this representation, both feature a @rel@ attribute for defining a link semantic - a "meaning" - and a @href@ attribute for a network address. Isn't that great?

* The @self@ link refers to the actual resource. It's a REST best practice and representations should always refer to their resource address.
* The @items@ link is what we want. The address @http://orders/42/items@ is what we have to refer to when adding articles to this order. Why? Cause we decided that!


h3. Using Hypermedia

Let the frontend add the delicious "Lonestar" beer to our order, now!

<pre>
beer = Article.new(:title => "Lonestar Beer")
beer.post(order.links[:items])
</pre>

That's all we need to do.

# First, we create an appropriate article representation.
# Then, the @#links@ method helps extracting the @items@ link URL from the order document.
# A simple POST to the respective address places the item in the order.

The @order@ instance in the frontend is now stale - it doesn't contain articles, yet, since it is still the document from the first post to @http://orders/@.

<pre>
order.items #=> []
</pre>

To update attributes, a GET is needed.

<pre>
order.get!(order.links[:self])
</pre>

Again, we use hypermedia to retrieve the order's URL. And now, the added article is included in the order.

[*Note:* If this looks clumsy - It's just the raw API for representers. You might be interested in the upcoming DSL that simplifys frequent workflows as updating a representer.]

<pre>
order.to_attributes #=> {:id => 42, :client_id => 1337,
  :articles => [{:title => "Lonestar Beer", :id => 666}]}
</pre>

This is cool, we used REST representers and hypermedia to create an order and fill it with articles. It's time for a beer, isn't it?


h3. Using Accessors

What if the ordering API is going a different way? What if we had to place articles into the order document ourselves, and then PUT this representation to @http://orders/42@? No problem with representers!

Here's what could happen in the frontend.

<pre>
beer = Article.new(:title => "Lonestar Beer")
order.items << beer
order.post(order.links[:self])
</pre>

This was dead simple since representations can be composed of different documents in Roar.

h2. Decorators

You can use `Roar::Decorator` as a representer. More docs coming soon. Note that if you want your represented object to save incoming hypermedia you need to do two things.

<pre>
class SongClient
  # do whatever here

  attr_accessor :links
end

class SongRepresenter < Roar::Decorator
  include Roar::Representer::JSON
  include Roar::Decorator::HypermediaConsumer
end
</pre>


h2. More Features

Be sure to check out the bundled features.

# *Coercion* transforms values to typed objects when parsing a document. Uses virtus.
# *Faraday* support, if you want to use it install the Faraday gem and require 'roar/representer/transport/faraday' and configure 'Roar::Representer::Feature::HttpVerbs.transport_engine = Roar::Representer::Transport::Faraday'

h2. What is REST about?

Making that system RESTful basically means

# The frontend knows one _single entry point_ URL to the REST services. This is @http://orders@.
# Do _not_ let the frontend compute any URLs to further actions.
# Showing articles, creating a new order, adding articles to it and finally placing the order - this all requires further URLs. These URLs are embedded as _hypermedia_ in the representations sent by the REST backend.

h2. Support

Questions? Need help? Free 1st Level Support on irc.freenode.org#roar !
We also have a "mailing list":https://groups.google.com/forum/?fromgroups#!forum/roar-talk, yiha!

h2. License

Roar is released under the "MIT License":http://www.opensource.org/licenses/MIT.