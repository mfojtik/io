+++
title = "Running OpenShift v3 on DigitalOcean"
date = "2016-02-12T14:44:55+01:00"
comments = true
+++

I'm running this blog (and couple other blogs and side-projects) on
[DigitalOcean](http://digitalocean.com) since 2014. Till this week, my VM looked
like a typical VM from 90': mysql server, nginx+php, irssi. Nothing special
about that setup really. But, since I'm currently busy working on the [OpenShift
v3](http://github.com/openshift/origin) platform, I convinced myself to upgrade
to the "containers era".

This blog post describes the steps I've take to run the latest OpenShift v3
platform and next post will explain how I containerized the apps I ran (this
site included).

The first thing I've to get familiar myself was this
[repository](https://github.com/openshift/openshift-ansible/blob/master/README_origin.md)
that contains the
[OpenShift](https://docs.openshift.org/latest/install_config/install/advanced_install.html)
[Ansible](https://www.ansible.com/) installer.

Since I love to automatize things and I don't have that much free time to
configure everything myself, I really fall in love with this installation
system. It does not require anything special on the VM, except password-less SSH
authentication.  And because DigitalOcean already have my SSH key, that is
no-op.

The next step was to actually create a VM that I will host my OpenShift v3. I
choosed the 2GB/2CPU one, which is a little bit more expensive (~$20/month), but
it gives me a little bit more space for running containers. It also comes with
40GB of SSD storage, which is perfectly fine for some simple apps and I can use
the SSD as a swap if I really need to.

So the VM is up and running. I gave it name `alpha.mifo.sk`. The reason is that
for now, I'm going with all-in-one installation, but in future, who knows...  I
selected the CentOS 7.1 box, which should be perfectly file and supported by the
Ansible installer and the OpenShift v3 itself.  The only change I dit to that VM
was to fix the `/etc/hosts` file:

```
178.62.231.166 alpha.mifo.sk
```

For some reason, the DNS name is assigned to point to `127.0.0.1`, which might
cause troubles with Ansible.

Now it is time to create the Ansible inventory file. I created mine `./alpha/hosts`
file with the following content:

```
[OSEv3:children]
masters
nodes
etcd

[OSEv3:vars]
ansible_ssh_user=root
deployment_type=origin
openshift_node_kubelet_args={'max-pods': ['40'], 'image-gc-high-threshold': ['90'], 'image-gc-low-threshold': ['80']}

[masters]
alpha.mifo.sk openshift_ip=178.62.231.166 openshift_hostname=alpha.mifo.sk openshift_public_ip=178.62.231.166 openshift_public_hostname=alpha.mifo.sk

[nodes]
alpha.mifo.sk openshift_ip=178.62.231.166 openshift_hostname=alpha.mifo.sk openshift_public_ip=178.62.231.166 openshift_public_hostname=alpha.mifo.sk

[etcd]
alpha.mifo.sk openshift_ip=178.62.231.166 openshift_hostname=alpha.mifo.sk openshift_public_ip=178.62.231.166 openshift_public_hostname=alpha.mifo.sk
```

This configuration basically says:

* I want **all-in-one VM** that runs the "master" but also acts as a "node" in the
  OpenShift cluster.
* I want the [etcd](https://coreos.com/etcd/docs/latest/) to run on the same VM as well.
* The node should have limit for maximum pods set to 40 (just a pre-caution...)

Now it is time to clone the Ansible installer GIT repository:

```
$ git clone https://github.com/openshift/openshift-ansible
```

And finally proceed with the installation:

```
$ cd openshift-ansible
$ ansible-playbook playbooks/byo/config.yml --inventory ~/alpha/hosts
```

You can now watch the Ansible installation output (should take less than
~5 minutes). After it finishes, the OpenShift Console should be available
at `https://alpha.mifo.sk:8443` (replace with your hostname...).

After you login to the console, you will notice that it is not really the
securest place in the world. OpenShift basically allows any user to login and it
will automatically create new users. Not cool for "production" use.

Fortunatelly, OpenShift offers pretty long list of [supported identity
providers](https://docs.openshift.org/latest/install_config/configuring_authentication.html).
, so I choosed the Github one, which is really easy to configure.

After I configured it and restarted the origin-master systemd service, I noticed
another odd thing. Now when I'm going to OpenShift login page, I'm redirected to
Github application page for authentication. After I allow my Github app to use
my own Github account informations, I get redirected back to OpenShift console
and I'm logged in.

So what is odd here? Any Github user can now login to my OpenShift console! To
fix this, you have to set the `mappingMethod` property in configuration to
"lookup" (and restart openshift server).

By doing that, only users that logged in already will have access to OpenShift
console, which is fine for me. If I want to give access to another user, I can
just manually create it in OpenShift, or temporarely open logging by switching
to "claim".

Another post-installation step, that I did for my OpenShift installation was to
configure NFS server. Why? Because I want to be able to use the persistent
volumes in my containers (like database...). You can read how to setup
persistent storage in OpenShift in the [official
documentation](https://docs.openshift.org/latest/install_config/persistent_storage/persistent_storage_nfs.html)

The last thing I noticed after installation, was that the "node" was in
"un-schedulable" state. That means, no container are allowed to schedule on this
VM. To fix that, you have to run:

```
$ oadm manage-node alpha.mifo.sk --schedulable=true
```

Now the containers will start to launch and you are good to go create your
applications and deploy some services.

Next time, I will explain how I containerized this blog and deployed it in
OpenShift.
