angular
.module 'remodra-main'
.service 'Remocra', ($http) ->
  console.log  ' in reference service'

  return  {
    reference:()->
      $http.get '/ref.json'
    get: (id)->
      $http.get '/pibi/'+id
    save: (hydrant)->
      $http.post '/pibi/'+hydrant?.hydrant?.id , hydrant

  }