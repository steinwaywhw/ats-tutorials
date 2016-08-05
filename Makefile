

RELEASE=./release/


all: release 
	cd ${RELEASE} && make -f example.make build

gh-pages: release
	cd ${RELEASE} && make -f example.make setup_venv 
	cd ${RELEASE} && source .venv/bin/activate && make -f example.make build 
	cp -f ${RELEASE}/example.html release.tar.gz /tmp/
	rm -rf ${RELEASE}
	git checkout gh-pages && cp -f /tmp/example.html index.html && cp -f /tmp/release.tar.gz ./
	git add --all 
	git commit -m "new release"
	git checkout master

publish-gh-pages: gh-pages
	git checkout gh-pages
	git push origin gh-pages
	git checkout master 

test: lib/* 
	cp lib/example.md lib/example.dats .
	pandoc                               \
		-f markdown                      \
		-t html5                         \
		-s                               \
		--template=lib/ats_template.html \
		--toc                            \
		--filter lib/ats_tutorialize.py  \
		-o example.html                  \
		example.md
	rm example.md example.dats

setup_venv: 
	virtualenv .venv 
	virtualenv -p $$(which python3) .venv 
	source .venv/bin/activate && pip install -r lib/req.pip.txt && deactivate

release: lib/* 
	mkdir -p ${RELEASE}/lib
	sed "s/ats_service.coffee/ats_service.js/g" lib/ats_tutorialize.py > ${RELEASE}/lib/ats_tutorialize.py 
	coffee -c -o $(RELEASE)/lib lib/ats_service.coffee 
	cp lib/req.pip.txt lib/ats_template.html lib/editable.css lib/highlight.css ${RELEASE}/lib/
	cp lib/example* ${RELEASE}
	tar cz ${RELEASE} > release.tar.gz

unrelease:
	rm -rf ${RELEASE}