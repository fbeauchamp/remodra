angular
.module 'remodra-main'
.service 'Remocra', ($http) ->
  console.log  ' in reference service'

  ref=  {
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
      setTournee: (pibi_id,tournee_id)->
        $http.post '/pibi/'+pibi_id+'/tournee' , {id:pibi_id,tournee:tournee_id}
    tournee:
      all: (cache=true)->
        $http.get '/tournees' , {cache:cache}
          .then (http_res)->
            http_res.data
      get: (id,cache=true)->
        ref.pibi.all()
          .then (pibis)->
            console.log ' now filter'
            _.filter pibis , (pibi)->
              pibi.hydrant.tournee == id


      save: (tournee)->
        $http.post '/pibi/'+tournee?.id , tournee


  }

  ref