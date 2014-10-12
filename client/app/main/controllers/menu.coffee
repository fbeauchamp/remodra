angular.module 'remodra-main'
.controller 'TopMenuCtrl', ($scope , $location) ->

  $scope.getClass = (path)->
    if path == '/'
      if $location.path() == '/'
        "active"
      else
        ""
    else
      if  $location.path().substr(0, path.length) == path
        "active"
      else
        ""

