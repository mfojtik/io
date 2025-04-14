all: build

build: build-site

build-site:
	hugo --logLevel info --minify --enableGitInfo -t hugo-theme-cleanwhite --baseURL https://mfojtik.io/

build-local:
	docker build -t mfojtik/io:test . &&  docker run -p 8080:80 mfojtik/io:test

clean:
	rm -rf ./{functions,public/*}
