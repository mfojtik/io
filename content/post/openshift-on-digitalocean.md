+++
title = "OpenShift v2 in DigitalOcean"
date = "2013-10-29T14:44:55+01:00"
+++

[DigitalOcean](http://digitalocean.com) is a new IaaS provider, similar to the
Amazon EC2. Comparing to the AWS, DigitalOcean is still a small fish in the IaaS
cloud market, but due to their offerring of SSD storage, they are attracting
more and more users.

[OpenShift](http://openshift.com) is a PaaS service, developed by [Red
Hat](http://redhat.com). OpenShift Origin, compared to
the [Heroku](http://heroku.com) is an OpenSource project, so you can install it on
your own machine and then run your own PaaS.

OpenShift Online infrastracture is built on top of Amazon EC2, so I want to try
how it would be to run my own PaaS, but on DigitalOcean. DigitalOcean, as I
mentioned before, offers SSD storage and also a datacenter in EU. So I created an
account and immediately got a $10 credit for my experiments using their coupon.

Once I logged into their administration console, I uploaded my public SSH
key to be able to login into the created 'droplets' (a 'droplet' is an equivalent to the
Amazon EC2 'instance').

For my experiments, I chosed the *Fedora 19 x86-64* image with 1GB of RAM, 1 CPU
and 30 GB of SSD storage. I also assigned my imported SSH key to it. It is also
important to set the hostname. I used *example*, but I think you should choose a
valid DNS name of the domain you own.

Once the droplet was created, I used SSH to connect and explore what needs to be
done to install OpenShift. First thing I discovered was that DigitalOcean
disables SELinux by default. Not a surprise, Amazon AWS does that as
well.
To enable it, I edited the <code>/etc/sysconfig/selinux</code> file:

```
SELINUX=enforcing
SELINUXTYPE=targeted
```

Now, to finish this change, you have to reboot the droplet. You can do that from
inside the droplet by typing <code>reboot</code> or from the administration
interface.

Once the droplet is back on again, verify that SELinux is properly enabled:

```
$ getenforce
Enforcing
```

To install OpenShift Origin, I used the [oo-install](https://github.com/tdawson/oo-install-scripts)
utility. This tool requires some packages to be installed on the base operating system:

```
$ yum -y install ruby unzip httpd-tools puppet bind
```

Now is the time to run `oo-install`:

```
$ sh <(curl -s http://oo-install.rhcloud.com)
```

The install script will ask you couple of questions, but I just keep the defaults.
There is a nice introduction [video](http://www.youtube.com/watch?v=T91Xc8rItek)
that explains various options you can use.

The install script will take some time to finish provisioning using Puppet and
during that process you will see couple errors. Some of them are OK to ignore,
and the others are already reported as bugs. So don't worry about them for now.

When the install script finishes, I recommend to reboot the droplet again to get
all services started correctly.

**UPDATE**: You can now skip to 'htpassword' command, as the workarounds below
are now fixed in oo-install script and not needed!

After reboot, I experiences some problems with the MongoDB. I think those are
caused by the Puppet script errors, but if this occurs to you, it is easy to
fix. Just edit the `/etc/mongodb.conf` and add these lines:

```
smallfiles=true
auth=true
```

Next problem I was experiencing was missing MongoDB account for the OpenShift
user. I think this is related to the previous problem, so hopefully get fixed
soon. You can add the user to MongoDB manually by:

```
$ mongo openshift_broker_dev --eval 'db.addUser("openshift", "PASSWORD")
```

The 'PASSWORD' is located in the `/etc/openshift/broker-dev.conf` file, so just
copy and paste it to the command line. Once you make these changes, restart the
mongodb service:

```
$ service mongod restart
```

Now is the time to verify that the OpenShift Broker is running correctly:

```
$ curl -k https://localhost/broker/rest/api
```

If you get JSON back, they you are done. If not, you need to go to
`/var/log/openshift/broker/httpd_logs` directory and check if everything is OK
there.

Next step is to create some OpenShift 'demo' user. To do so, you need to type
this command:

```
$ htpasswd -c /etc/openshift/htpasswd demo
```

Almost done. Now you should be able to run the `rhc setup` command. Use the
'demo' user credentials for authentication. You should also be able to create a
new applications.

I said almost done, because the applications you create will use the 'example'
domain. I haven't tried yet using my own domain, but I guess it should be easy.
All you need to do is to point the nameserver of your domain to the DigitalOcean
droplet and let the DNS server on the droplet manage things.
