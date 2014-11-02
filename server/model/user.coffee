Promise = require "bluebird"
Structure = require "./structure"
persister = require '../lib/persister.js'

persister = null
class User
  id:null
  structure_id:null
  populate: ()->
    persister.get 'user' , @id
      .then (res)=>
        _.each res, (val,key)=>
          this[key] = val
    return Promise.resolve()
  constructor : (@id)->
    null
  getTerritoiresInteresct : ()->
    s = new Structure @structure_id
    s.getTerritoiresInteresct()

module.exports =   User