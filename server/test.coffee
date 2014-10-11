wkhtmltopdf = require 'wkhtmltopdf'
fs = require 'fs'
jade = require 'jade'


html = jade.renderFile 'templates/sommairetournee.jade' , {}


wkhtmltopdf(html, {  })
.pipe(fs.createWriteStream('out.pdf'))
