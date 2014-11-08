
persister = require '../lib/persister.js'

class PIBI
  id:null
  details: {}
  structure: null

  constructor : (@id)->
    @details ={}
    @
  populate: (opts)->
    persister.get 'remocra.hydrant' , @id
      .then (pgres)=>
        @details.hydrant=pgres.rows[0]
        persister.get 'remocra.hydrant_pena' , @id
      .then (pgres)=>
        @details.pena=pgres.rows[0]
        persister.get 'remocra.hydrant_pibi' , @id
      .then (pgres)=>
        @details.pibi=pgres.rows[0]
        persister.where 'remocra.hydrant_anomalies' ,  {hydrant:@id}
      .then (pgres)=>
        @details.anomalies=pgres.rows ||[]
        @



module.exports = PIBI;