# This Makefile generates all API documentation under doc/
# Run it this way: cd doc/ && make
# You can remove the files by running: cd doc/ && make clean
# Dependencies: GNU Make, Inkscape and PDF LateX, besides the API dependencies

INKSCAPE = inkscape -b 'rgb(255,255,255)'
RUNNER = bundle exec rails
BEXEC = bundle exec

all: controllers_brief.png controllers_complete.png models_brief.png models_complete.png api.txt licenses.csv api-docs.json api.md structure.sql

controllers_brief.png: controllers_brief.svg
	$(INKSCAPE) --export-png='controllers_brief.png' controllers_brief.svg

controllers_brief.svg:
	$(BEXEC) railroady -C -b -c ../config/environment -s ../app/controllers/*.rb,../app/controllers/api/v1/*.rb | sed 's/bgcolor="none"/bgcolor="transparent"/g' | dot -Tsvg > controllers_brief.svg

controllers_complete.png: controllers_complete.svg
	$(INKSCAPE) --export-png='controllers_complete.png' controllers_complete.svg

controllers_complete.svg:
	$(BEXEC) railroady -C -c ../config/environment -s ../app/controllers/*.rb,../app/controllers/api/v1/*.rb | sed 's/bgcolor="none"/bgcolor="transparent"/g' | dot -Tsvg > controllers_complete.svg

models_brief.png: models_brief.svg
	$(INKSCAPE) --export-png='models_brief.png' models_brief.svg

models_brief.svg:
	$(BEXEC) railroady -M -s ../app/models/annotations/*,../app/models/*.rb -b -c ../config/environment | sed 's/bgcolor="none"/bgcolor="transparent"/g' | dot -Tsvg > models_brief.svg

models_complete.png: models_complete.svg
	$(INKSCAPE) --export-png='models_complete.png' models_complete.svg

models_complete.svg:
	$(BEXEC) railroady -M -s ../app/models/annotations/*,../app/models/*.rb -c ../config/environment | sed 's/bgcolor="none"/bgcolor="transparent"/g' | dot -Tsvg > models_complete.svg

api.txt:
	echo "API Endpoints - `LANG=en_US date --utc`" > api.txt
	$(RUNNER) routes | sed 's/.*\([PGD]\)/\1/g' | sed 's/(.:format).*//g' | grep -v Pattern | sort | nl >> api.txt

licenses.csv:
	$(RUNNER) gem:licenses:csv['doc/licenses.csv']

api-docs.json:
	$(RUNNER) swagger:docs && ln -s ../public/api-docs.json .

api.md: api-docs.json
	$(RUNNER) swagger:docs:markdown

structure.sql:
	$(RUNNER) db:structure:dump && mv ../db/structure.sql .

clean:
	rm -f controllers_brief.png controllers_complete.png models_brief.png models_complete.png api.txt licenses.csv api-docs.json api.md structure.sql
	apt-get update && apt-get install -y graphviz postgresql-client inkscape
	npm i -g graphql-markdown graphql
