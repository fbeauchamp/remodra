persister = require './lib/persister.js'
_ = require 'lodash'
Promise = require 'bluebird'
express = require 'express'
app = express()

'use strict'

env = process.env.NODE_ENV || 'prod';
config = require './config.dev.js'

app.use(express.json());
app.use(express.urlencoded());
app.use(express.multipart());
app.use(express.cookieParser(config.cookieSecret));


references ={}
sources_ref_activable =[
  'remocra.type_alerte_ano'
  'remocra.type_alerte_elt'
  'remocra.type_hydrant'
  'remocra.type_hydrant_critere'
  'remocra.type_hydrant_diametre'
  'remocra.type_hydrant_domaine'
  'remocra.type_hydrant_marque'
  'remocra.type_hydrant_materiau'
  'remocra.type_hydrant_nature'
  'remocra.type_hydrant_modele'
  'remocra.type_hydrant_positionnement'
  'remocra.type_organisme'
  ]
_.each sources_ref_activable , (source)->
  persister.query "select * from "+source+" WHERE actif= TRUE" , []
    .then (res)->
      references[source.split('.')[1]]=res.rows
    .catch (e)->
      console.log source
      console.log e


sources_ref =[
  'remocra.type_hydrant_anomalie'
  'remocra.type_hydrant_anomalie_nature'
  'remocra.type_hydrant_anomalie_nature_saisies'
  'remocra.type_hydrant_diametre_natures'
]
_.each sources_ref , (source)->
  persister.query "select * from "+source , []
  .then (res)->
    references[source.split('.')[1]]=res.rows
  .catch (e)->
    console.log source
    console.log e


persister.query "select id,nom,insee,pprif,code from remocra.commune" , []
  .then (res)->
    references['commune'] =[]
    _.each res.rows , (row)->
      references['commune'][row.id]=row
  .catch (e)->
    console.log source
    console.log e


persister.query "select distinct anomalie, nature, val_indispo_terrestre from remocra.type_hydrant_anomalie_nature where val_indispo_terrestre >0 " , []
  .then (res)->
    references['type_hydrant_anomalie_nature'] =res.rows
  .catch (e)->
    console.log source
    console.log e



app.get '/ref.json' , (req,res)->
  res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
  res.setHeader 'Content-type' , 'application/json'
  res.charset = 'utf-8'
  res.write JSON.stringify references
  res.end()

app.post '/pibi/:id' , (req,res)->
  to_be_saved = req.body
  console.log 'will save '
  console.log to_be_saved
  persister.upsert 'remocra.hydrant' , req.body.hydrant
    .then (pgres)->
      console.log 'saved hydrant '
      console.log pgres
      persister.upsert 'remocra.hydrant_pibi' , req.body.pibi
    .then (pgres)->
      console.log 'saved pibi '
      persister.query  'DELETE FROM remocra.hydrant_anomalies WHERE hydrant = $1 ' , [req.body.hydrant.id]
    .then (pgres) ->
      console.log pgres
      promises = []
      _.each req.body.anomalies , (anomalie)->
        console.log ' will save '
        console.log anomalie
        promises.push persister.insert  'remocra.hydrant_anomalies' , anomalie
      Promise.all promises
    .then ()->
      console.log " all anomalies"

      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify {code:200,errors:[]}
      res.end()
    .catch (e)->
      console.log e
      res.end()


app.get '/pibi/:id' , (req,res)->
  id = req.params.id
  pibi ={}
  persister.get 'remocra.hydrant' , id
    .then (pgres)->
      pibi.hydrant=pgres.rows[0]
      persister.get 'remocra.hydrant_pena' , id
    .then (pgres)->
      console.log pgres
      pibi.pena=pgres.rows[0]
      persister.get 'remocra.hydrant_pibi' , id
    .then (pgres)->
      console.log pgres
      pibi.pibi=pgres.rows[0]
      persister.where 'remocra.hydrant_anomalies' ,  {hydrant:id}
    .then (pgres)->
      pibi.anomalies=pgres.rows ||[]
      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify pibi
      res.end()
    .catch (e)->
      res.write 'fail'
      res.write e.message
      res.end()


app.use('/', express.static('../client/build/'));

server = app.listen(9001);

###
.then (pgres)->
  pibi.pena=pgres.rows[0]
  persister.where 'remocra.hydrant_anomalies' ,  {hydrant:id}
.then (pgres)->
  pibi.anomalies=pgres.rows
  persister.get 'remocra.hydrant_pibi' , id
###