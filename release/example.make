

all: build

setup_venv:
	@echo "Requirements:"
	@echo "   python3, pip3"
	@echo "   virtualenv (http://docs.python-guide.org/en/latest/dev/virtualenvs/)"
	virtualenv .venv 
	virtualenv -p $$(which python3) .venv 
	source .venv/bin/activate && pip install -r lib/req.pip.txt && deactivate


build: 
	@echo "make sure you are in the correct virtualenv."
	pandoc                               \
		-f markdown                      \
		-t html5                         \
		-s                               \
		--template=lib/ats_template.html \
		--toc                            \
		--filter lib/ats_tutorialize.py  \
		-o example.html                   \
		example.md