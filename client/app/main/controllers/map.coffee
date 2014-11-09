angular
  .module 'remodra-main'
  .controller 'MapCtrl', ($scope,leafletData,$routeParams,Remocra,$compile) ->
    console.log ' in carte controller'
    console.log $routeParams
    $scope.tournees = []
    $scope.alerte = {}
    Remocra.tournee.all()
      .then (tournees)->
        $scope.tournees = tournees

    $scope.center =
      lat:  parseFloat($routeParams.lat)  ||46.3
      lng: parseFloat($routeParams.lng) || 4.83
      zoom: if  $routeParams.lat then 20 else 14

    $scope.events =
      map:
        enable: ['click', 'dblclick', 'mousedown', 'mouseup', 'mouseover', 'mouseout', 'mousemove', 'contextmenu', 'focus', 'blur', 'preclick', 'load', 'unload', 'viewreset', 'movestart', 'move', 'moveend', 'dragstart', 'drag', 'dragend', 'zoomstart', 'zoomend', 'zoomlevelschange', 'resize', 'autopanstart', 'layeradd', 'layerremove', 'baselayerchange', 'overlayadd', 'overlayremove', 'locationfound', 'locationerror', 'popupopen', 'popupclose'],
        logic: 'broadcast'
    $scope.clickAction = 'select';

    loadData = (bbox,cb)->
      Remocra.pibi.all()
        .then (pibis)->
          json = _.filter pibis , (pibi)->
            lat = parseFloat pibi.hydrant.lat
            lng = parseFloat pibi.hydrant.lng
            (lat >bbox[0][0] and lng >bbox[0][1] and lat <bbox[1][0] and lng <bbox[1][1])
          cb(_.pluck json , 'hydrant')
    buildIcon = (pibi,title)->
      className =  if pibi.code =='PIBI' then 'fa fa-circle' else 'fa fa-square'
      color = if pibi.tournee then 'blue' else 'black'
      html = "<i class='#{ className }' STYLE='color:#{ color };display:block;'></i>"
      if pibi.dispo_terrestre != 'DISPO'
        html += "<i class='fa fa-ban' STYLE='color:red;display:block;position:absolute;top:-0.125em;left:-0.125em;font-size:150%'></i>"
      new L.DivIcon {html:html}

    leafletData.getMap().then (map)->
      L.Icon.Default.imagePath = 'images'
      ClickControl = L.Control.extend
        options:
          position: 'topleft'
        onAdd:  (map) ->
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
      new L.Map.BoxSelect(map)

      showPopup = (json,marker)->
        html = '<table><tr><th></th><th></th></tr>';
        _.each json , (val,key)->
          if val
            html+='<tr><td>'+key+'</td><td>'+val+'</td>'
        html += '</table>';
        html +='<a class="btn btn-primary" href="#/pibi/modifier/'+json.id+'">Modifier</a>';
        marker
          .bindPopup html
          .openPopup()

      $scope.selection =[];
      $scope.emptySelection = ->
        _.each $scope.selection , (selected)->
          L.DomUtil.removeClass selected._icon , 'blink'
        $scope.selection =[]
      $scope.ajouterTournee = ->
        console.log ' ajouter à la tournéee'

        Promise.all _.map $scope.selection , (selected)->
          console.log selected
          Remocra.pibi.setTournee selected.options.id , $scope.tournee.id
        .then (res)->
          console.log 'saved'


      addMarkerToSelection =(marker)->
        alreadyIn= _.find $scope.selection , (selected)->
          selected.options.id ==  marker.options.id
        if !alreadyIn
          $scope.selection.push marker
          L.DomUtil.addClass marker._icon , 'blink'

      layerJSON = new L.LayerJSON
          propertyLoc:null
          minZoom: 14
          callData: loadData
          buildIcon: buildIcon

          onEachMarker: (json,marker)->
            marker.on 'click' , (event)->
              if event.originalEvent.ctrlKey
                addMarkerToSelection(marker)
              else
                $scope.emptySelection()
                showPopup(json,marker)



      map.addLayer(layerJSON);

      selectionStartPoint = null
      selectionEndPoint = null
      selectionBox = null

      $scope.$on 'leafletDirectiveMap.mousedown' , (event,leaflet_event)->
        if leaflet_event.leafletEvent.originalEvent.ctrlKey
          map.dragging.disable();
          L.DomUtil.disableTextSelection();
          selectionStartPoint = map.mouseEventToLayerPoint(leaflet_event.leafletEvent.originalEvent)
          selectionBox=L.DomUtil.create('div', 'leaflet-zoom-box', map._panes.overlayPane);
          L.DomUtil.setPosition(selectionBox, selectionStartPoint);

      $scope.$on 'leafletDirectiveMap.mousemove' , (event,leaflet_event)->
        if selectionStartPoint && leaflet_event.leafletEvent.originalEvent.ctrlKey
          selectionEndPoint = map.mouseEventToLayerPoint(leaflet_event.leafletEvent.originalEvent)
          offset = selectionEndPoint.subtract(selectionStartPoint)
          newPos = new L.Point(
            Math.min(selectionEndPoint.x, selectionStartPoint.x),
            Math.min(selectionEndPoint.y, selectionStartPoint.y));

          L.DomUtil.setPosition(selectionBox, newPos)

          selectionBox.style.width  = (Math.max(0, Math.abs(offset.x) - 4)) + 'px';
          selectionBox.style.height = (Math.max(0, Math.abs(offset.y) - 4)) + 'px';

      $scope.$on 'leafletDirectiveMap.mouseup' , (event,leaflet_event)->
        if selectionStartPoint && leaflet_event.leafletEvent.originalEvent.ctrlKey
          map.dragging.enable();
          L.DomUtil.enableTextSelection();
          addToSelection()
          selectionStartPoint = null
          selectionEndPoint = null
          map._panes.overlayPane.removeChild(selectionBox);

      $scope.$on 'leafletDirectiveMap.mouseout' , (event,leaflet_event)->
        map.dragging.enable();
        L.DomUtil.enableTextSelection();
      addToSelection =->
        bounds = new L.LatLngBounds(
          map.layerPointToLatLng(selectionStartPoint),
          map.layerPointToLatLng(selectionEndPoint));
        _.each layerJSON._markersCache , (marker)->
          if bounds.contains(marker._latlng)
            addMarkerToSelection(marker)

    $scope.creerAlerte = ->
      console.log "creer alert"
      console.log $scope.alerte
      Remocra.alerte.save $scope.alerte.commentaire , $scope.alerte.latlng.lat , $scope.alerte.latlng.lng

    $scope.$on 'leafletDirectiveMap.click' , (event, leaflet_event)->
      if $scope.clickAction == 'marker'
        popup = L.popup({minWidth: 350})
          .setContent(
            '<h4>Créer une alerte</h4>
              <form class="form-horizontal" role="form">
                <div class="form-group">
                  <label class="col-sm-2 control-label">Type</label>
                  <div class="col-sm-10">
                  <select class="form-control" ng-model="alerte.type">
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
                  <textarea class="form-control" rows="5"  ng-model="alerte.commentaire"></textarea>
                  </div>
                  </div>
                  </form>
                  <a class="btn btn-primary" ng-click="creerAlerte()">Créer</a> ')
          .setLatLng(leaflet_event.leafletEvent.latlng)
        $scope.alerte.latlng = leaflet_event.leafletEvent.latlng
        leafletData.getMap().then (map)->
          popup.openOn(map)

          $compile(popup._contentNode)($scope)

          if (!$scope.addMarker)
            return;
          $scope.eventDetected = event_type;



