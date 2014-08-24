should = require("should")
$ = require("cheerio")
util = require("../lib/util")

describe "util test", ()->
	describe "remove single header test", ()->
		it "should be empty after remove", ()->
			html = "<div><h5>test header</h5></div>"
			obj = $("div",html)
			util.removeSingleHeader(obj)
			obj.html().should.be.empty
		it "should remain a div and h5 which have sibling",()->
			html="<div><div><h3>test</h3></div><h5>should remain</h5></div>"
			obj=$(html)
			util.removeSingleHeader(obj)
			obj.html().should.be.exactly("<div></div><h5>should remain</h5>")