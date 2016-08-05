import os 
import sys
import requests
import tempfile
import json
from urllib import parse
from bs4 import *
from panflute import *

######################
# embed files
######################

def embed_raw(doc, tp, content):
	if tp == '.js':
		content = '<script>{}</script>'.format(content)

	elif tp == '.css':
		content = '<style>{}</style>'.format(content)

	elif tp == '.less':
		tmp = tempfile.NamedTemporaryFile(mode='w', delete=False)
		tmp.write(content)
		tmp.close()

		output = str((shell(['lessc', tmp.name])),'utf-8')
		content = '<style>{}</style>'.format(output)
		os.remove(tmp.name)

	elif tp == '.coffee':
		tmp = tempfile.NamedTemporaryFile(mode='w', delete=False)
		tmp.write(content)
		tmp.close()

		output = str((shell(['coffee', '-cp', tmp.name])),'utf-8')
		content = '<script>{}</script>'.format(output)
		os.remove(tmp.name)

	elif tp == '.html':
		content = content

	else:
		raise RuntimeError ("Format not supported.")

	doc.content.insert(0, RawBlock(content))


def embed_file(doc, file):
	ext = os.path.splitext(file)[-1].lower()
	debug("embedding file {} with ext {}".format(file, ext))

	f = open(file, 'r')
	content = f.read()
	f.close()

	embed_raw(doc, ext, content)


######################
# prepare and finalize
######################

# metadata in the YAML
# hljs, hljs-style, ace-style
# 
# metadata knobs in the template:
# css, math, ats, hljs, jq, ace
# 
# files can be embedded
# highlight.css
# editable.css
# ats_service.coffee

def prepare(doc):
	debug("preparing filters")
	doc.ats = False 
	doc.ace = False
	doc.hljs = doc.get_metadata('hljs', default=True)
	doc.hljs_style = doc.get_metadata('hljs-style', default=MetaString("default"))
	doc.ace_style = doc.get_metadata('ace-style', default=MetaString("solarized_dark"))

def finalize(doc):
	debug("finalizing filters")
	if doc.ats:
		doc.metadata['ats'] = True

		if doc.hljs:
			debug("using highlight.js")
			doc.metadata['hljs'] = True
			doc.metadata['hljs-style'] = doc.hljs_style

			# this has to be after ats_service is loaded
			# therefore, it is firstly inserted
			doc.content.insert(0, RawBlock("<script>window.ats_service.hljs = true</script>"))
		else:
			debug("using home-made highligh.css")
			embed_file(doc, "lib/highlight.css")

		if doc.ace:
			debug("using ace, jq and ats_service")
			doc.metadata['jq'] = True
			doc.metadata['ace'] = True
			embed_file(doc, 'lib/editable.css')
			embed_file(doc, 'lib/ats_service.coffee')

	del doc.ats 
	del doc.hljs 
	del doc.hljs_style
	del doc.ace

######################
# filters
######################

def include(elem, doc): 
	if doc.format in ['html', 'html5'] and isinstance(elem, CodeBlock) and 'ats' in elem.classes:
		doc.ats = True

		if 'include' in elem.attributes:
			file = open(elem.attributes['include'], 'r')
			debug("including file {}".format(file.name))
			code = file.read()
			file.close()
			del elem.attributes['include']

			elem.text = code.strip()
			return elem


def fix_pre_code(code, ident, classes):
	soup = BeautifulSoup(code, 'html.parser')
	classes += soup.pre['class']

	newpre = soup.new_tag('pre')
	newpre['id'] = ident 
	newpre['class'] = classes 

	newpre.append(soup.new_tag('code'))
	soup.pre.unwrap()

	# fix the first line empty problem
	if soup.contents[0] == '\n':
		soup.contents = soup.contents[1:]

	newpre.code.append(soup)

	return newpre

