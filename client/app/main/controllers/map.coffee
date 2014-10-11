angular
  .module 'remodra-main'
  .controller 'MapCtrl', ($scope,leafletData) ->
    console.log ' in carte controller'

    $scope.center =
      lat:  46.3
      lng: 4.83
      zoom: 14

    $scope.markers = {};
    $scope.events =
      map:
        enable: ['click', 'dblclick', 'mousedown', 'mouseup', 'mouseover', 'mouseout', 'mousemove', 'contextmenu', 'focus', 'blur', 'preclick', 'load', 'unload', 'viewreset', 'movestart', 'move', 'moveend', 'dragstart', 'drag', 'dragend', 'zoomstart', 'zoomend', 'zoomlevelschange', 'resize', 'autopanstart', 'layeradd', 'layerremove', 'baselayerchange', 'overlayadd', 'overlayremove', 'locationfound', 'locationerror', 'popupopen', 'popupclose'],
        logic: 'broadcast'
    $scope.clickAction = 'select';

    leafletData.getMap().then (map)->
      L.Icon.Default.imagePath = 'images'
      ClickControl = L.Control.extend
        options:
          position: 'topleft'
        onAdd:  (map) ->
          console.log 'clo'
          container = L.DomUtil.create 'div' , ' leaflet-bar leaflet-control remodra-control-bar '
          L.DomEvent
            .addListener container , 'click' , L.DomEvent.stopPropagation
            .addListener container , 'click' , L.DomEvent.preventDefault
          markerbtn = L.DomUtil.create 'a' , ' ' , container
          selectbtn = L.DomUtil.create 'a' , ' active ', container
          markerbtn.innerHTML = '<i class="fa fa-map-marker"></i>'

          L.DomEvent
            .addListener markerbtn , 'click', L.DomEvent.stopPropagation
            .addListener markerbtn , 'click', L.DomEvent.preventDefault
            .addListener markerbtn , 'click', ->
              $scope.clickAction = 'marker';
              L.DomUtil.removeClass selectbtn, 'active'
              L.DomUtil.addClass markerbtn , 'active'

          selectbtn.innerHTML = '<i class="fa fa-info-circle"></i>';
          L.DomEvent
            .addListener selectbtn , 'click' , L.DomEvent.stopPropagation
            .addListener selectbtn , 'click' , L.DomEvent.preventDefault
            .addListener selectbtn , 'click' , ->
              $scope.clickAction = 'select';
              console.log($scope.clickAction);
              L.DomUtil.removeClass(markerbtn, 'active');
              L.DomUtil.addClass(selectbtn, 'active');

          container

      map.addControl(new ClickControl())

      l = new L.LayerJSON
          propertyLoc:'geometry.coordinates'
          minZoom: 14
          url: "/geojson.json?lat1={lat1}&lat2={lat2}&lon1={lon1}&lon2={lon2}"
          onEachMarker: (json,marker)->
            marker.on 'click' , ()->
              html = '<table><tr><th></th><th></th></tr>';
              _.each json.properties , (val,key)->
                if val
                  html+='<tr><td>'+key+'</td><td>'+val+'</td>'
              html += '</table>';
              html +='<a class="btn btn-primary" href="#/pibi/'+json.properties.id+'">Modifier</a>';
              marker
                .bindPopup html
                .openPopup()


      map.addLayer(l);

      $scope.eventDetected = "No events yet...";
    _.each ['click'] , (event_type)->
      $scope.$on 'leafletDirectiveMap.' + event_type , (event, leaflet_event)->
        if $scope.clickAction == 'marker'
          popup = L.popup({minWidth: 350})
            .setContent(
              '<h4>Créer une alerte</h4>
                <form class="form-horizontal" role="form">
                  <div class="form-group">
                    <label class="col-sm-2 control-label">Type</label>
                    <div class="col-sm-10">
                    <select class="form-control">
                    <option>Anomalie 1</option>
                    <option>Anomalie 2</option>
                    <option>Anomaie 3</option>
                    <option>Anomalie 4</option>
                    <option>Anomalie 5</option>
                    </select>
                    </div>
                    </div>
                    <div class="form-group">
                    <label class="col-sm-2 control-label">Desc</label>
                    <div class="col-sm-10">
                    <textarea class="form-control" rows="5"></textarea>
                    </div>
                    </div>
                    </form>
                    <a class="btn btn-primary">Créer</a>
                    <a class="btn btn-danger">annuler</a>')
            .setLatLng(leaflet_event.leafletEvent.latlng);
          leafletData.getMap().then (map)->
            popup.openOn(map)


          if (!$scope.addMarker)
            return;
          $scope.eventDetected = event_type;


