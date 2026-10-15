// Purpose: Renders the Map Panel interface within apps\web\src\features\trips\jsx\map.
import { validCoordinates } from '../../../../utils/coordinates';
import React, { useEffect, useRef, useState, useMemo } from 'react';
import { Moon, Sun, MessageCircle, Ticket, MapPin } from 'lucide-react';
import useLeaflet from '../../hooks/useMapRenderer';
import {
  cartoTileUrl,
  DEFAULT_CENTER,
  DEFAULT_ZOOM,
  DAY_COLORS,
  MARKER_COLORS,
  MARKER_ICONS,
} from '../../constants/mapConfig';
import { getMarkerCategory, sanitizePopup, tripDayNumber } from '../../utils/groupPlannerUtils';
import { formatDate } from '../../utils/formatters';

/**
 * Leaflet map panel for the Group Planner right pane.
 *
 * Props:
 *   group           - group detail object (destination_lat, destination_lng)
 *   places          - all group places (itinerary + unscheduled)
 *   filteredLibrary - destination discovery items (for library tab)
 *   activeTab       - current tab key
 *   mapDay          - 'all' | day number string
 *   uniqueDates     - sorted array of visit_date strings
 *   dayNumbers      - array of day numbers [1,2,3...]
 *   onMapDayChange  - callback(dayStr)
 */
