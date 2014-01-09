Private NPM Registry + Proxy Caching
====

What we want:
- A private NPM registry
- A proxy cache for the default npm registry
- Both of those things to work without anyone knowing anything

Solution:
- Use Kappa to proxy
- Hit the private couchdb instance
- Proxy the default npm registry through nginx

Quickstart:
====

CouchDB Setup:
----

Should work out of the box without any customization

- `brew install couchdb`
- `couchdb`

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
       }
     }

Include the files you just added to nginx.conf

    /usr/local/etc/nginx/nginx.conf

    # ...
    http {
        include conf.d/*.conf;
        include sites-enabled/*.conf;
        # ...

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
