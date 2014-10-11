angular.module 'remodra', [ 'ngRoute','remodra-main','templates','leaflet-directive' ]
  
  .config ($routeProvider) ->
    console.log $routeProvider
    $routeProvider
      .when '/pibi/:id' ,
        templateUrl: 'main/templates/pibi-form.html'
        controller: 'PibiCtrl'
      .when '/map' ,
        templateUrl: 'main/templates/map.html'
        controller: 'MapCtrl'
      .when '/' ,
        templateUrl: 'main/main.html'
        controller: 'MainCtrl'
      .otherwise
        redirectTo: '/'