





RELEASE=./release/


all: release 
	cd ${RELEASE} && make -f example.make build

gh-pages: release
	cd ${RELEASE} && make -f example.make setup_venv 
	cd ${RELEASE} && source .venv/bin/activate && make -f example.make build 
	cp ${RELEASE}/example.html index.html
	rm -rf ${RELEASE}

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