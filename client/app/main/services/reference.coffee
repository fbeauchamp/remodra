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
        $http.post '/pibi/'+hydrant?.hydrant?.id , hydrant
    tournee:
      all: ->
        $http.get '/tournees'
      save: (tournee)->
        $http.post '/pibi/'+tournee?.id , tournee


  }