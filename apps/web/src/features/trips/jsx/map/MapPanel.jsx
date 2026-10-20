// Purpose: Renders planner stops and day routes on Leaflet/OpenFreeMap, focuses the destination viewport, filters days and handles theme/coordinate fallbacks.
import { validCoordinates } from '../../../../utils/coordinates';
import React, { useEffect, useRef, useState, useMemo } from 'react';
import { Moon, Sun } from 'lucide-react';
import useLeaflet from '../../hooks/useMapRenderer';
import {
  OPENFREEMAP_STYLES,
  MAP_ATTRIBUTION,
  DEFAULT_CENTER,
  DEFAULT_ZOOM,
  DAY_COLORS,
  MARKER_COLORS,
  MARKER_ICONS,
} from '../../constants/mapConfig';
import { getMarkerCategory, sanitizePopup, tripDayNumber } from '../../utils/groupPlannerUtils';
import { formatDate } from '../../utils/formatters';
import { focusDestination, longitudeNearViewport } from '../../utils/mapViewport';
import { openFreeMapStyle } from '../../utils/openFreeMapStyle';

/**
 * Leaflet map panel for the Group Planner right pane.
 *
 * Props:
 *   group           - group detail object (destination_lat, destination_lng)
 *   places          - all group places (itinerary + unscheduled)
 *   activeTab       - current tab key
 *   mapDay          - 'all' | day number string
 *   uniqueDates     - sorted array of visit_date strings
 *   dayNumbers      - array of day numbers [1,2,3...]
 *   onMapDayChange  - callback(dayStr)
 */
export default function MapPanel({
  group,
  places,
  activeTab,
  mapDay,
  uniqueDates,
  dayNumbers,
  onMapDayChange,
  selectedPlaceId,
  onSelectPlace,
  destinationViewport,
  viewportError,
}) {
  const leafletReady = useLeaflet();
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markersLayerRef = useRef(null);
  const markerRefs = useRef(new Map());
  const basemapRef = useRef(null);
  const styleUrlRef = useRef(null);
  const [nightMap, setNightMap] = useState(false);
  const [basemapError, setBasemapError] = useState(false);

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
    unscheduledPlaces.find((p) => p.id === selectedPlaceId) ||
    visibleStops[0];

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
    setBasemapError(false);
    if (L.maplibreGL && (!L.supportsVectorMap || L.supportsVectorMap())) {
      let layer;
      try {
        layer = L.maplibreGL({
          style: null,
          interactive: false,
          attributionControl: { customAttribution: MAP_ATTRIBUTION },
        });
        layer.addTo(map);
        basemapRef.current = layer;
        const style = nightMap ? OPENFREEMAP_STYLES.night : OPENFREEMAP_STYLES.day;
        layer.getMaplibreMap?.()?.setStyle(style, {transformStyle: openFreeMapStyle});
        styleUrlRef.current = style;
        layer.getMaplibreMap?.()?.on('error', () => setBasemapError(true));
        layer.getMaplibreMap?.()?.on('style.load', () => setBasemapError(false));
      } catch {
        setBasemapError(true);
        if (layer) {
          if (!layer.getMaplibreMap?.()) layer.onRemove = () => layer.getContainer?.()?.remove();
          try {
            map.removeLayer?.(layer);
          } catch {
            /* Local overlays still work. */
          }
        }
      }
    } else setBasemapError(true);
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
        basemapRef.current = null;
        styleUrlRef.current = null;
      }
    };
  }, [leafletReady, group?.id]);

  useEffect(() => {
    const style = nightMap ? OPENFREEMAP_STYLES.night : OPENFREEMAP_STYLES.day;
    if (styleUrlRef.current === style) return;
    basemapRef.current
      ?.getMaplibreMap?.()
      ?.setStyle(style, {transformStyle: openFreeMapStyle});
    styleUrlRef.current = style;
  }, [nightMap]);

  // Re-center on destination change
  useEffect(() => {
    if (!selectedPlaceId && mapDay === 'all')
      focusDestination(mapInstanceRef.current, destinationViewport, group);
  }, [
    leafletReady,
    destinationViewport,
    group?.id,
    group?.destination_lat,
    group?.destination_lng,
    mapDay,
    selectedPlaceId,
  ]);

  // Render markers
  useEffect(() => {
    if (!mapInstanceRef.current || !markersLayerRef.current || !window.L) return;
    const L = window.L;
    mapInstanceRef.current.stop?.();
    mapInstanceRef.current.closePopup?.();
    markersLayerRef.current.clearLayers();
    markerRefs.current.clear();
    const bounds = [];

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
      const lng = longitudeNearViewport(parseFloat(p.longitude), destinationViewport);

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
      const lng = longitudeNearViewport(parseFloat(p.longitude), destinationViewport);

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

    const hasDestinationLocation =
      destinationViewport?.center ||
      validCoordinates(group?.destination_lat, group?.destination_lng);
    if (bounds.length > 0 && (mapDay !== 'all' || !hasDestinationLocation)) {
      mapInstanceRef.current.fitBounds(bounds, { padding: [80, 80], maxZoom: 15 });
    }
  }, [
    itineraryPlaces,
    unscheduledPlaces,
    mapDay,
    group,
    activeTab,
      destinationViewport,
    leafletReady,
  ]);

  useEffect(() => {
    if (!selectedPlaceId) return;
    const marker = markerRefs.current.get(selectedPlaceId);
    mapInstanceRef.current?.closePopup?.();
    marker?.openPopup?.();
    if (marker?.getLatLng)
      mapInstanceRef.current?.setView?.(
        marker.getLatLng(),
        Math.max(mapInstanceRef.current.getZoom?.() || 0, 13),
        { animate: false },
      );
  }, [selectedPlaceId, mapDay, leafletReady, places, destinationViewport]);
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
      {(viewportError || destinationViewport?.status === 'location_unavailable' || destinationViewport?.status === 'unresolved') && (
        <p className="gp-map-location-status" role="status">Destination coordinates are unavailable in the catalog.</p>
      )}
      {basemapError && (
        <p className="gp-map-background-status" role="status">
          Map background unavailable. Saved place markers remain visible.
        </p>
      )}
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
              {selected.visit_date ? `Day ${getDayNumber(selected.visit_date)} - ${formatDate(selected.visit_date)}` : 'Unscheduled'}
            </span>
            <span>{selected.suggested_time?.slice(0, 5) || 'Any time'}</span>
          </div>
          <div className="gp-map-spot-body">
            <div>
              <h3>{selected.name}</h3>
              <p>{selected.remarks || selected.description}</p>
            </div>
          </div>
          {!validCoordinates(selected.latitude, selected.longitude) && (
            <p className="gp-map-coordinate-note" role="status">Map coordinates are not available for this stop yet.</p>
          )}

        </div>
      )}
    </div>
  );
}
