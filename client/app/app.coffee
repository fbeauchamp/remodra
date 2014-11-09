angular.module 'remodra', [ 'ngRoute','remodra-main','templates','leaflet-directive' ]
  
  .config ($routeProvider) ->
    console.log $routeProvider
    $routeProvider
      .when '/pibi' ,
        templateUrl: 'main/templates/pibi-list.html'
        controller: 'PibiListCtrl'
      .when '/pibi/modifier/:id?' ,
        templateUrl: 'main/templates/pibi-form.html'
        controller: 'PibiCtrl'
      .when '/tournee' ,
        templateUrl: 'main/templates/liste-tournee.html'
        controller: 'ListetourneeCtrl'
      .when '/tournee/detail/:id' ,
        templateUrl: 'main/templates/detail-tournee.html'
        controller: 'DetailtourneeCtrl'
      .when '/carte' ,
        templateUrl: 'main/templates/map.html'
        controller: 'MapCtrl'
      .when '/annuaire' ,
        templateUrl: 'main/templates/directory.html'
        controller: 'DirectoryCtrl'
      .when '/' ,
        templateUrl: 'main/main.html'
        controller: 'MainCtrl'
      .otherwise
        redirectTo: '/'