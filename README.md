# Meteor Any-Store

This package provides a client-side interface for `ccorcos:any-db` that's responsible for subscription caching and latency compensation. As a bonus, it also provides caching for HTTP fetching.

[Check out this article](https://medium.com/p/d2e01e708f31/).

# Getting Started

Simply add this package to your project:

    meteor add ccorcos:any-store

# API

A store provides a generic interface for working with data. It works kind of like this:

```coffee
{data, fetch, clear, watch} = store.get(query)
if data
  # here's your data found in the cache
  listener = watch ({data, fetch, clear, watch}) ->
    # here's some new data onChange
  # when you're done listening...
  listener.stop()
else
  fetch ({data, fetch, clear, watch}) ->
    # here's your data async
    listener = watch ({data, fetch, clear, watch}) ->
      # here's some new data onChange
    # when you're done listening...
    listener.stop()
# when you're with this data
clear()
```

You need to call clear once for every time you call get, else you'll have a memory leak in your cache. When you call clear, a timer will be set to remove the data from the cache unless you call get again.

You can create a store for a `ccorcos:any-db` publication like this:

```coffee
AnyStore.createSubStore(name, {minutes}, shortcut)
AnyStore.createSubListStore(name, {minutes, limit}, shortcut)
AnyStore.createHTTPStore(name, {minutes}, fetcher)
AnyStore.createHTTPListStore(name, {minutes, limit}, fetcher)
```

Minutes defaults to 1 and limit defaults to 10. The subscription name pairs with an AnyDb publication. And shortcut is an optional function to look for the result of this query in another subscription so you don't have to wait for a round trip to the server. For example, maybe you're querying for a user, but that user was just clicked on in a list from another subscription. The shortcut allows you to display that user immediately by searching for that user in the user list subscriptions.

For HTTP stores, you have an async fetcher function that works well with the HTTP Meteor package.

Its also important that your query is a plain object. This allows AnyStore to tag on a paging:{limit,skip} property for paging.
