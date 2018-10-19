all: build

build: build-site build-hello

build-site:
	hugo -v -t hugo_theme_pickles --baseURL https://mfojtik.io/

build-hello:
	mkdir -p ./functions
	go get ./...
	go build -o functions/hello ./lambda/hello

clean:
	rm -rf ./{functions,public/*}
