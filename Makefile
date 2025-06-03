build:
	docker build -t zot-chart-extractor-test .


test:
	docker run --rm -it -v "$PWD":/workspace zot-chart-extractor-test ./zot-chart-tool.sh scan -p ./zot
