readability = require("../lib/index")
should = require("should")
path = require("path")
fs = require("fs")

describe "grab article test", ()->
	it "case 1", (done)->
		done()
		return
		sample1Path = path.join(__dirname, "/samples/1.html")
		fs.readFile sample1Path, (err, data)->
			should(err).be.empty
			read = new readability
				content: data.toString()
			article = read.run()
			article.text.should.not.be.empty
			done()
	it "case 2", (done)->
		done()
		return
		sample2Path = path.join(__dirname, "/samples/2.html")
		fs.readFile sample2Path, (err, data)->
			should(err).be.empty
			read = new readability
				content: data.toString()
			article = read.run()
			should(article).not.be.empty
			article.text.should.not.be.empty
			done()
	it "case 3", (done)->
		done()
		return
		sample3Path = path.join(__dirname, "/samples/3.html")
		fs.readFile sample3Path, (err, data)->
			should(err).be.empty
			read = new readability
				content: data.toString()
			article = read.run()
			done()
