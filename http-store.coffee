debug = (->)
if Meteor.settings.public?.log?.http_store
  debug = console.log.bind(console, 'http-store')

LIMIT = Meteor.settings.public?.http_list_paging_inc || 10
MINUTES = Meteor.settings.public?.http_cache_minutes || 0

# {data, fetch, clear, watch} = store.get(query)
AnyStore.createHTTPStore = (name, options={}, fetcher) ->
  if _.isFunction(options)
    fetcher = options
    options = {}

  store = {}
  store.cache = {}
  store.minutes = options.minutes or MINUTES

  store.newItem = (query) ->
    check(query, Object)
    key = U.serialize(query)
    # this item represents some cached value that as async fetched
    item = {query}
    # count the number of places this item is being used. only clear
    # when no one is using it anymore
    item.count = 0
    # watch this item for changes
    item.dispatcher = U.createDispatcher()
    item.watch = item.dispatcher.register
    item.changed = -> item.dispatcher.dispatch(item.respond())
    # timer to clear the item
    item.timerId = undefined
    item.data = undefined
    # register this item with the cache, and delete it from the cache
    # when appropriate.
    store.cache[key] = item
    item.delete = ->
      delete store.cache[key]
    # if no one is using this item, then we can set a timeout to delete
    # the item from the cache
    item.clear = ->
      item.count--
      if item.count is 0
        item.timerId = Meteor.setTimeout(item.delete, store.minutes*1000*60)
    # keep track of how many people have called .get without .clear
    item.get = ->
      item.count++
      Meteor.clearTimeout(item.timerId)
      item.respond()
    # the same interface for .get .fetch and .watch
    item.respond = ->
      data: R.clone(item.data)
      clear: item.clear
      watch: item.watch
      fetch: item.fetch
    # we dont want to fetch multiple times in parallel, so we want to keep
    # track if we're waiting for a result and only fetch once.
    item.fetching = false
    item.callbacks = []
    item.fetch = (callback) ->
      item.callbacks.push(callback)
      unless item.fetching
        item.fetching = true
        fetcher query, (data) ->
          item.data = data
          item.callbacks.map (f) -> f?(item.respond())
          item.changed()
          item.callbacks = []
          item.fetching = false
    return item

  store.get = (query) ->
    key = U.serialize(query)
    item = store.cache[key]
    unless item
      item = store.newItem(query)
    return item.get()

  return store

AnyStore.createHTTPListStore = (name, options={}, fetcher) ->
  store = AnyStore.createHTTPStore(name)

  if _.isFunction(options)
    fetcher = options
    options = {}

  store.minutes = options.minutes or MINUTES
  store.limit = options.limit or LIMIT


  store.newListItem = (query) ->
    item = store.newItem(query)
    item.limit = store.limit
    item.skip = 0
    item.respond = ->
      data: R.clone(item.data)
      clear: item.clear
      watch: item.watch
      fetch: item.fetch unless (item.data and (item.data.length < item.limit + item.skip))
    item.fetch = (callback) ->
      item.callbacks.push(callback)
      unless item.fetching
        item.fetching = true
        if (item.data and (item.data.length >= item.limit + item.skip))
          item.skip += item.limit
        q = R.clone(query)
        q.paging =
          limit: item.limit
          skip: item.skip
        fetcher q, (data) ->
          item.data = (item.data or []).concat(data or [])
          item.callbacks.map (f) -> f?(item.respond())
          item.changed()
          item.callbacks = []
          item.fetching = false
    return item

  store.get = (query) ->
    key = U.serialize(query)
    item = store.cache[key]
    unless item
      item = store.newListItem(query)
    return item.get()

  return store
