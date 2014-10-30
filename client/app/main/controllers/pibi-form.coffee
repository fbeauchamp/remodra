angular.module 'remodra-main'
.controller 'PibiCtrl', ($scope,Remocra,$routeParams) ->

  $scope.tabs=
    identification :
      showed:true
      active:true
    verification :
      showed:false
      active:false
    gestionnaire :
      showed:false
      active:false
    details :
      showed:false
      active:false
  $scope.current_check = 0

  $scope.changeTab = (target)->
    active_tab = _.find $scope.tabs , {active:true}
    active_tab.active = false if active_tab
    $scope.tabs[target].active=true
    $scope.tabs[target].showed=true


  $scope.modeleFromBrand =()->
    _.filter $scope.ref?.type_hydrant_modele , (model)->
      model.marque ==  $scope.pibi?.pibi?.marque

  $scope.toutAfficher = 0
  $scope.critere = 1

  $scope.toggleToutAfficher = ()->
    $scope.toutAfficher = !$scope.toutAfficher
  $scope.currentAnomalies =()->

    _.filter $scope?.pibi?.anomalies , (anomalie)->
        return false unless anomalie.critere == $scope.critere
        return false unless anomalie.nature == $scope.pibi?.hydrant?.nature
        $scope.toutAfficher || _.find $scope.ref?.type_hydrant_anomalie_nature , {anomalie:anomalie.anomalie,nature:anomalie.nature}

  $scope.nextCritere = ->
    $scope.critere = ($scope.critere + 1 ) %%9
    if $scope.currentAnomalies().length == 0
      $scope.nextCritere()
  $scope.prevCritere = ->
    $scope.critere = ($scope.critere - 1 ) %%9
    if $scope.currentAnomalies().length == 0
      $scope.prevCritere()



  Remocra.reference()
    .then (res)->
      $scope.ref=res.data
      console.log 'got ref ';
      console.log $scope.ref
      Remocra.pibi.get $routeParams.id
        .then (res)->
          anomalies =[]
          console.log 'got obj ';
          console.log  res.data.anomalies
          _.each $scope.ref?.type_hydrant_anomalie_nature , (ref_anomalie)->
            anomalie = _.clone ref_anomalie
            anomalie.checked =!!_.find res.data.anomalies , {anomalies:ref_anomalie.anomalie}
            def = _.find $scope.ref.type_hydrant_anomalie , {id:ref_anomalie.anomalie}
            anomalie.nom = def?.nom
            anomalie.critere = def?.critere
            anomalies.push anomalie

          $scope.pibi = res.data
          $scope.pibi.anomalies = anomalies

  $scope.save = ()->
    anomalies = _.filter $scope.pibi.anomalies , {checked:true}
    anomalies = _.map anomalies , (anomalie) ->
      {hydrant:$scope.pibi.hydrant.id, anomalies:anomalie.anomalie}

    $scope.pibi.anomalies =anomalies

    Remocra.pibi.save($scope.pibi)
      .then ( )->
        console.log 'success'
