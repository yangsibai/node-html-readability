##html-readability

node.js html readability parser

[![NPM](https://nodei.co/npm/html-readability.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/html-readability/)

###Get started

    var readability = require("readability");
    var html = "<html>xxxxxxxxxxx</html>";
    var article = readability.parse(html);
    console.log(article.title);
    console.log(article.text);

###Parse result

    var article = {
       title: "", // page title 
       text: "", //text content
       html: "", //pretty html content
       time: {
           title: 10, //parse title elapsed milliseconds
           article: 100 //parse content elapsed milliseconds
       }
    };
