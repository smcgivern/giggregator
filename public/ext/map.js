var map = null;
var geocoder = null;
var timePeriods = [];

window.onload = attachMap;

function e(i) { return document.getElementById(i); }

function t(element) {
    if (typeof element == 'string') {
        return element;
    } else {
        return element.innerHTML;
    }
}

function s(className, element) {
    var spans = element.getElementsByTagName('span');

    for (var i = 0; i < spans.length; i++) {
        if (spans[i].className == className) { return spans[i]; }
    }
}

function attachMap() {
    if (google.maps.BrowserIsCompatible()) {
        if (e('address')) {
            createMap();

            addMarker(
                e('location'), e('address'), e('band'), e('time'),
                true
            );
        } else {
            showMapOptions();
        }
    }
};

function createMap() {
    map = new google.maps.Map2(e('map'));
    map.setUIToDefault();
    geocoder = new google.maps.ClientGeocoder();
    map.setCenter(new google.maps.LatLng(0, 0), 1);
}

function showMapOptions() {
    if (timePeriods.length == 0) { loadTimePeriods(); }

    var mapContainer = document.getElementById('map-container');
    var mapOptions = document.createElement('ol');
    var mapDiv = document.createElement('div');

    mapOptions.id = 'map-options';
    mapDiv.id = 'map';

    for (var i = 0; i < timePeriods.length; i++) {
        var li = document.createElement('li');
        li.id = 'map-options-' + timePeriods[i].id;
        li.innerHTML = timePeriods[i].name;

        inactiveOption(li);
        mapOptions.appendChild(li);
    }

    mapContainer.appendChild(mapOptions);
    mapContainer.appendChild(mapDiv);

    createMap();

    var first = document.getElementById('map-options').
        getElementsByTagName('li')[0];

    first.onclick.call(first);
}

function activeTimePeriod() {
    var selectedOption = this;
    var timePeriodId = this.id.replace('map-options-', '');
    var timePeriod = document.getElementById(timePeriodId);

    var mapOptions = document.getElementById('map-options');
    var lis = mapOptions.getElementsByTagName('li');
    var gigs = timePeriod.getElementsByTagName('li');

    for (var i = 0; i < lis.length; i++) { inactiveOption(lis[i]); }

    map.clearOverlays();
    selectedOption.onclick = null;
    selectedOption.className = 'active';

    for (var i = 0; i < gigs.length; i++) {
        var gig = gigs[i];

        addMarker(
            gig.getElementsByTagName('a')[0].title,
            s('address', gig), s('band', gig), s('time', gig)
        );
    }
}

function inactiveOption(li) {
    li.className = 'inactive';
    li.onclick = activeTimePeriod;
}

function loadTimePeriods() {
    var divs = document.getElementsByTagName('div');

    for (var i = 0; i < divs.length; i++) {
        var div = divs[i];

        if (div.className.indexOf('time-period') > -1) {
            timePeriods.push({
                name: t(div.getElementsByTagName('h2')[0]),
                id: div.id,
            });
        }
    }
}

function addMarker(location, address, band, time, center) {
    var place = t(location) + ', ' + t(address);

    var callback = function(point) {
        if (point) {
            if (center) { map.setCenter(point, 11); }

            var marker = new google.maps.Marker(point);
            var info = [
                '<strong>' + t(band) + '</strong>',
                t(time),
                place,
            ].join('<br>');

            map.addOverlay(marker);

            google.maps.Event.addListener(
                marker, 'click', function() {
                    marker.openInfoWindowHtml(info);
                }
            );
        }
    };

    geocoder.getLatLng(place, callback);
}
