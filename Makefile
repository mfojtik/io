all: build

build: build-site

build-site:
	hugo --logLevel info --minify --gc --enableGitInfo -t hugo_theme_pickles --baseURL https://mfojtik.io/

clean:
	rm -rf ./{functions,public/*}
