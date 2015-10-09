debug = (->)
if Meteor.settings.public?.log?.sub_store
  debug = console.log.bind(console, 'sub-store')

LIMIT = 10
MINUTES = 1

AnyStore.createSubStore = (name, options={}, shortcut) ->
  store = AnyStore.createHTTPStore(name)

  if _.isFunction(options)
    shortcut = options
    options = {}

  store.minutes = options.minutes or MINUTES

  store.newSubItem = (query) ->
    item = store.newItem(query)
    item.sub = undefined
    key = U.serialize(query)

    item.fetch = (callback) ->
      debug 'fetch', name
      item.callbacks.push(callback)
      unless item.fetching
        item.fetching = true
        debug 'subscribe', name
        AnyDb.subscribe name, query, (sub) ->
          debug 'ready', name
          item.sub?.stop()
          item.sub = sub
          item.data = sub.data or []
          item.callbacks.map (f) -> f?(item.respond())
          item.changed()
          item.callbacks = []
          item.fetching = false
          sub.onChange (data) ->
            item.data = data
            item.changed()

    # latency compensation
    item.update = (transform) ->
      debug 'update', name
      item.data = transform(R.clone(item.data))
      item.changed()

    # stop the subscription
    item.delete = ->
      debug 'clear', name
      delete store.cache[key]
      item.sub?.stop()

    return item

  store.update = (condition, transform) ->
    for key, item of store.cache
      query = U.deserialize(key)
      if condition(query)
        item.update(transform)

  store.get = (query) ->
    key = U.serialize(query)
    item = store.cache[key]
    unless item
      item = store.newSubItem(query)
    return item.get()

  if shortcut
    return AnyStore.shortcut(store, shortcut)

  return store


AnyStore.createSubListStore = (name, options={}, shortcut) ->
  store = AnyStore.createSubStore(name)

  if _.isFunction(options)
    shortcut = options
    options = {}

  store.minutes = options.minutes or MINUTES
  store.limit = options.limit or LIMIT

  store.newSubListItem = (query) ->
    item = store.newSubItem(query)
    item.limit = store.limit
    item.skip = 0

    item.respond = ->
      data: R.clone(item.data)
      clear: item.clear
      watch: item.watch
      fetch: item.fetch unless (item.data and (item.data.length < item.limit + item.skip))

    item.fetch = (callback) ->
      debug 'fetch', name
      item.callbacks.push(callback)
      unless item.fetching
        item.fetching = true
        if (item.data and (item.data.length >= item.limit + item.skip))
          item.skip += item.limit
        q = R.clone(query)
        q.paging =
          limit: item.limit
          skip: item.skip
        debug 'subscribe', name
        AnyDb.subscribe name, q, (sub) ->
          debug 'ready', name
          item.sub?.stop()
          item.sub = sub
          item.data = sub.data or []
          item.callbacks.map (f) -> f?(item.respond())
          item.changed()
          item.callbacks = []
          item.fetching = false
          sub.onChange (data) ->
            item.data = data
            item.changed()

    return item

  store.get = (query) ->
    key = U.serialize(query)
    item = store.cache[key]
    unless item
      item = store.newSubListItem(query)
    return item.get()

  if shortcut
    return AnyStore.shortcut(store, shortcut)

  return store

# shortcut the store to find some data in a different subscription!
# not that all documents are kept in sync on the client regardless of
# which ones are refreshed and which ones arent.
AnyStore.shortcut = (store, func) ->
  get = store.get
  store.get = (query) ->
    result = get(query)
    unless result.data?.length > 0
      data = func(query).filter(U.isPlainObject).map(R.assoc('shortcut', true))
      data.shortcut = true
      result.data = data
    return result
  return store
