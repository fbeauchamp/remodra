Promise = require "bluebird"
persister = require '../lib/persister.js'

persister = null

class Structure
  id:null
  constructor : (@id)->
    null
  getFiches: (opts)->
    if opts.populate
        console.log " populate fiche before retunrinig it "
    persister
      .where  'fiche' , {structure_id:@id}
      .then (fiches)->
        return Promise.resolve fiches unless opts?.populate_level

        Promise.all  _.map fiches , (fiche)->
          fiche.populate({populate_level:opts?.populate_level})

  #return all th territory intersecting  my territory
  getTerritoiresInteresct: ->
    return persister.query 'SELECT t.id
                FROM
                  territoire t INNER JOIN territoire t_visible ON INTERSCTION
                  INNER JOIN  structure s ON s.territoire_id = t_visible.id
                  WHERE s.id = $1 ',[@id]


module.exports = Structure