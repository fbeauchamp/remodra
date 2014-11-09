persister = require './lib/persister.js'
_ = require 'lodash'
require 'coffee-script/register'
Promise = require 'bluebird'
express = require 'express'
User = require('./model/user')
PIBI = require('./model/pibi')
app = express()
mssql = require 'mssql'
'use strict'

env = process.env.NODE_ENV || 'prod';
config = require './config.dev.js'

if !!config.mssql
  mssql.connect config.mssql , (err)->
    console.log 'MSSQSL';
    console.log err
app.use(express.compress());
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
    console.log e


persister.query "select id,nom,insee,pprif,code from remocra.commune" , []
  .then (res)->
    references['commune'] =[]
    _.each res.rows , (row)->
      references['commune'][row.id]=row
  .catch (e)->
    console.log e


persister.query "select distinct anomalie, nature, val_indispo_terrestre from remocra.type_hydrant_anomalie_nature where val_indispo_terrestre >0 " , []
  .then (res)->
    references['type_hydrant_anomalie_nature'] =res.rows
  .catch (e)->
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
  pibi =new PIBI(id)
  pibi.populate()
    .then ->
      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify pibi.details
      res.end()
    .catch (e)->
      res.write 'fail'
      res.write e.message
      res.end()


app.get '/pibis' , (req,res)->
  pibis = {}
  persister.where('remocra.hydrant',{})
    .then (pg_res)->
      pibis = _.map pg_res.rows , (row)->
        row = _.transform row, (res, v, k) ->
          if v!= null
            res[k] = v
        {id:row.id,hydrant:row}
      persister.where('remocra.hydrant_pena',{})
    .then (pg_res)->
      _.each pg_res.rows , (row)->
        row = _.transform row, (res, v, k) ->
          if v!= null
            res[k] = v
        pibi =_.find pibis , {id:row.id}
        pibi.pena =row if pibi
      persister.where('remocra.hydrant_pibi',{})
    .then (pg_res)->
      _.each pg_res.rows , (row)->
        row = _.transform row, (res, v, k) ->
          if v!= null
            res[k] = v
        pibi =_.find pibis , {id:row.id}
        pibi.pibi =row if pibi
      persister.where('remocra.hydrant_anomalies',{})
    .then (pg_res)->
      _.each pg_res.rows , (row)->

        row = _.transform row, (res, v, k) ->
          if v!= null
            res[k] = v
        pibi =_.find pibis , {id:row.id}
        pibi.anomalies =row if pibi

      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify pibis
      res.end()
    .catch (e)->
      res.write 'fail '
      res.write e.message
      console.log e
      res.end()


app.get '/geojson.json' , (req,res)->
  persister.query('SELECT *,ST_AsGeoJSON(ST_Transform(geometrie, 4326)) as geometrie  from remocra.hydrant
    WHERE ST_X((ST_Transform(geometrie, 4326))) BETWEEN $1 and $2
  AND ST_Y((ST_Transform(geometrie, 4326))) BETWEEN $3 AND $4   ',
    [req.query.lon1,req.query.lon2,req.query.lat1,req.query.lat2])
  .then (pgres)->
      json = []
      _.each pgres.rows, (row)->

        json.push
          type:'feature'
          geometry:JSON.parse row.geometrie
          properties:
            _.clone _.omit row , 'geometrie'

      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify json
      res.end()
  .catch (e)->
    res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
    res.setHeader 'Content-type' , 'application/json'
    res.charset = 'utf-8'
    res.write '[]'
    res.end()
    console.log e



app.get '/annuaire.json', (req,res)->
  console.log ('get annnuaire')
  #todo : handle session
  user_id = 1
  user = new User(user_id)
  fiches =[]
  user
    .populate()
    .then ()->
      user.getTerritoiresInteresct()
    .then (territoires)->
      Promise.all  _.map territoires , (territoire)->
        territoire.getStructures()
    .spread (structures)->
      structures = _.compact  structures , true # the promise result is an arry aof array of structures
      structures = _.uniq structures , 'id'
      Promise.all  _.map structures , (structure)->
        structure.getFiches({populate_level:1})
    .spread (fiches)->
      fiches = _.compact  fiches , true
      fiches = _.uniq fiches , 'id'
      console.log fiches
      # todo : add structure this user admin
    .catch (e)->
      console.log e


app.get '/contacts' , (req,res)->
  request = new mssql.Request()
  request.query "SELECT  f.fiche_id as id,nom,prenom,label_gipsi as structure,r.label as role, valeur,fdt.label as type_contact,commentaire
    FROM [ANNUAIRE].[dbo].[FICHE] f
    inner join [ANNUAIRE].[dbo].[COMMUNE] c  on c.commune_id = f.commune_id
    inner join [ANNUAIRE].[dbo].rubrique_fiche rf on rf.fiche_id = f.fiche_id
    inner join [ANNUAIRE].[dbo].rubrique r on r.rubrique_id = rf.rubrique_id
    inner join [ANNUAIRE].[dbo].fiche_donnee fd on fd.fiche_id = f.fiche_id
    inner join [ANNUAIRE].[dbo].fiche_donnee_type fdt on fdt.type_id = fd.type_id
    WHERE r.label IN ('MAIRE','ELU 2','ELU 3','ELU 4','ELU 5')
    "
    , (err,rs)->
      json =[]
      _.each rs , (row)->
        if json[row.id]
          json[row.id].contact[row.type_contact.toLowerCase()] = row.valeur
        else
          row.contact={}
          row.contact[row.type_contact.toLowerCase()]=row.valeur
          delete row.type_contact
          delete row.valeur
          delete row.commentaire
          json[row.id]= _.clone row

      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify _.compact json
      res.end()

app.get '/tournees' , (req,res)->
  persister.where 'remocra.tournee' , {}
  .then (pgres)->
    res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
    res.setHeader 'Content-type' , 'application/json'
    res.charset = 'utf-8'
    res.write JSON.stringify pgres.rows
    res.end()
  .catch (e)->
    res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
    res.setHeader 'Content-type' , 'application/json'
    res.charset = 'utf-8'
    res.write '[]'
    res.end()
    console.log e

app.get '/tournee/:id' , (req,res)->
  id = req.params.id
  persister.where 'remocra.hydrant' , {tournee:id}
    .then (res)->
      pibis = _.map res.rows , (row)->
        new PIBI row.id
      Promise.all _.map pibis , (pibi)->
        pibi.populate()
    .spread (pibis)->

      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write JSON.stringify _.pluck pibis , 'details'
      res.end()
    .catch (e)->
      res.setHeader 'Cache-Control' , 'no-cache, must-revalidate'
      res.setHeader 'Content-type' , 'application/json'
      res.charset = 'utf-8'
      res.write '[]'
      res.end()
      console.log e

app.get 'pdf' , (req,res)->



app.use('/', express.static('../client/build/'));

server = app.listen(9001);
