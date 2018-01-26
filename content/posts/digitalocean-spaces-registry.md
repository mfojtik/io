+++
date = "2018-01-26T14:44:48+01:00"
draft = false
title = "Use DigitalOcean Spaces as Docker Registry storage"

+++

DigitalOcean recently introduced [Spaces](https://blog.digitalocean.com/introducing-spaces-object-storage/) which is
their name for an Object Storage service similar to Amazon S3.

Since I run OpenShift on DigitalOcean, I was curios if instead of
pushing my images into Amazon S3 I can just use "in-house" service
that should give me better performance.

To make Spaces work for Docker Registry in OpenShift (or in Kubernetes)
you need to first create your "bucket" (aka "Space Name").

In DigitalOcean admin interface, click "Create" and then navigate
to bottom of the list and hist "Spaces". Now choose the bucket name
and the datacenter. For maximum performance, you should select the
same region where your droplets are running. You also want your
image blobs to be private, so select the "Private" option.

Now go to the "Spaces" page where you should see your newly created
space. Click 'Settings' and copy the space "Endpoint". In my case
the endpoint was *ams3.digitaloceanspaces.com*. We will need this
in next steps.

Next thing to acquire is API key and secret that Docker Registry
will use to connect to your space. To get them, go to the 'API'
page in DigitalOcean admin interface. On bottom. you should see
something like "Spaces access keys". Generate a new key and copy
out the key name and the secret.

Now we have all we need to configure the registry. First of, copy
out the current registry config from the registry pod:

```
$ oc exec docker-registry-4-wpffd -- /bin/bash -c 'cat /config.yml'
```

Save the output locally and then open editor. Locate the `storage`
section in the YAML file and replace it with this:


```yaml
storage:
  cache:
    blobdescriptor: inmemory
  s3:
    region: digitalocean-ams3
    regionendpoint: ams3.digitaloceanspaces.com
    bucket: SPACE_NAME
    accesskey: XXX
    secretkey: XXX
  delete:
    enabled: true
```

The `region` can be set to whatever. The `regionendpoint` however
must point to the "Endpoint" we got before.
The `bucket` must be set to the name of our space.

Now lets make registry use this new config:

```
$ oc secrets new registry-config config.yaml=registry-config.yaml

$ oc volume dc/docker-registry --add --type=secret \
    --secret-name=registry-config -m /etc/docker/registry/

$ oc set env dc/docker-registry \
    REGISTRY_CONFIGURATION_PATH=/etc/docker/registry/config.yaml
```

Now the registry should redeploy and new builds should push blobs
into your DigitalOcean space.