
(global => {
  'use strict';

  // Load the sw-tookbox library.
  importScripts('sw-toolbox.js'); // Update path to match your own setup

  global.toolbox.options.cache.name = 'sw-cache-<%= hash %>';

  //its variable replaced by node script
  global.toolbox.precache(['/', <%= precache %>]);


  //Turn on debug logging, visible in the Developer Tools' console.
  //global.toolbox.options.debug = true;

  // By default, all requests that don't match our custom handler will use the
  // toolbox.networkFirst cache strategy, and their responses will be stored in
  // the default cache.
  global.toolbox.router.default = global.toolbox.networkFirst;

  //global.location = {};

  // Boilerplate to ensure our service worker takes control of the page as soon
  // as possible.
  global.addEventListener('install', event => event.waitUntil(global.skipWaiting()));

  global.addEventListener('activate', event => event.waitUntil(global.clients.claim()));

})(self);
