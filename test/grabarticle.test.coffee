readability = require '../lib/index'
path = require 'path'
fs = require 'fs'
assert = require 'assert'

describe 'readability test', ()->
    it 'case 1', (done)->
        sample1Path = path.join(__dirname, '/samples/1.html')
        fs.readFile sample1Path, (err, data)->
            assert.equal(err, null)
            readability.parse data.toString(), (err, article)->
                assert.equal(err, null)
                assert(article.text.length > 0)
                done()

    it 'case 2', (done)->
        sample2Path = path.join(__dirname, '/samples/2.html')
        fs.readFile sample2Path, (err, data)->
            assert.equal(err, null)
            readability.parse data.toString(), (err, article)->
                assert.equal(err, null)
                assert(article.text.length > 0)
                done()

    it 'case 3', (done)->
        sample3Path = path.join(__dirname, '/samples/3.html')
        fs.readFile sample3Path, (err, data)->
            assert.equal(err, null)
            readability.parse data.toString(), (err, article)->
                assert.equal(err, null)
                assert(article.text.length > 0)
                done()

    it 'url test', (done)->
        readability.parse 'http://www.mockplus.cn/blog/post/5', (err, article)->
            assert.equal(err, null)
            assert(article.text.length > 0)
            done()

    it 'invalid parameter test', (done)->
        readability.parse 1, (err, article)->
            assert.ok(err)
            done()