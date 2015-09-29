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

## TO DO

this will change soon

XXX change to {name, minutes, limit, shortcut, fetcher}
AnyStore.createSubStore = (name, {minutes}) ->
AnyStore.createSubListStore = (name, {minutes, limit}, shortcut) ->
AnyStore.createHTTPStore = (name, {minutes}, fetcher) ->
AnyStore.createHTTPListStore = (name, {minutes, limit}, fetcher) ->


{name, minutes, limit, shortcut, fetcher}
{data, fetch, clear, watch}

Name is the AnyDb.publish name or the name of an object for localStorage using Meteor.

Minutes is how long to wait after clear before stopping the publications and/or deleting the data.

limit size of a page for list stores. This assumes the query of a store is an object and tags on a paging: {limit, skip} where limit is the size requested back and skip is  how many ay the beginnign you dont need. This is optimal. When doing http requests, you'll do something like this where limit.
XXX check this out exactly. terrilbe name. use pageSize or something. And pages.

shortcut gives you a an opportunity to find a document in another subscription which will shortcut your serve and provide immediate feedback.

fetcher is for aync functions like http.get.

data is the data currently in the cache. undefined or some collection if its a subscription (could be empty []), or whatever the async responds with.






LIMIT = Meteor.settings?.public?.sub_list_paging_inc || 10
MINUTES = Meteor.settings?.public?.sub_cache_minutes || 0

LIMIT = Meteor.settings.public?.http_list_paging_inc || 10
MINUTES = Meteor.settings.public?.http_cache_minutes || 0
