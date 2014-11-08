angular
.module 'remodra-main'
.service 'Remocra', ($http) ->
  console.log  ' in reference service'

  return  {
    reference:()->
      $http.get '/ref.json'
    pibi:
      get: (id)->
        $http.get '/pibi/'+id
      save: (hydrant)->
        $http.post '/pibi/'+hydrant?.hydperant?.id , hydrant
    tournee:
      all: ->
        $http.get '/tournees'
          .then (http_res)->
            http_res.data
      get: (id)->
          $http.get '/tournee/'+id
            .then (http_res)->
              http_res.data

      save: (tournee)->
        $http.post '/pibi/'+tournee?.id , tournee


  }