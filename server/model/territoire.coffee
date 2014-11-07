
persister = require '../lib/persister.js'
class Territoire
  constructor : (@id)->
    null
  id: null
  geom: null
  getStructures : ()->
    []
module.exports = Territoire;