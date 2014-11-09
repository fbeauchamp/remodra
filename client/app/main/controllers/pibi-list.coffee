angular.module 'remodra-main'
.controller 'PibiListCtrl', ($scope,Remocra,$routeParams) ->
  console.log 'pibilist'
  $scope.pibis = []
  $scope.tournees =[]
  $scope.dispos =[{id:'',label:''},{id:'DISPO',label:'Disponible'},{id:'INDISPO',label:'Indisponible'}]
  $scope.filter =
    nom:null
    emplacement:null
    tournee : null

  Remocra.pibi.all()
    .then (pibis)->
      $scope.pibis = pibis;


  Remocra.tournee.all()
    .then (tournees)->
      $scope.tournees = tournees

  $scope.filterPibi = (pibi)->
    if $scope.filter.nom
      if !pibi.hydrant.numero or pibi.hydrant.numero.toLowerCase().indexOf($scope.filter.nom) ==-1
        return false
    if $scope.filter.emplacement
      if !pibi.hydrant.complement or pibi.hydrant.complement.toLowerCase().indexOf($scope.filter.emplacement) ==-1
        return false


    if $scope.filter.dispo
      if pibi.hydrant.dispo_terrestre != $scope.filter.dispo
        return false


    true