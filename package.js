Package.describe({
  name: 'ccorcos:any-store',
  summary: 'A flux-like interface for ccorcos:any-db subscriptions and http endpoints',
  version: '0.0.1',
  git: 'https://github.com/ccorcos/meteor-any-store'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2');

  var packages = [
    'coffeescript',
    'ccorcos:any-db@0.1.0',
    'ccorcos:utils@0.0.1',
  ];

  api.use(packages);
  api.imply(packages);

  api.add_files([
    'globals.js',
    'http-store.coffee',
    'sub-store.coffee'
  ], 'client');

  api.export(['AnyStore'], 'client');
});
