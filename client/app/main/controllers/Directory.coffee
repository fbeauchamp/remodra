angular.module 'remodra-main'
.controller 'DirectoryCtrl', ($scope,$http) ->

  $scope.roles =[]
  $scope.structures =[]
  $scope.selected_role =null;
  $scope.selected_structure =null;

  $scope.contacts = []
  $scope.contacts.push
    structure : 'Mâcon (Ville)'
    role : 'Maire'
    nom : 'COURTOIS'
    prenom : 'Jean Patrick'
  $scope.contacts.push
    structure : 'Mâcon (CIS)'
    role : 'Chef de centre'
    nom : 'DELAIE'
    prenom : 'Philippe'

  $http.get '/contacts'
    .then (res)->
      console.log 'contacts'
      $scope.filtered_contacts = $scope.contacts = res.data
      $scope.structures = _.sortBy _.uniq _.compact _.pluck $scope.contacts , 'structure'
      $scope.roles = _.sortBy _.uniq _.compact _.pluck $scope.contacts , 'role'




  $scope.new_contact =
    priority : 0

  $scope.structures = _.sortBy _.uniq _.compact _.pluck $scope.contacts , 'structure'
  $scope.roles = _.sortBy _.uniq _.compact _.pluck $scope.contacts , 'role'



  $scope.toggleFilter = (type,value)->
    if $scope[type] == value
      $scope[type] = null
    else
      $scope[type] = value

    $scope.filtered_contacts = _.filter  $scope.contacts , (element)->
      (!$scope.selected_role or element.role == $scope.selected_role) and
      (!$scope.selected_structure or element.structure == $scope.selected_structure)

    $scope.structures = _.sortBy _.uniq _.compact _.pluck $scope.filtered_contacts , 'structure'
    $scope.roles = _.sortBy _.uniq _.compact _.pluck $scope.filtered_contacts , 'role'

  $scope.resetContact = ->
    $scope.modal_title="Création d'une nouvelle fiche"
    $scope.new_contact =
      priority : 0

  $scope.editContact = (contact)->
    $scope.modal_title="Modification d'une fiche"
    $scope.new_contact =   contact

  $scope.saveContact = (contact) ->
    console.log ' should save'