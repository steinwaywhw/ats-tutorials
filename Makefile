



all: release 
	cd release && make -f example.make build

# STATIC=./static/
RELEASE=./release/

# download:
# 	mkdir -p ${STATIC}
# 	wget https://ats-lang.github.io/LIBRARY/libatscc2js/libatscc2js_all.js -o ${STATIC}/libatscc2js_all.js
# 	wget https://ats-lang.github.io/LIBRARY/libatscc2js/libatscc2js_print_store_cats.js -o ${STATIC}/libatscc2js_print_store_cats.js 
# 	wget https://ats-lang.github.io/LIBRARY/ats2langweb/pats2xhtmlize_dats.js -o ${STATIC}/pats2xhtmlize_dats.js 


test: 
	pandoc -f markdown -t html5 -s --template=lib/ats_template.html --toc --filter lib/ats_tutorialize.py -o test.html test.md

release: lib/*
	mkdir -p ${RELEASE}/lib
	sed "s/ats_service.coffee/ats_service.js/g" lib/ats_tutorialize.py > ${RELEASE}/lib/ats_tutorialize.py 
	coffee -c -o $(RELEASE)/lib lib/ats_service.coffee 
	cp req.pip.txt lib/ats_template.html lib/editable.css lib/highlight.css ${RELEASE}/lib/
	cp lib/example* ${RELEASE}
	tar cz ${RELEASE} > release.tar.gz

unrelease:
	rm -rf ${RELEASE}