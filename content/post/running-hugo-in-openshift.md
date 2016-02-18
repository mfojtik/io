+++
title = "How to run Hugo on OpenShift v3"
date = "2016-02-18T14:44:55+01:00"
comments = true
+++

In my [previous](http://mifo.sk/post/openshift-v3-digitalocean/) post I
described how I transitioned myself into the *container era* by installing the
OpenShift v3 in [DigitalOcean](http://digitalocean.com) and containerizing my
applications. This post will describe how I moved from my previous blog engine
to [Hugo](http://gohugo.io/) engine.

My previous blog engine was a hand-written [Sinatra](http://sinatrarb.com)
application that was just serving Markdown files. Everything else was just
Javascript. While that seems pretty decent and minimal, in fact it is not. The
[Ruby](https://github.com/openshift/sti-ruby) Docker image is something around
430MB and while 90% of that is just `centos:7`, it is still 'too much'. Also the
ruby itself is pretty memory hungry and DigitalOcean is not really about having
extra memory to spare.

I was looking into something more minimal, preferably [Go](https://golang.org/)
based static web site generator, so I can just copy the static binary into a
minimal Docker image and have really small image with my blog in the end.

Then I found [hugo](http://gohugo.io/). It is fast and flexible static site
generator, written by [spf13](http://spf13.com/), a guy who is behind popular
[cobra](https://github.com/spf13/cobra) and many other successfull Go projects.

Hugo is **very** simple to use tool, you can check the
[tutorial](http://gohugo.io/overview/quickstart/), and what it basically does is
converting the Markdown files into static HTML pages. It also comes with
countless themes you can start from.  As a bonus, it also comes with very fast
HTTP server, which is built-in into its binary.

Now, how to configure OpenShift to automatically build and deploy my blog?
First, I have to create [Github
repository](https://github.com/mfojtik/hugo-blog) and upload my content there.

Then I need to craft the
[Source-To-Image](https://github.com/openshift/source-to-image) builder image
that will take the source (content above) and produce the Docker image that will
contain hugo server and my content.

The source for the image is [here](https://github.com/mfojtik/sti-hugo).
Some points about this image:

* It uses `FROM golang:alpine` which is a new official [Go builder image](https://hub.docker.com/_/golang/) based on minimal Alpine Linux.
* It compiles hugo from the source, giving me the latest master version.
* I remove all unnecesary packages after the build to keep the final image small.
* Image log to a pipe which is streamed to the standard output, so I can watch the logs in container log.
* The `assemble` script compiles the blog content to verify that nothing is broken.
* You can change the theme by setting `HUGO_THEME` variable.
* And you should change `HUGO_BASE_URL` as well ;-)

To create my blog, I run the following command:

```
$ oc new-app mfojtik/hugo~https://github.com/mfojtik/hugo-blog
```

That's it! The resulting image is ~200 MB. It also consume almost no memory, so
I can scale it up on DigitalOcean without adding extra node to get more memory.

I also configured the Github hooks to automatically trigger the build of this
blog when I push to the `master` branch. Which is how I publishing this article.
Jut by pushing it to github. And you can see the result here :-)