export default function MapPanel({
  group,
  places,
  filteredLibrary,
  activeTab,
  mapDay,
  uniqueDates,
  dayNumbers,
  onMapDayChange,
  selectedPlaceId,
  onSelectPlace,
  onAskPlace,
  onOpenBookings,
  mapApiKey = '',
}) {
  const leafletReady = useLeaflet();
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markersLayerRef = useRef(null);
  const markerRefs = useRef(new Map());
  const [nightMap, setNightMap] = useState(false);

  const itineraryPlaces = useMemo(
    () => places.filter((p) => p.visit_date && !p.is_deleted),
    [places],
  );
  const unscheduledPlaces = useMemo(
    () => places.filter((p) => !p.visit_date && !p.is_deleted),
    [places],
  );
  const visibleStops = itineraryPlaces.filter(
    (p) =>
      mapDay === 'all' ||
      String(tripDayNumber(p.visit_date, group?.start_date, uniqueDates)) === mapDay,
  );
  const selected =
    visibleStops.find((p) => p.id === selectedPlaceId) ||
    visibleStops[0] ||
    unscheduledPlaces.find((p) => p.id === selectedPlaceId);

  function getDayNumber(dateStr) {
    return tripDayNumber(dateStr, group?.start_date, uniqueDates);
  }

  // Initialize map
  useEffect(() => {
    if (!leafletReady || !mapRef.current) return;

    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
      mapInstanceRef.current = null;
      markersLayerRef.current = null;
    }

    if (!group) return;

    const L = window.L;
    const center = validCoordinates(group.destination_lat, group.destination_lng)
      ? [group.destination_lat, group.destination_lng]
      : DEFAULT_CENTER;

    const map = L.map(mapRef.current, {
      center,
      zoom: DEFAULT_ZOOM,
      zoomControl: true,
      attributionControl: true,
      zoomAnimation: false,
      markerZoomAnimation: false,
    });
    const tileUrl = cartoTileUrl(mapApiKey, nightMap);
    if (tileUrl)
      L.tileLayer(tileUrl, {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attribution/">CARTO</a>',
        maxZoom: 20,
      }).addTo(map);
    const markersLayer = L.layerGroup().addTo(map);

    mapInstanceRef.current = map;
    markersLayerRef.current = markersLayer;

    return () => {
      if (mapInstanceRef.current === map) {
        map.stop?.();
        map.closePopup?.();
        map.remove();
        mapInstanceRef.current = null;
        markersLayerRef.current = null;
      }
    };
  }, [leafletReady, group?.id, nightMap, mapApiKey]);

  // Re-center on destination change
  useEffect(() => {
    if (!mapInstanceRef.current || !group) return;
    if (validCoordinates(group.destination_lat, group.destination_lng)) {
      mapInstanceRef.current.setView([group.destination_lat, group.destination_lng], DEFAULT_ZOOM);
    }
  }, [group?.destination_lat, group?.destination_lng]);

  // Render markers
  useEffect(() => {
    if (!mapInstanceRef.current || !markersLayerRef.current || !window.L) return;
    if (activeTab !== 'itinerary') return;
    const L = window.L;
    mapInstanceRef.current.stop?.();
    mapInstanceRef.current.closePopup?.();
    markersLayerRef.current.clearLayers();
    markerRefs.current.clear();
    const bounds = [];

    if (activeTab === 'library') {
      filteredLibrary.forEach((item) => {
        if (!validCoordinates(item.latitude, item.longitude)) return;
        const cat = item.category || 'PLACE';
        const color = MARKER_COLORS[cat] || MARKER_COLORS.PLACE;
        const iconHtml = MARKER_ICONS[cat] || MARKER_ICONS.PLACE;

        const icon = L.divIcon({
          className: 'custom-marker',
          html:
            '<div class="marker-pin-wrapper" style="background: ' +
            color +
            ';">' +
            iconHtml +
            '</div>',
          iconSize: [40, 40],
          iconAnchor: [20, 20],
        });

        const lat = parseFloat(item.latitude);
        const lng = parseFloat(item.longitude);
        L.marker([lat, lng], { icon })
          .addTo(markersLayerRef.current)
          .bindPopup(
            '<div style="padding:4px;font-weight:600;">' +
              sanitizePopup(item.name) +
              '</div>' +
              '<div style="font-size:11px;color:#71717a;">' +
              sanitizePopup(item.address) +
              '</div>',
          );
        bounds.push([lat, lng]);
      });

      if (bounds.length > 0) {
        mapInstanceRef.current.fitBounds(bounds, { padding: [80, 80], maxZoom: 14 });
      }
      return;
    }

    // Itinerary / other tabs
    let scheduledItems = itineraryPlaces.filter((p) => validCoordinates(p.latitude, p.longitude));
    if (mapDay !== 'all') {
      scheduledItems = scheduledItems.filter(
        (p) => getDayNumber(p.visit_date) === parseInt(mapDay),
      );
    }

    const byDay = {};

    scheduledItems.forEach((p) => {
      const cat = getMarkerCategory(p.category);
      const color = MARKER_COLORS[cat] || MARKER_COLORS.PLACE;
      const iconHtml = MARKER_ICONS[cat] || MARKER_ICONS.PLACE;
      const day = getDayNumber(p.visit_date);

      const icon = L.divIcon({
        className: 'custom-marker',
        html:
          '<div class="marker-pin-wrapper" style="background: ' +
          color +
          ';">' +
          iconHtml +
          '<div class="marker-day-badge">D' +
          day +
          '</div></div>',
        iconSize: [40, 40],
        iconAnchor: [20, 20],
      });

      const lat = parseFloat(p.latitude);
      const lng = parseFloat(p.longitude);

      let popupHtml =
        '<div style="padding:4px;"><div style="font-weight:600;margin-bottom:4px;">' +
        sanitizePopup(p.name) +
        '</div>';
      popupHtml += '<div style="font-size:11px;color:#52525b;">Day ' + day;
      if (p.visit_date) popupHtml += ' &middot; ' + sanitizePopup(formatDate(p.visit_date));
      if (p.suggested_time) popupHtml += ' &middot; ' + sanitizePopup(p.suggested_time.slice(0, 5));
      popupHtml += '</div>';
      if (p.remarks)
        popupHtml +=
          '<div style="font-size:11px;color:#71717a;margin-top:4px;font-style:italic;">' +
          sanitizePopup(p.remarks) +
          '</div>';
      popupHtml += '</div>';

      const marker = L.marker([lat, lng], { icon });
      marker.addTo(markersLayerRef.current).bindPopup(popupHtml);
      const popup = marker.getPopup?.();
      if (popup) popup.options.autoPan = false;
      marker.on?.('click', () => onSelectPlace?.(p.id));
      markerRefs.current.set(p.id, marker);
      bounds.push([lat, lng]);

      if (!byDay[day]) byDay[day] = [];
      byDay[day].push({ lat, lng, time: p.suggested_time || p.visit_date || '' });
    });

    // Always show unassigned places with icon-only markers (no day badge)
    unscheduledPlaces.forEach((p) => {
      if (!validCoordinates(p.latitude, p.longitude)) return;
      const cat = getMarkerCategory(p.category);
      const iconHtml = MARKER_ICONS[cat] || MARKER_ICONS.PLACE;

      const icon = L.divIcon({
        className: 'custom-marker',
        html:
          '<div class="marker-pin-wrapper" style="background: #a1a1aa; opacity: 0.75;">' +
          iconHtml +
          '</div>',
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      });

      const lat = parseFloat(p.latitude);
      const lng = parseFloat(p.longitude);

      let popupHtml =
        '<div style="padding:4px;"><div style="font-weight:600;margin-bottom:2px;">' +
        sanitizePopup(p.name) +
        '</div>';
      popupHtml += '<div style="font-size:11px;color:#a1a1aa;">Unassigned</div>';
      if (p.remarks)
        popupHtml +=
          '<div style="font-size:11px;color:#71717a;margin-top:4px;font-style:italic;">' +
          sanitizePopup(p.remarks) +
          '</div>';
      popupHtml += '</div>';

      const marker = L.marker([lat, lng], { icon });
      marker.addTo(markersLayerRef.current).bindPopup(popupHtml);
      const popup = marker.getPopup?.();
      if (popup) popup.options.autoPan = false;
      marker.on?.('click', () => onSelectPlace?.(p.id));
      markerRefs.current.set(p.id, marker);
      bounds.push([lat, lng]);
    });

    Object.keys(byDay).forEach((day) => {
      const stops = byDay[day].sort((a, b) => a.time.localeCompare(b.time));
      if (stops.length < 2) return;
      const latlngs = stops.map((s) => [s.lat, s.lng]);
      const lineColor = DAY_COLORS[(parseInt(day) - 1) % DAY_COLORS.length];
      L.polyline(latlngs, {
        color: lineColor,
        weight: 3,
        opacity: 0.7,
        dashArray: '8 6',
      }).addTo(markersLayerRef.current);
    });

    if (bounds.length > 0) {
      mapInstanceRef.current.fitBounds(bounds, { padding: [80, 80], maxZoom: 15 });
    }
  }, [itineraryPlaces, unscheduledPlaces, mapDay, group, activeTab, filteredLibrary, nightMap, mapApiKey]);

  useEffect(() => {
    if (!selectedPlaceId) return;
    const marker = markerRefs.current.get(selectedPlaceId);
    marker?.openPopup?.();
    if (marker?.getLatLng) mapInstanceRef.current?.panTo?.(marker.getLatLng(), { animate: false });
  }, [selectedPlaceId, mapDay]);
  useEffect(() => {
    mapInstanceRef.current?.invalidateSize?.();
  }, [activeTab]);

  return (
    <div className={'gp-map-container' + (nightMap ? ' gp-map-night' : '')}>
      <button
        className="gp-map-theme gp-icon-button"
        aria-label={nightMap ? 'Switch to day map' : 'Switch to night map'}
        aria-pressed={nightMap}
        onClick={() => setNightMap((value) => !value)}
      >
        {nightMap ? <Sun size={16} /> : <Moon size={16} />}
        {nightMap ? 'Day Map' : 'Night Radar'}
      </button>
      <div className="gp-map-day-selector">
        <button
          className={'gp-map-day-btn' + (mapDay === 'all' ? ' active' : '')}
          onClick={() => onMapDayChange('all')}
        >
          All
        </button>
        {dayNumbers.map((d) => (
          <button
            key={d}
            className={'gp-map-day-btn' + (mapDay === String(d) ? ' active' : '')}
            onClick={() => onMapDayChange(String(d))}
          >
            Day {d}
          </button>
        ))}
      </div>
      <div ref={mapRef} className="gp-leaflet-map" />
      {selected && (
        <div className="gp-map-spot">
          <div className="gp-map-spot-top">
            <span>
              <MapPin size={12} />
              Selected Stop
            </span>
            <span>{selected.suggested_time?.slice(0, 5) || 'Any time'}</span>
          </div>
          <div className="gp-map-spot-body">
            {selected.photo_url && <img src={selected.photo_url} alt="" />}
            <div>
              <h3>{selected.name}</h3>
              <p>{selected.remarks || selected.description || selected.address}</p>
            </div>
          </div>
          <div className="gp-map-spot-actions">
            <button onClick={() => onOpenBookings?.()}>
              <Ticket size={13} />
              View bookings
            </button>
            <button onClick={() => onAskPlace?.(selected)}>
              <MessageCircle size={13} />
              Ask group
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
