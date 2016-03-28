cheerio = require("cheerio")
_ = require("underscore")
regexHelper = require("./regexHelper")
url = require("url")
util = require("./util")
request = require("request")

class Readability
    constructor: (@options)->
        defaultOptions =
            content: ""
            debug: false
        for k of defaultOptions
            @options[k] = defaultOptions[k] if _.isUndefined(@options[k])
        @$ = cheerio.load(util.washHtml(@options.content))

    run: ()->
        startTime = new Date().getTime()
        title = @grabTitle()
        grabTileElapsedMilliseconds = new Date().getTime() - startTime
        article = @grabArticle()
        grabArticleElapsedMilliseconds = new Date().getTime() - startTime

        res =
            title: title
            text: article.text.trim()
            html: article.html.trim()
            url: @options.url
            time:
                title: grabTileElapsedMilliseconds
                article: grabArticleElapsedMilliseconds

        return res

    dbg: ()->
        if @options.debug
            console.log.apply this, arguments

    grabTitle: ()->
        @titleCandidates = []
        titleNodes = @$("head title")
        if titleNodes.length isnt 1
            return ""

        @title = cheerio(titleNodes[0]).text().trim()

        for i in [1..3]
            tag = "h#{i}"
            nodes = @$(tag)
            for node,j in nodes
                _score = 9 - i - j # calculate head score
                _score = 1 if _score < 1
                _node = cheerio(node)
                _text = _node.text().trim()
                continue unless _text
                _score += 6 if regexHelper.likeTitle(_getSignature(node))
                _score = _score * (1 + @getTextInTitleWeight(_text))
                @titleCandidates.push
                    text: _text
                    score: _score

        titleClass = @$(".title")
        for titleNode in titleClass
            _text = cheerio(titleNode).text().trim()
            continue unless _text
            _score = 6
            _score = _score * (1 + @getTextInTitleWeight(_text))
            @titleCandidates.push
                text: _text
                score: _score

        betterTitle =
            score: 6
            text: @title

        for candidate in @titleCandidates
            if candidate.score > betterTitle.score
                betterTitle = candidate

        return betterTitle.text

    ###
        grab article content
    ###
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
        text is one of title pieces,may be a good title
        @param {String} text
        @return {Boolean}
    ###
    getTextInTitleWeight: (text)->
        if @title.indexOf(text) isnt -1
            return text.length / @title.length
        return 0

    ###
        get node's signature:class name + id
        @param {Object} node
        @return {String} signature
    ###
    _getSignature = (node)->
        return (node.attribs?.class or "") + (node.attribs?.id or "")

    ###
        remove unlikely content node
        @param {Object} htmlObj cheerio object
    ###
    removeUnlikelyNode: ()->
        allElements = @$("*")

        for elem in allElements
            node = cheerio(elem)
            _sign = _getSignature(elem)
            tagName = elem.name

            continueFlag = false

            #remove unlikely candidate node
            if _sign and (tagName isnt "body") and regexHelper.unlikelyCandidates(_sign) and (not regexHelper.okMaybeItsACandidate(_sign))
                node.remove()
                @dbg "remove node:#{_sign}"
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
        @candidates = []

        allPElements = @$("p")
        for elem in allPElements
            node = cheerio(elem)
            parentNode = elem.parent
            unless parentNode
                continue

            if _.isUndefined(parentNode.score)
                util.initializeNode(parentNode)
                @candidates.push parentNode
            else
                @dbg "parent score:#{parentNode.score}"

            grandParentNode = parentNode.parent
            if grandParentNode and _.isUndefined(grandParentNode.score)
                util.initializeNode(grandParentNode)
                @candidates.push(grandParentNode)
            else
                @dbg "grantParent score:#{grandParentNode.score}" unless _.isUndefined(grandParentNode)

            innerText = node.text()

            if util.justWords(innerText)
                @dbg "may be just words => #{innerText}"
                continue

            contentScore = util.contentScore(innerText)

            parentNode.score += contentScore
            grandParentNode.score += contentScore / 2 unless _.isUndefined(grandParentNode)

        @dbg "candidates count:#{@candidates.length}"

    ###
        select out top candidates
        @param {Array} candidates
        @return {Object} top candidate
    ###
    selectTopCandidate: ()->
        for candidate,i in @candidates
            linkDensity = util.getLinkDensity(candidate)
            if linkDensity > 0
                candidate.score = candidate.score * (1 - linkDensity)

            if (not @topCandidate) or (candidate.score > @topCandidate.score)
                @dbg "find new better candidate"
                @topCandidate = candidate

        # if we still have no top candidate,use the body
        if @topCandidate is null or @topCandidate.name is "body"
            @topCandidate = cheerio("<div></div>").html(cheerio(@topCandidate).html())[0]
            util.initializeNode(@topCandidate)

    ###
        pull out all good nodes according to top candidate
        @param {Object} topCandidate
        @return {Array} good nodes array
    ###
    pullAllGoodNodes: ()->
        @goodNodes = []
        siblingNodes = []
        if @topCandidate.parent
            siblingNodes = @topCandidate.parent.children

        if siblingNodes.length > 0
            @dbg "sibling count:#{siblingNodes.length}"
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
                        $sibling = cheerio(sibling)
                        innerText = $sibling.text()
                        linkDensity = util.getLinkDensity($sibling)

                        if innerText.length > 80 && linkDensity < 0.25
                            append = true
                        else if (innerText.length <= 80 and linkDensity is 0 and (innerText.search(/\.( | $)/) isnt -1))
                            append = true
                if append
                    @goodNodes.push sibling
        else
            @goodNodes.push @topCandidate

    ###
        prepare article,clean html
    ###
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

        util.pullOutRealPath(@articleContent, @options.url)

exports.parse = (options, cb)->
    if _.isObject(options)
        read = new Readability(options)
        cb(null, read.run())
    else if _.isString(options) and util.isURL(options)
        request options, (err, response, body)->
            return cb(err) if err
            read = new Readability
                url: options
                content: body.toString()
            cb(null, read.run())
    else if _.isString(options)
        read = new Readability
            content: options
        cb(null, read.run())
    else
        cb(new Error("invalid parameter"))
