should = require("should")
$ = require("cheerio")
util = require("../lib/util")

describe "util test", ()->
	describe "remove single header test", ()->
		it "should be empty after remove", ()->
			return
			html = "<div><h5>test header</h5></div>"
			obj = $("div",html)
			util.removeSingleHeader(obj)
			obj.html().should.be.empty
		it "should remain a div and h5 which have sibling",()->
			return
			html="<div><div><h3>test</h3></div><h5>should remain</h5></div>"
			obj=$(html)
			util.removeSingleHeader(obj)
			obj.html().should.be.exactly("<div></div><h5>should remain</h5>")
		it "should replace relative path with absolute path",()->
			html="<div><img src='./test.png' /></div>"
			obj=$(html)
			util.pullOutRealPath(obj,"http://example.com")
			obj.find("img")[0].attribs["src"].should.be.exactly("http://example.com/test.png")
		it "should not use resolve if src is absolute path",()->
			html="<div><img src='http://example.com/test.png'></div>"
			obj=$(html)
			util.pullOutRealPath(obj,"http://example.com")
			obj.find("img")[0].attribs["src"].should.be.exactly("http://example.com/test.png")
		it "should replace lazy src with real img",()->
			html="<div><img img='lazy.png' data-real-path='http://example.com/real.png'/></div>"
			obj=$(html)
			util.pullOutRealPath(obj,"http://example.com")
			obj.find("img")[0].attribs["src"].should.be.exactly("http://example.com/real.png")
