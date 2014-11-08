angular.module 'remodra-main'
.controller 'DetailtourneeCtrl', ($scope,Remocra,$routeParams) ->
  $scope.tournee =
    id:1
    name: "Macon 1"
    size: 10
    color : '#F00'
    pibis:[]

  Remocra.tournee.get 11
    .then (pibis)->
      console.log ' got it'
      console.log pibis
      $scope.tournee.pibis = pibis

  $scope.availablepibis = []
  $scope.availablepibis.push
    id:3
    adresse: "à l'angle de toto et tata"
    statut: "DISPO"
    date:"30/01/2014"
  $scope.availablepibis.push
    id:4
    adresse: "à l'angle de toto et tata"
    statut: "DISPO"
    date:"30/01/2014"

  $scope.reset = ->
    console.log 'reset'
    _.each $scope.availablepibis , (pibi)->
      pibi.selected = false;

  $scope.remove = (id)->
    $scope.tournee.pibis = _.filter $scope.tournee.pibis , (pibi)->
      pibi.id != id

  $scope.add = ->
    console.log 'reset'
    _.each $scope.availablepibis , (pibi)->
      if !!pibi.selected
        pibi.selected = false;
        $scope.tournee.pibis.push pibi

