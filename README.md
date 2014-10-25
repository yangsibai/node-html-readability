##html-readability

node.js html readability parser

[![NPM](https://nodei.co/npm/html-readability.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/html-readability/)

###Get started

    var readability = require("readability");
    var html = "<html>xxxxxxxxxxx</html>";
    readability.parse(html, function(err, article){
        /* article
            article = {
                title: "", // page title 
                text: "", //text content
                html: "", //pretty html content
                time: {
                   title: 10, //parse title elapsed milliseconds
                   article: 100 //parse content elapsed milliseconds
                }
            }
        */
    });

###Usage

**1. pass a object:**

    var options = {
        url: "http://example.com/article/some-article.html", // url is optional, if supply, can convert relative url to absolute.
        content: "<html>some html</html>"
    };

    readability.parse(options, function(err, article){
        //some code
    });

**2. pass a html string:**

    var html = "<html>some html</html>";

    readability.parse(html, function(err, article){
        //some code
    });

**3. pass a url:**

    var url = "http://example.com/article/some-article.html";

    readability.parse(url, function(err, article){
        //some code
    });