def use_hljs(code, ident, classes):
	pre = fix_pre_code(code, ident, classes)
	pre['class'] = ['hljs']

	mapping = {
		'keyword':          'hljs-keyword', # {color:#000000;font-weight:bold;}
		'comment':          'hljs-comment', # {color:#787878;font-style:italic;}
		'extcode':          'hljs-meta', # {color:#A52A2A;}
		'neuexp':           '', #  {color:#800080;}
		'staexp':           'hljs-type', #  {color:#0000F0;}
		'prfexp':           'hljs-symbol', #  {color:#603030;}
		'dynexp':           '', #  {color:#F00000;}
		'stalab':           'hljs-type', #  {color:#0000F0;font-style:italic}
		'dynlab':           '', #  {color:#F00000;font-style:italic}
		'dynstr':           'hljs-string', #  {color:#008000;font-style:normal}
		'stacstdec':        '', #  {text-decoration:none;}
		'stacstuse':        '', #  {color:#0000CF;text-decoration:underline;}
		'dyncstdec':        '', #  {text-decoration:none;}
		'dyncstuse':        '', #  {color:#B80000;text-decoration:underline;}
		'dyncst_implement': ''  #  {color:#B80000;text-decoration:underline;}
	}


	for k, v in mapping.items():
		for elem in pre.select("." + k):
			elem['class'] = [v]
	
	return str(pre)


def offline_highlight(elem, doc):
	if doc.format in ['html', 'html5']  \
		and isinstance(elem, CodeBlock) \
		and 'ats' in elem.classes \
		and 'editable' not in elem.classes:

		doc.ats = True

		query = {'mycode': elem.text}
		if 'static' in elem.classes:
			query['stadyn'] = 0
		else:
			query['stadyn'] = 1

		debug("offline highlighting for id {}".format(str(elem.identifier)))

		rsp = requests.post('http://www.ats-lang.org/SERVER/MYCODE/atslangweb_pats2xhtml_eval_0_.php', data=query)
		data = json.loads(parse.unquote(rsp.text))

		if data[0] == 0:			
			if doc.hljs:
				return RawBlock(use_hljs(data[1], elem.identifier, elem.classes))
			else:
				return RawBlock(str(fix_pre_code(data[1], elem.identifier, elem.classes)))
		else:
			elem.text = data[1]
			return elem

def editable_template(ident, classes, code, ace_style):
	ret = """
		  <section id="{id}" class="{classes}">
		    <div id="{id}-control" class="control">
			  <button onClick='{api}.preview("{id}")'>Preview</button>
			  <button onClick='{api}.edit("{id}")'>Edit</button>
			  <button onClick='{api}.download("{id}")'>Download</button>
			  <button onClick='{api}.clear("{id}")'>Clear Output</button>
			  <button onClick='{api}.typecheck("{id}")'>Type Check</button>
			  <button onClick='{api}.compilec("{id}")'>Compile (C)</button>
			  <button onClick='{api}.runjs("{id}")'>Run (JavaScript)</button>
		    </div>
		  	<div id="{id}-editor" class="editor">{code}</div>
		  	<div id="{id}-preview" class="preview"></div>
		  	<div id="{id}-output" class="output"></div>
		  	<script>
		  	  var editor = ace.edit("{id}-editor");
		  	  editor.$blockScrolling = Infinity;
		  	  editor.setTheme("ace/theme/{ace_style}");
		  	  editor.setOptions({{maxLines: Infinity}});
		  	  editor.session.setMode("ace/mode/plain_text");
		  	  editor.resize();
		  	  {api}.edit("{id}");
		  	</script>
		  </section>
	      """

	return ret.format(id=ident, classes=' '.join(classes), code=code, api='ats_service', ace_style=ace_style)

def editable(elem, doc):
	if doc.format in ['html', 'html5']  \
		and isinstance(elem, CodeBlock) \
		and 'ats' in elem.classes       \
		and 'editable' in elem.classes:

		doc.ace = True

		debug("making code editable for id {}".format(str(elem.identifier)))

		if not elem.identifier:
			raise AssertionError("Must have an identifier.\n" + str(elem))



		soup = BeautifulSoup(editable_template(elem.identifier, elem.classes, elem.text, stringify(doc.ace_style)), 'html.parser')
		
		return RawBlock(str(soup))

if __name__ == '__main__':
	toJSONFilters([include, offline_highlight, editable], prepare, finalize)
