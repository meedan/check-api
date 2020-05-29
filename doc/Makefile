# This Makefile generates all API documentation under doc/
# Run it this way: cd doc/ && make
# You can remove the files by running: cd doc/ && make clean
# Dependencies: GNU Make, Inkscape and PDF LateX, besides the API dependencies

INKSCAPE = inkscape -b 'rgb(255, 255, 255)'
RAKE = bundle exec rake
BEXEC = bundle exec

all: controllers_brief.png controllers_complete.png models_brief.png models_complete.png api.txt licenses.csv api-docs.json api.md graphql.md structure.sql

controllers_brief.png: controllers_brief.svg
	$(INKSCAPE) --export-png='controllers_brief.png' controllers_brief.svg

controllers_brief.svg:
	$(BEXEC) railroady -C -b -c ../config/environment | dot -Tsvg > controllers_brief.svg

controllers_complete.png: controllers_complete.svg
	$(INKSCAPE) --export-png='controllers_complete.png' controllers_complete.svg

controllers_complete.svg:
	$(BEXEC) railroady -C -c ../config/environment | dot -Tsvg > controllers_complete.svg

models_brief.png: models_brief.svg
	$(INKSCAPE) --export-png='models_brief.png' models_brief.svg

models_brief.svg:
	$(BEXEC) railroady -M -s app/models/annotations/*,app/models/*.rb -b -c ../config/environment | dot -Tsvg > models_brief.svg

models_complete.png: models_complete.svg
	$(INKSCAPE) --export-png='models_complete.png' models_complete.svg

models_complete.svg:
	$(BEXEC) railroady -M -s app/models/annotations/*,app/models/*.rb -c ../config/environment | dot -Tsvg > models_complete.svg

api.txt:
	echo "API Endpoints - `LANG=en_US date --utc`" > api.txt
	$(RAKE) routes | sed 's/.*\([PGD]\)/\1/g' | sed 's/(.:format).*//g' | grep -v Pattern | sort | nl >> api.txt

licenses.csv:
	$(RAKE) gem:licenses:csv['doc/licenses.csv']

api-docs.json:
	$(RAKE) swagger:docs && ln -s ../public/api-docs.json .

api.md: api-docs.json
	$(RAKE) swagger:docs:markdown

structure.sql:
	$(RAKE) db:structure:dump && mv ../db/structure.sql .

graphql.md:
	graphql-markdown ../public/relay.json > graphql.md

clean:
	rm -f controllers_brief.png controllers_complete.png models_brief.png models_complete.png api.txt licenses.csv api-docs.json api.md graphql.md structure.sql
	apt-get update && apt-get install graphviz postgresql-client inkscape
	npm i -g graphql-markdown
