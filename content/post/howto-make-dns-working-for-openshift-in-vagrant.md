+++
title = "Resolve application DNS in OpenShift v2"
date = "2013-02-11T14:44:55+01:00"
+++

If you followed this [OpenShift howto](https://www.openshift.com/wiki/installing-openshift-origin-using-vagrant-and-puppet)
and you installed OpenShift Origin using the [Puppet](https://github.com/openshift/puppet-openshift_origin/archive/master.zip)
modules in [Vagrant](http://www.vagrantup.com/), then maybe you come across with
the problem how you can access your OpenShift applications outside the Vagrant
virtual machine. By default OpenShift vagrant file will forward ports 80, 443,
22 and 53 to your host machine. This allows <code>vagrant ssh</code> to work and
also allows you to access OpenShift Apache service using <code>curl
http://localhost:8080</code>.

But as you know, when you create new application via `rhc app create`, then it
gets its own domain name. Unfortunately this domain name is not accessible from
the host and it will work only on the Vagrant machine. To be able to access your
applications outside Vagrant, you need to do following:

1. Open the `Vagrantfile` and change the DNS port `53` to `5350`. Virtualbox
   **will not forward** the port 53, because 1) you need UDP, not TCP, 2)
   non-privileged users are not allowed to forward ports <1024.
   So the line in VagrantFile should looks like this:
   ```
   config.vm.forward_port 53, 5350, :protocol => :udp
   ```

2. Now run `vagrant reload` and wait for changes to be applied. You can verify
   that the DNS server is working by:
   ```
   $ dig @127.0.0.1 -p 5350 broker.example.com
   ```

3. When the machine is ready, start the dnsmasq on host:

   ```
   $ sudo dnsmasq --no-daemon --server="/example.com/127.0.0.1#5350"
   ```

   **NOTE**: *The domain 'example.com' is the domain used by the OpenShift default Vagrant
             machine. If you use different domain name, change this.*

   **NOTE**: If you have libvirtd installed and running, you might need to kill
             existing dnsmasq processes.

4. When dnsmasq is running, add it to the `/etc/resolv.conf` as the very first nameserver:
   ```
   nameserver 127.0.0.1
   ```
   Now you can verify, if the DNS is working by:
   ```
   $ ping broker.example.com
   ```

5. The last change will require modifying the Apache configuration in Vagrant
   machine. For that run:
   ```
   $ cd origin/
   $ vagrant ssh
   ```

   Then open the `/etc/httpd/conf.d/openshift_route.include` file and add these
   rules around line 45:
   ```
   RewriteCond %{HTTP_HOST} ^(.*):8080$ [NC]
   RewriteRule ^.*$ - [E=V_MATCH_HOST:%1,NS]
   ```
   Then reload the Apache service:
   ```
   $ service httpd reload
   ```

6. Done! Now you can access your apps from the host machine. All you need to do
   is to add port 8080 into URL:

   ```
   $ curl http://test-mfojtik.example.com:8080
   ```
