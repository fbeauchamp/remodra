
persister = require '../lib/persister.js'

class Fiche
  id:null
  details: []
  structure: null

  constructor : (@id)->
    null
  populate: (opts)->
    filter =
      ficher_id : @id
    filter.level = opts.populate_level if opts.populate_level
    persister
      .where 'fiche_detail' , filter
      .then (details)=>
        @details = details
        @


class FicheDetail
  level : 0 #0 : hidden, 1 : just for admin of the same structure, 2 everybody on the same structure, 3 parent structre, 4  everybody on intersecting territory, 5 the whole world
  constructor: (@id,@key,@val)->
    null

module.exports = Fiche;