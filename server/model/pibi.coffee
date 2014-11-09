
persister = require '../lib/persister.js'
_ = require 'lodash'

class PIBI
  id:null
  details: {}
  structure: null

  constructor : (@id,@details={})->
    @
  populate: (opts)->
    persister.get 'remocra.hydrant' , @id
      .then (pgres)=>
        @details.hydrant = _.transform pgres.rows[0], (res, v, k) ->
          if v!= null
              res[k] = v
        persister.get 'remocra.hydrant_pena' , @id
      .then (pgres)=>
        @details.pena = _.transform pgres.rows[0], (res, v, k) ->
          if v!= null
            res[k] = v
        persister.get 'remocra.hydrant_pibi' , @id
      .then (pgres)=>
        @details.pibi = _.transform pgres.rows[0], (res, v, k) ->
          if v!= null
            res[k] = v
        persister.where 'remocra.hydrant_anomalies' ,  {hydrant:@id}
      .then (pgres)=>
        @details.anomalies = _.transform pgres.rows[0], (res, v, k) ->
          if v!= null
            res[k] = v
        @



module.exports = PIBI;