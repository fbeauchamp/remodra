angular
.module 'remodra-main'
.service 'Remocra', ($http) ->
  console.log  ' in reference service'

  return  {
    reference:(cache=true)->
      $http.get '/ref.json' , {cache:cache}
    pibi:
      all: (cache=true)->
        $http.get '/pibis' , {cache:cache}
          .then (http_res)->
            http_res.data
      get: (id,cache=true)->
        $http.get '/pibi/'+id , {cache:cache}
      save: (hydrant)->
        $http.post '/pibi/'+hydrant?.hydrant?.id , hydrant
    tournee:
      all: (cache=true)->
        $http.get '/tournees' , {cache:cache}
          .then (http_res)->
            http_res.data
      get: (id,cache=true)->
          $http.get '/tournee/'+id , {cache:cache}
            .then (http_res)->
              http_res.data

      save: (tournee)->
        $http.post '/pibi/'+tournee?.id , tournee


  }