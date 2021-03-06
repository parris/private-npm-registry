Private NPM Registry + Proxy Caching
====

What we want:
- A private NPM registry
- A proxy cache for the default npm registry
- Both of those things to work without anyone knowing anything

Solution:
- Use Kappa to proxy
- Hit the private reggie or couchdb instance
- Proxy the default npm registry through nginx

Other options: https://github.com/terinjokes/docker-npmjs

Quickstart:
====

You need an NPM registry server. You can either use reggie or set one up yourself via couchdb.

Reggie Setup (optional/way easier)
----

- Details at: https://npmjs.org/package/reggie
- `npm install -g reggie`
- `reggie-server -d ~/.reggie`
- Make sure to replace the first line in config.json's paths array with the reggie url

CouchDB Setup (optional):
----

Should work out of the box without any customization

- Build via instructions from: https://github.com/iriscouch/build-couchdb
- Setup couchdb using these instructions: https://github.com/npm/npmjs.org
- No need to replicate so stop before those instructions
- Make sure to replace the first line in config.json's paths array with the couch db url (according to npm)
- I found this pretty hard to set up. You may also want to peak at the docker project's setup

Nginx Setup:
----

This is what worked for me. Largely influenced by: http://eng.yammer.com/a-private-npm-cache/

- Get homebrew
- `brew tap marcqualie/nginx && brew install nginx-full` (this gives you all needed modules)
- sudo mkdir -p /var/cache/npm/data

Create a cache zone

    /usr/local/etc/nginx/conf.d/npm.conf

    # this is the npm zone, things stay active for 3 days
    proxy_cache_path /var/cache/npm/data levels=1:2 keys_zone=npm:20m max_size=1000m inactive=3d;
    proxy_temp_path /var/cache/npm/tmp;

Add a site config

    /usr/local/etc/nginx/sites-enabled/npm.conf

    server {
       listen 12345;
       server_name localhost;
       location / {
         proxy_pass https://registry.npmjs.org/;
         proxy_cache npm;
         proxy_cache_valid 200 302 3d;
         proxy_cache_valid 404 1m;
         # npm adds "_resolved": 'registry.npmjs.org/xyz.tgz" to package.json files
         # this rewrites things correctly
         sub_filter 'registry.npmjs.org' 'localhost:12345';
         sub_filter_once off;
         sub_filter_types application/json;
       }
     }

Include the files you just added to nginx.conf

    /usr/local/etc/nginx/nginx.conf

    # ...
    http {
        include conf.d/*.conf;
        include sites-enabled/*.conf;
        # ...

- Move your default nginx.conf port off of 8080 to something else
- Restart nginx, `sudo nginx -s reload`, or just `sudo nginx`
- Visit http://localhost:12345/npm to confirm the proxy works
- Turn off wifi and visit that same URL!

Kappa Setup
----

- Edit config.json. At the very least you should replace
  `http://localhost:12345` with your registry's host name
- Run `npm start` in this repo

NPM Setup on client machines
----

- `npm config set registry http://localhost:1337/`
- Try installing something

This adds `registry = http://localhost:1337` to your .npmrc file in your home directory.

After all that you should not only be able to `npm publish`, which actually only publishes to your private registry, but you should also be able to install packages from the normal npm registry. If the repo already exists in the nginx cache you won't even make a request npm headquarters.


License Info
----
[![License](https://i.creativecommons.org/p/zero/1.0/80x15.png "License")](http://creativecommons.org/publicdomain/zero/1.0/)

To the extent possible under law, Parris Khachi has waived all copyright and related or neighboring rights to Private NPM Registry + Proxy Caching. This work is published from: United States.
