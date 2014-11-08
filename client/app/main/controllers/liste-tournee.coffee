angular.module 'remodra-main'
.controller 'ListetourneeCtrl', ($scope,Remocra,$routeParams) ->
  $scope.tournees =[]
  Remocra.tournee.all()
    .then (tournees)->
      $scope.tournees = tournees

      ###
  $scope.tournees.push
    id:1
    name: "Macon 1"
    city: "MACON"
    size: 10
    color: '#F00'
###
