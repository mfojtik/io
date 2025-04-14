+++
date = "2015-02-11T14:44:55+01:00"
title = "Publishing reveal.js presentations using OpenShift"
comments = true

+++

There are numerous reasons why I love creating my slides as a simple HTML page,
for example, I don't want to collect emails of people that ask me to send them
those, or I'm not worried that the format of my slides will not be recognized or
the presentation will look terrible on someone else's machine.<br/>
The other reason is that I simply hate all presentation software, including
Apple Keynote, LibreOffice Presenter or the one from Microsoft.  I'm a
programmer and given that I do prefer a simple and efficient approach. I hate
touching the mouse, and fighting with alignment of my images or the size of
fonts.<br/>
I think, personally, that slides should be simple and should not be the core of
a presentation; the story should be told by the presenter and not by his slides.

There are many good HTML frameworks for making slides, such as [deck.js](http://imakewebthings.com/deck.js/),
[slippy](https://github.com/Seldaek/slippy), [impress.js](http://bartaz.github.io/impress.js/#/bored) all heavily based on the HTML5, CSS3 and JavaScript.
To be honest, I haven't tried them all, but somehow I ended up using [reveal.js](http://lab.hakim.se/reveal-js). For me, this framework is very simple, follows the HTML5 new semantics, does not require any initial setup and the result looks awesome.<br/>
To make your presentation in reveal.js, you don't need to be HTML5 or
JavaScript wizard. If you know at least basic HTML, you should be fine.
You can start with a [index.html](https://github.com/hakimel/reveal.js/blob/master/index.html) file they have in their [Github repository](https://github.com/hakimel/reveal.js).

For now, you can fast-forward to the &lt;body;&gt; section of that file and
remove everything inside &lt;div class="slide"&gt;.  Each slide is represented
as an HTML5 &lt;section&gt; element, where you put the slide content. See the
examples in the original *index.html* for how to make your slides awesome. There
are many examples from basic text to complex code highlighting. The good thing
about reveal.js is it will make your slides look awesome on whatever resolution
or screen. They even look awesome on mobile browsers.

Now, this blog post is not about teaching you reveal.js, but it is more about
how you can publish your final presentation in
[OpenShift](https://www.openshift.com/). If you [sign
up](https://www.openshift.com/app/account/new) you get 3 free applications,
which is enough for storing 3 different presentations slides. Also you can use
one application to store multiple reveal.js presentations as they are just
simple HTML pages.

So to start, just clone the reveal.js Github repository which includes all require
libraries and assets:

```
git clone https://github.com/hakimel/reveal.js
```

Now, if you follow the [Full
setup](https://github.com/hakimel/reveal.js/#full-setup) instructions, you
install NodeJS and Grunt, which you can use to start your presentation locally.
We don't want to run Grunt or NodeJS in OpenShift to serve our static
presentation. For that, reveal.js comes with a simple Grunt task:

```
grunt zip
```

This will produce an archive with just enough JavaScript and CSS files and, of
course, with your index.html file. To make it online, you need to create a new
application in OpenShift:

```
rhc app create mypreso php-5.3
```

I used a PHP application, because that one is very small and the `git push`
command is super fast as it does not need to pull any dependencies or compile
assets. You can use whatever application type you want as we will just serve
static HTML files.  Next step is unzipping your presentation into the
[OpenShift](https://www.openshift.com) application folder and make it available
online:

```
unzip reveal-js-presentation.zip -d ./mypreso/php/
rm -f ./mypreso/php/index.php
cd mypreso && git add -A && git commit -m "My preso" && git push
```

When the last command has finished, you should have your presentation available at
<u>http://mypreso-YOURDOMAIN.rhcloud.com</u>. OpenShift supports custom domains
so you can easily set up your own domain name for place where you store
presentations, for example, <u>preso.mfojtik.im</u>.

