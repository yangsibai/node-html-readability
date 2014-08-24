cheerio = require("cheerio")
_ = require("underscore")
regexHelper = require("./regexHelper")
url = require("url")
util = require("./util")

dbg = ()->
#	console.log.apply this, arguments

class readability
	constructor: (@options)->
		@$ = cheerio.load(util.washHtml(@options.content))

	grabArticle: ()->
		@removeUnlikelyNode()
		@selectCandidates()
		@selectTopCandidate()
		@pullAllGoodNodes()
		@articleContent = cheerio("<div></div>")
		for node in @goodNodes
			@articleContent.append(node)

		@prepArticle()

		return {
			text: @articleContent.text()
			html: @articleContent.html()
		}

	###
		remove unlikely content node
		@param {Object} htmlObj cheerio object
	###
	removeUnlikelyNode: ()->
		allElements = @$("*")

		allElements.each (i, elem)->
			node = cheerio(this)
			unlikelyMatchString = (elem.attribs?.class or "") + (elem.attribs?.id or "")
			tagName = elem.name

			continueFlag = false

			#remove unlikely candidate node
			if unlikelyMatchString and (tagName isnt "body") and regexHelper.unlikelyCandidates(unlikelyMatchString) and (not regexHelper.okMaybeItsACandidate(unlikelyMatchString))
				node.remove()
				dbg "remove node:#{unlikelyMatchString}"
				continueFlag = true

			#turn all dives that don't have children block level elements into p
			if (not continueFlag) and (tagName is "div")
				if regexHelper.divToPElements(node.html()) #这里搜索字符串可能不准确
					newNode = cheerio("<p></p>")
					newNode.html(node.html())
					node.replaceWith(newNode)

	###
		select out candidates
		@param {Object} htmlObj cheerio object
		@return {Array} candidates array
	###
	selectCandidates: ()->
		candidates = []

		@$("p").each (i, elem)->
			node = cheerio(this)
			parentNode = elem.parent
			unless parentNode
				return

			if _.isUndefined(parentNode.score)
				util.initializeNode(parentNode)
				candidates.push parentNode
			else
				dbg "parent score:#{parentNode.score}"

			grandParentNode = parentNode.parent
			if grandParentNode and _.isUndefined(grandParentNode.score)
				util.initializeNode(grandParentNode)
				candidates.push(grandParentNode)
			else
				dbg "grantParent score:#{grandParentNode.score}" unless _.isUndefined(grandParentNode)

			innerText = node.text()

			if util.justWords(innerText)
				dbg "may be just words => #{innerText}"
				return

			contentScore = util.contentScore(innerText)

			parentNode.score += contentScore
			grandParentNode.score += contentScore / 2 unless _.isUndefined(grandParentNode)


		dbg "candidates count:#{candidates.length}"
		@candidates = candidates

	###
		select out top candidates
		@param {Array} candidates
		@return {Object} top candidate
	###
	selectTopCandidate: ()->
		topCandidate = null
		for candidate,i in @candidates
			linkDensity = util.getLinkDensity(candidate)
			if linkDensity > 0
				candidate.score = candidate.score * (1 - linkDensity)

			if (not topCandidate) or (candidate.score > topCandidate.score)
				dbg "find new better candidate"
				topCandidate = candidate

		# if we still have no top candidate,use the body
		if topCandidate is null or topCandidate.name is "body"
			topCandidate= cheerio("<div></div>").html(cheerio(topCandidate).html())[0]
			util.initializeNode(topCandidate)

		@topCandidate = topCandidate

	###
		pull out all good nodes according to top candidate
		@param {Object} topCandidate
		@return {Array} good nodes array
	###
	pullAllGoodNodes: ()->
		goodNodes = []
		siblingNodes = []
		if @topCandidate.parent
			siblingNodes = @topCandidate.parent.children

		if siblingNodes.length > 0
			dbg "sibling count:#{siblingNodes.length}"
			topCandidateClassName = @topCandidate.attribs["class"]
			siblingScoreThreshold = Math.max(10, @topCandidate.score * 0.2)

			for sibling in siblingNodes
				append = false
				if sibling is @topCandidate
					append = true
				else
					contentBonus = 0
					if topCandidateClassName and sibling.attribs and sibling.attribs["class"]
						siblingClassName = sibling.attribs["class"]
						if topCandidateClassName and (topCandidateClassName is siblingClassName)
							contentBonus += @topCandidate.score * 0.2

					if (not _.isUndefined(sibling.score)) and (sibling.score + contentBonus) >= siblingScoreThreshold
						append = true

					if sibling.name is "p"
						$sibling = $(sibling)
						innerText = $sibling.text()
						linkDensity = util.getLinkDensity($sibling)

						if innerText.length > 80 && linkDensity < 0.25
							append = true
						else if (innerText.length <= 80 and linkDensity is 0 and (innerText.search(/\.( | $)/) isnt -1))
							append = true
				if append
					goodNodes.push sibling
		else
			goodNodes.push @topCandidate

		@goodNodes = goodNodes

	prepArticle: ()->
		util.killBreaks(@articleContent)

		util.clean(@articleContent, "form")
		util.clean(@articleContent, "object")
		util.clean(@articleContent, "h1")
		util.clean(@articleContent, "input")
		util.clean(@articleContent, "textarea")
		util.clean(@articleContent, "iframe")

		if @articleContent.find('h2').length is 1
			util.clean(@articleContent, "h2")

		util.cleanHeaders(@articleContent)

		util.cleanConditionally(@articleContent, "table")
		util.cleanConditionally(@articleContent, "ul")
		util.cleanConditionally(@articleContent, "div")

		util.removeExtraParagraph(@articleContent)

		util.removeSingleHeader(@articleContent)

		util.trimAttributes(@articleContent)


module.exports = readability
