angular.module 'remodra', [ 'ngRoute','remodra-main','templates','leaflet-directive' ]
  
  .config ($routeProvider) ->

    $routeProvider
      .otherwise
        redirectTo: '/'