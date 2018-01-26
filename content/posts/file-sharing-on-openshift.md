+++
title = "Simple file hosting on OpenShift"
date = "2016-03-11T14:44:55+01:00"
+++

I often need to upload something really fast to make it available
for somebody. That includes PDF files with my presentations, error logs,
pictures or random meme pictures I can then link to.

In 99% of cases all I want is to simply `scp` the file into my DigitalOcean
instance and run some small web server serving the directory where I uploading
the file to public.

To make this possible on OpenShift v3 that I run, following was needed:

1. A persistent volume where I can just upload the files (`/data/files`)
2. A Docker image with a web server
3. A pod that run this image
4. A persistent volume claim attached to this pod

So I started exploring Github and I found [ran](https://github.com/m3ng9i/ran).
Small web server intended to serve static files, written in Go so to run it
you just have to execute the static binary.

So I have to write a Dockerfile first:

```
FROM alpine:3.3
ADD https://github.com/m3ng9i/ran/releases/download/v0.1.2/ran_linux_amd64.zip /app/
RUN cd /app && unzip ran_linux_amd64.zip && rm -rf ran_linux_amd64.zip && mkdir /data
EXPOSE 8080
WORKDIR /app
VOLUME /data
CMD ["/app/ran_linux_amd64", "-p=8080", "-r=/data", "-l=true"]
```

I'm using alpine here, because I already use `golang:alpine` for this blog, so I have
that image already available on all nodes I have.

Next step is build the Docker image:

`$ docker build -t docker.io/mfojtik/ran .`

And then push this image to DockerHub:

`$ docker push docker.io/mfojtik/ran`

Now to run this Docker image in OpenShift, I first created a new project called `file`.
Then I ran following command:

`$ oc new-app docker.io/mfojtik/ran -l app=file`

What this command does is it will read the Docker image metadata and create bunch of
OpenShift/Kubernetes resources for me, such as Service, ImageStream, DeploymentConfig, etc.

After I ran this command, I navigated to the OpenShift web console and added Route for the
"ran" service, so I can access it externally. I also added the CNAME record in DigitalOcean.

Now, the service is up, route is working, but since the Pod I use is running "ran" in an
ephemeral container, I need to attach a volume to it, pointing to my NFS server.

First, I created new PersistentVolume as an admin:

```
kind: "PersistentVolume"
metadata:
  name: "files-upload"
spec:
  capacity:
    storage: "2Gi"
  accessModes:
    - "ReadWriteOnce"
  nfs:
    path: "/data/files"
    server: "178.xxx.xxx.xxx"
  persistentVolumeReclaimPolicy: "Retain"
```

And then I created the PersistentVolumeClaim:

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: files-upload
spec:
  accessModes:
    - ReadWriteOnce
  volumeName: files-upload
  resources:
    requests:
      storage: 2Gi
```

Now, back to the web console, I have to edit the Deployment, to remove the EmptyDir
volume, that was created automatically. After that, I can click on "Attach Storage"
and simply attach the PersistentVolume to `/data` volume.

Done :-) I can now simply `scp foo file.mifo.sk:/data/files` and the file will be available
immediately on http://file.mifo.sk for download.
