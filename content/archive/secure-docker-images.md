+++
title = "Building secure Docker images"
date = "2016-04-07T14:44:55+01:00"
+++

A lot was written about [Docker](http://docker.org) security and how to run
Docker in a secure way. But there are not many articles describing how to write
Docker images, which are secure and easy to maitain. According to [this
article](http://www.infoq.com/news/2015/05/Docker-Image-Vulnerabilities) over
30% of the official Docker images published to Docker Hub contain some security
vuleabilities.

Here is my list of rules to follow when I'm building Docker images:

* **Do not run as "root"** - almost every image published on Docker hub does not
    set the `USER` instruction, which means they expect to be run as the `root`
    user. Where Docker provides some level of isolation, it is never bad idea to
    add yet another barrier for the malicious process to escape from the Docker
    container. For example in [OpenShift](http://github.com/openshift/origin)
    the default rule is set to disallow running containers as "root" and instead
    the container is started using random user ID.
    You can create non-privileged user in Dockerfile and use `USER foo`
    instruction at the end. Then make writeable only those directories you know
    the process running in the container is going to write to.

* **Use nss_wrapper if necessary** - if the process that run inside container
    really need to have UID to user name mapping, you can use [nss_wrapper](https://cwrap.org/nss_wrapper.html)
    to provide it.

* **Do not update the base image** - this is not that much security related, but
    you should learn to trust the base image provider. It is really his job to
    keep the base image content up-to-date for you. That also include all
    security fixes, testing, verifications, etc.. If you do update the software
    in your image yourself, you might, by accident pull some insecure/untested bits (it
    happens...). If the base Docker image provider does not update the base image
    frequently, maybe it is time to move to another base image.

* **Avoid curl|bash** - this is **always** a bad idea. You really don't have a control
    over the shell script that you pull from the internet.

* **The `:latest` is not a version** - you should version your image properly.
    Use Docker [tags](https://docs.docker.com/engine/reference/commandline/tag/) to do so.

* **It is better to freeze dependencies** - instead of always pulling the
    "latest" versions of Ruby gems, Python modules, NPM modules, etc. it is
    better to explicitly lock the versions your application is using when
    building the image. Also it is sometimes better to vendor them in same
    repository where you have your Dockerfile (how often is rubygems.org down?).
    Following this rule means you will be able to consistently rebuild the image
    without ending up with different versions.

* **Verify content you download** - [gnupg](https://www.gnupg.org/) is your friend in case you using `ADD`
    from a HTTP(S) location. Make sure what you downloaded is really what you
    expected.

* **Do not rely on squashing** - scary right? You add a
    secret password file in one layer, use it in another layer and remove it in third
    layer. Now you squash the final image to minimize the size of layers and the
    secret password file is back. Always verify that before you pushing content
    to Docker hub.
