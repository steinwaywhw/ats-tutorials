---
hljs: true
hljs-style: solarized-light
ace-style: solarized_light
title: ATS Tutorial Tools
---

# ATS Tutorials Tooling Support

Our toolset provides you with a plugin and supporting files on top of a regular `pandoc` workflow: writing markdown, and getting webpages. You gain all the benefits of markdown and all the power of `pandoc`, and you can easily wirte ATS programming language tutorials that embeds editable/runnable ATS code with proper highlighting.

All the tools you need is in the released `lib` folder. It contains 

* a python filter `ats_tutorialize.py` for `pandoc`, which processes incoming `pandoc` parse tree, and transform it in some way to produce interactive tutorials.  
* a template `ats_template.html` 
* a javascript file `ats_service.js` (compiled from coffeescript) that provides the interactive part of the webpage. 
* several stylesheets
* and an example with proper makefile.

Before we can start, we need to ensure that we have the following software installed. 

* python3, pip3, and [virtualenv](http://docs.python-guide.org/en/latest/dev/virtualenvs/)
* [pandoc (latest)](http://pandoc.org/)

## Contribution

Please head to <https://github.com/steinwaywhw/ats-tutorials>. Issues, pull requests are welcomed. 

## Installation

Installation is easy, just download the [release.tar.gz](release.tar.gz), and install necessary softwares. Requested python packages can be setup by the following steps.

```bash
make -f example.make setup_venv # setup virtual env and install python packages
source .venv/bin/activate       # enter the virtual env
```

Then you can start working on the tutorials. After finished, remeber to deactivate the virtual environment by 

```bash 
deactivate
```

## Getting Start

With `example.make` and `example.md`, we just type 

```bash
make -f example.make 
```

and the output will be in `example.md`. This example file mainly demonstrats how a regular markdown file looks like, with features like 
* YAML front matter, where you can configure the behavior of both `pandoc` and our filter. For `pandoc` parameters, see [its user guide](http://pandoc.org/MANUAL.html).
* basic formattings of elements, e.g. headings, paragraghs, lists, inline code, etc. See `pandoc` [user guide](http://pandoc.org/MANUAL.html) for full references. See [here](https://daringfireball.net/projects/markdown/) for a quick look. 
* fenced code blocks with options, see followings for details. The code blocks with `.ats` option will be processed by our filter. Others will be processed by `pandoc` as usual. 

## Using Code Blocks

Let's take a fully equipped example as follows.

```
    ```{#assignment1 .ats .dynamic}
    extern fun hello (): string 
    implement main0 () = ()
    ```
```

```{#assignment1 .ats .dynamic}
extern fun hello (): string 
implement main0 () = ()
```

Here, after the opening fence, a curly brace is used to provide options. `#assignment1` is the id of this code block, which will be the id of corresponding html element in the output. `.ats` and `.dynamic` are classes of the code, specifying that this is dynamic ATS code that needs to be highlighted. You can add more classes, they will be passed unchanged to the resulting html elements as their classes. If you are writing static ATS code, just change `.dynamic` to `.static`. 

If you have a longer file, that you don't want to compose in-place, use the option `include=file.ext` as below.

```
    ```{#assignment1 .ats .dynamic include="example.dats"}
    ```
```


```{#assignment1 .ats .dynamic include="example.dats"}
```


If you want the code to be editable, just add `.editable` as below. 

```
    ```{#assignment1 .ats .dynamic .editable include="example.dats"}
    ```
```

```{#assignment1 .ats .dynamic .editable include="example.dats"}
```

The resulting page will provide a group of buttons, for editing the code, as well as type-checking, compiling to c, and compiling to javascript. 

## Other Options

As you can see, in the YAML front matter (the beginning of the raw content of this markdown file), we have several options to set. They are as follows. 

* `hljs`: use `highlight.js` if set to true. use default styling if `false`. `true` by default. 
* `hljs-style`: choose a theme for `highlight.js`, see [github](https://github.com/isagalaev/highlight.js/tree/master/src/styles) for a complete list of styles. 
* `ace-style`: choose a theme for the `ace` editor, see [github](https://github.com/ajaxorg/ace/tree/master/lib/ace/theme) for a complete list. Default to `solarized_dark`.
* `title`: Title of the document. This is part of the options provided by `pandoc`, see the `ats_template.html` for a full list of options. Just look for template variables enclosed in `$`. 


