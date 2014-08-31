regexHelper = require("./regexHelper")
$ = require("cheerio")
_ = require("underscore")
url = require("url")

###
    trim script tag
    @param {String} html html content
###
exports.washHtml = (html)->
	html = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
	return html

###
    initialize a node with content score
    @param {Object} node
###
exports.initializeNode = (node)->
	score = 0
	switch node.name
		when "object","embed"
			try
				if regexHelper.isVideo(node.attribs["src"])
					score += 10
			catch e
				console.dir e
		when "div" then score += 5
		when "pre","td","blockquote","img" then score += 3
		when "address","ol","ul","dl","dd","dt","li","form" then score -= 3
		when "h1","h2","h3","h4","h5","h6","th" then score -= 5
	score += _getClassAndIdWeight(node)
	node.score = score

###
	get link density
    @param {Object} node
###
_getLinkDensity = exports.getLinkDensity = (node)->
	unless node instanceof $
		node = $(node)
	return node.find("a").text().length / node.text()

###
    detect input is just some words(more than 5 words)
    @param {String} input
###
exports.justWords = (input)->
	input = input.trim()
	if _containsChinese(input)
		return input.length < 10
	else
		return input.length < 25

###
    calculate content score
    @param {String} input content
###
exports.contentScore = (input)->
	score = 1
	input = input.trim()
	score += input.replace(",", ',').split(',').length
	if _containsChinese(input)
		score + Math.min(Math.floor(input.length / 40), 3)
	else
		score + Math.min(Math.floor(input.length / 100), 3)
	return score

###
    kill all breaks
###
exports.killBreaks = (node)->
	node.html(regexHelper.replaceBreaks(node.html()))

###
    clean tag
    @param {Object} node
    @param {String} tag tag name
###
exports.clean = (node, tag)->
	isEmbed = tag is "object" or tag is "embed"

	targetArray = node.find(tag)
	for n in targetArray
		_node = $(n)
		if isEmbed and regexHelper.isVideo(_node.html())
			continue
		_node.remove()

###
    clean headers
    @param {Object} node cheerio node
###
exports.cleanHeaders = (node)->
	for headerIndex in [2..3]
		headers = node.find("h" + headerIndex)
		for header in headers
			if _getClassAndIdWeight(header) < 0 or _getLinkDensity(header) > 0.33
				header.remove()

exports.cleanConditionally = (node, tag)->
	tagList = node.find(tag)

	if tagList.length > 0
		for n in tagList
			weight = _getClassAndIdWeight(n)
			score = n.score or 0
			_n = $(n)
			if (weight + score) < 0
				_n.remove()
			else if(_n.text().replace("，", ",").split(',').length < 10)
				#if there are not very many commas,and the number of
				#non-paragraph elements is more that paragraphs or other ominous signs
				#remove the element.
				pLength = _n.find("p").length
				imgLength = _n.find("img").length
				liLength = _n.find("li").length
				inputLength = _n.find("input").length
				embedCount = 0
				embeds = _n.find("embed")
				for em in embeds
					if regexHelper.isVideo($(em).attr("src")) #是否不用这样取
						embedCount += 1

				contentLength = _n.text().length
				linkDensity = _getLinkDensity(_n)

				toRemove = false

				if imgLength > pLength
					toRemove = true
				else if liLength > pLength and (tag isnt "ul") and (tag isnt "ol")
					toRemove = true
				else if inputLength > Math.floor(pLength / 3)
					toRemove = true
				else if weight < 25 and linkDensity > 0.2
					toRemove = true
				else if weight >= 24 and linkDensity > 0.5
					toRemove = true
				else if (embedCount is 1 and contentLength < 75) or embedCount > 1
					toRemove = true

				if toRemove
					_n.remove()

###
    remove extra paragraphs
    @param {Object} node
###
exports.removeExtraParagraph = (node)->
	paragraphs = node.find("p")
	for para in paragraphs
		_n = $(para)
		imgCount = _n.find("img").length
		embedCount = _n.find("embed").length
		objectCount = _n.find("object").length
		if imgCount is 0 and embedCount is 0 and objectCount is 0 and _n.text().trim() is ""
			_n.remove()

###
    remove the header that doesn't have next siblings
###
exports.removeSingleHeader = (node)->
	for headerIndex in [1..6]
		headers = $(node).find("h#{headerIndex}")
		for header in headers
			if _.isNull(header.next) and _.isNull(header.prev)
				$(header).remove()

###
    remove attributes
    @param {Object} node cheerio node
###
exports.trimAttributes = (node)->
	all = node.find("*")
	for n in all
		proAttrs = ['srv']
		if n.name isnt "object" and n.name isnt "embed"
			proAttrs.push 'href'
			proAttrs.push 'width' #TODO:图片的宽度高度应该留一个
		for attr in n.attribs
			$(n).removeAttr(attr) if attr not in proAttrs #TODO:是否可以通过直接 delete 呢

###
    replace relative path with real path
    @param {Object} node
    @param {String} baseUrl
###
exports.pullOutRealPath = (node, baseUrl)->
	if baseUrl
		imgs = node.find('img')
		imgs.each (i, img)->
			realPath = img.attribs['src']
			_.each img.attribs, (value, key)->
				realPath = value if _isUrl(value) and (value isnt realPath or (not realPath))
			img.attribs['src'] = if _isUrl(realPath) then realPath else url.resolve(baseUrl, realPath)

		links = node.find('a')
		links.each (i, link)->
			link.attribs['href'] = url.resolve(baseUrl, link.attribs['href']) if link.attribs['href']

###
    detect if string contains chinese words
###
_containsChinese = (str)->
	return escape(str).indexOf("%u") isnt -1

###
	calculate node's description(class+id) score
	@param {Object} node
	@return {Number} score
###
_getClassAndIdWeight = (node)->
	weight = 0
	if node.attribs
		className = node.attribs['class']
		id = node.attribs["id"]
		desc = className + id
		unless desc
			return weight

		if regexHelper.isNegative(desc)
			weight -= 25
		if regexHelper.isPositive(desc)
			weight += 25

	return weight

###
    test path is a url
    @param {String} path
###
_isUrl = (path)->
	urlRegex = /^(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?$/
	return urlRegex.test(path)