# This Makefile generates all API documentation under doc/
# Run it this way: cd doc/ && make
# You can remove the files by running: cd doc/ && make clean
# Dependencies: GNU Make, Inkscape and PDF LateX, besides the API dependencies

INKSCAPE = inkscape -b 'rgb(255, 255, 255)' 
RAKE = bundle exec rake 
BEXEC = bundle exec 

all: controllers_brief.png controllers_complete.png models_brief.png models_complete.png api.txt licenses.csv api-docs.json api.md graphql.md

controllers_brief.png: controllers_brief.svg
	$(INKSCAPE) --export-png='controllers_brief.png' controllers_brief.svg

controllers_brief.svg:
	cd .. && $(RAKE) diagram:controllers:brief && cd -

controllers_complete.png: controllers_complete.svg
	$(INKSCAPE) --export-png='controllers_complete.png' controllers_complete.svg

controllers_complete.svg:
	cd .. && $(RAKE) diagram:controllers:complete && cd -

models_brief.png: models_brief.svg
	$(INKSCAPE) --export-png='models_brief.png' models_brief.svg

models_brief.svg:
	cd .. && $(BEXEC) railroady -M -s app/models/annotations/*,app/models/*.rb -b | dot -Tsvg > doc/models_brief.svg && cd -

models_complete.png: models_complete.svg
	$(INKSCAPE) --export-png='models_complete.png' models_complete.svg

models_complete.svg:
	cd .. && $(BEXEC) railroady -M -s app/models/annotations/*,app/models/*.rb | dot -Tsvg > doc/models_complete.svg && cd -

api.txt:
	echo "API Endpoints - `LANG=en_US date --utc`" > api.txt
	$(RAKE) routes | sed 's/.*\([PGD]\)/\1/g' | sed 's/(.:format).*//g' | grep -v Pattern | sort | nl >> api.txt

licenses.csv:
	$(RAKE) lapis:licenses > licenses.csv

api-docs.json:
	tmp=`mktemp -d` && cd .. && mv public/*.json $$tmp && $(RAKE) swagger:docs && cd - && ln -s ../public/api-docs.json && mv $$tmp/*.json ../public/

api.md: api-docs.json
	cd .. && $(RAKE) swagger:docs:markdown && cd -

graphql.md:
	cd .. && $(RAKE) lapis:graphql:docs && cd -

clean:
	rm -f *.png *.svg *.txt *.csv *.json api.md graphql.md
