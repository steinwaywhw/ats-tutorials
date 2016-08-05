ats_service = 

  hljs: false

  precodify: 
    (str, pre_cls = "", code_cls = "") -> 
      "<pre class=\"#{pre_cls}\"><code class=\"#{code_cls}\">#{str}</code></pre>"

  # endpoints
  api: 
    tc:    "https://www.ats-lang.org/SERVER/MYCODE/atslangweb_patsopt_tcats_0_.php"
    cc:    "https://www.ats-lang.org/SERVER/MYCODE/atslangweb_patsopt_ccats_0_.php" 
    cjs:   "https://www.ats-lang.org/SERVER/MYCODE/atslangweb_patsopt_atscc2js_0_.php"
    chtml: "https://www.ats-lang.org/SERVER/MYCODE/atslangweb_pats2xhtml_eval_0_.php"

  # get code from editor
  get_code: 
    (id) -> ace.edit("#{id}-editor").getValue()

  # fix pre code
  fix_pre_code: 
    (elem) -> 
      classes = $(elem).attr("class")
      elem = $(elem).wrapAll("<pre><code></code></pre>").children().unwrap().parent().parent()
      elem.attr("class", classes)
      elem 

  # use hljs
  use_hljs: 
    (elem) -> 
      elem = @fix_pre_code(elem)
      elem.addClass("hljs").removeClass("patsyntax")
      mapping = 
        'keyword'          : 'hljs-keyword'
        'comment'          : 'hljs-comment'
        'extcode'          : 'hljs-meta'
        'neuexp'           : ''
        'staexp'           : 'hljs-type'
        'prfexp'           : 'hljs-symbol'
        'dynexp'           : ''
        'stalab'           : 'hljs-type'
        'dynlab'           : ''
        'dynstr'           : 'hljs-string'
        'stacstdec'        : ''
        'stacstuse'        : ''
        'dyncstdec'        : ''
        'dyncstuse'        : ''
        'dyncst_implement' : ''

      for k, v of mapping
        do (k, v) -> 
          elem.find(".#{k}").removeClass(k).addClass(v) 

      elem      

  preview: 
    (id) -> 
      $("##{id} button:contains('Edit')").show()
      $("##{id} button:contains('Preview')").hide()
      $("##{id} > .preview").show()
      $("##{id} > .editor").hide()

      self = this 
      handler = (data, status) -> 
        data = $.parseJSON(decodeURIComponent(data))
        html = if self.hljs then self.use_hljs(data[1]) else self.fix_pre_code(data[1])
        $("##{id}-preview").html(html)

      $.post(@api.chtml, {mycode: @get_code(id), stadyn: 1}).done(handler)

  show_code:
    (id, code, language, append = false) -> 
      @clear() if not append
      code = hljs.highlight(language, code).value if @hljs 
      code = if @hljs then @precodify(code, "hljs") else @precodify(code)
      target = $("##{id}-output")
      if append and target.html().length > 0
        target.append("<br>")
        target.append(code)
      else 
        target.html(code)

  edit: 
    (id) -> 
      $("##{id} button:contains('Edit')").hide()
      $("##{id} button:contains('Preview')").show()
      $("##{id} > .preview").hide()
      $("##{id} > .editor").show()

  typecheck: 
    (id) -> 
      self = this
      handler = (data, status) ->
        data = $.parseJSON(decodeURIComponent(data))
        console.log(status)
        self.show_code(id, data[1], "bash")

      $.post(@api.tc, {mycode: @get_code(id), stadyn: 1}).done(handler)

  compilec: 
    (id) -> 
      self = this
      handler = (data, status) -> 
        data = $.parseJSON(decodeURIComponent(data))
        if data[0] == 0
          self.show_code(id, data[1], "c")
        else 
          self.show_code(id, data[1], "bash")

      $.post(@api.cc, {mycode: @get_code(id), stadyn: 1}).done(handler)

  runjs: 
    (id) -> 
      self = this
      handler = (data, status) -> 
        data = $.parseJSON(decodeURIComponent(data))
        if not data[0] == 0
          self.show_code(id, data[1], "bash")
        else 
          try 
            result = eval(data[1])
            self.show_code(id, result, "js")
          catch error
            $("##{id}-output").html("#{error}")
          finally
            self.show_code(id, data[1], "js", true)

      $.post(@api.cjs, {mycode: @get_code(id), stadyn: 1}).done(handler)

  download:
    (id) -> 
      code = escape(@get_code(id))
      window.open("data:x-application/text," + code)


  clear:
    (id) -> $("##{id}-output").empty()

window.ats_service = ats_service
