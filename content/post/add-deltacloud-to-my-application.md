+++
title = "Mounting Deltacloud API into your application"
date = "2014-02-11T14:44:55+01:00"
+++

Yes, it's is possible through <code>Rack::Builder</code>:

<script src="https://gist.github.com/3371551.js?file=example.rb"></script>

You can use [thin](http://code.macournoyer.com/thin/) to start this application:

<code>$ thin -R config.ru start</code>

Now, the Deltacloud API is 'mounted' into your application and you can access
it on "/api" URL.
