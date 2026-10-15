import React, { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { MapPin, Star, Search, Compass, ChevronLeft, ChevronRight } from 'lucide-react';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { unwrap } from '../../utils/groupPlannerUtils';

export default function LibraryTab({ destination, group }) {
  const [filters, setFilters] = useState({ state_id: '', city_id: '', page: 1 });
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setFilters((old) => ({ ...old, page: 1 }));
    }, 300);
    return () => clearTimeout(timer);
  }, [search]);
  const scope = {
    destination_type: group?.destination_type || '',
    destination_id: group?.destination_id || '',
    destination: destination || group?.destination || '',
  };
  const options = { ...scope, ...filters, search: debouncedSearch, per_page: 24 };
  const {
    data: raw,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ['group-planner', 'catalog-cards', options],
    queryFn: () => groupPlannerApi.getCatalogPlaces(options),
    enabled: !!(scope.destination_id || scope.destination),
    staleTime: 60000,
  });
  const data = unwrap(raw) || {};
  const places = data.places || [];
  const regions = useMemo(() => {
    const grouped = new Map();
    for (const place of places) {
      const key = `${place.state_id}-${place.city_id}`;
      if (!grouped.has(key))
        grouped.set(key, { key, state: place.state_name, city: place.city_name, places: [] });
      grouped.get(key).places.push(place);
    }
    return [...grouped.values()];
  }, [places]);
  const kind = data.destination?.type || scope.destination_type;
  return (
    <div className="gp-view gp-library-view">
      <div className="gp-tab-heading">
        <div>
          <span className="gp-eyebrow">EXPLORE YOUR DESTINATION</span>
          <h1>{data.destination?.name || destination?.split(',')[0] || 'Travel'} Library</h1>
          <p>
            {kind === 'country'
              ? 'Browse states, then cities, and discover their places.'
              : kind === 'state'
                ? 'Browse cities and discover every place in this region.'
                : 'Discover all the places in your selected city.'}
          </p>
        </div>
        <span className="gp-tab-count">
          <Compass size={15} />
          {(data.total || 0).toLocaleString()} places
        </span>
      </div>
      <div className="gp-catalog-toolbar">
        {kind === 'country' && (
          <label className="gp-field">
            <span>State / region</span>
            <select
              aria-label="Library state"
              value={filters.state_id}
              onChange={(e) => setFilters({ state_id: e.target.value, city_id: '', page: 1 })}
            >
              <option value="">All states / regions</option>
              {(data.states || []).map((state) => (
                <option key={state.id} value={state.id}>
                  {state.name} ({state.place_count})
                </option>
              ))}
            </select>
          </label>
        )}
        {kind !== 'city' && (
          <label className="gp-field">
            <span>City</span>
            <select
              aria-label="Library city"
              value={filters.city_id}
              onChange={(e) => setFilters({ ...filters, city_id: e.target.value, page: 1 })}
            >
              <option value="">All cities</option>
              {(data.cities || []).map((city) => (
                <option key={city.id} value={city.id}>
                  {city.name}
                  {kind === 'country' && !filters.state_id ? `, ${city.state_name}` : ''} (
                  {city.place_count})
                </option>
              ))}
            </select>
          </label>
        )}
        <label className="gp-search-field">
          <Search size={15} />
          <input
            aria-label="Search destination library"
            placeholder="Search places in this destination..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </label>
      </div>
      {isLoading ? (
        <p role="status">Loading places...</p>
      ) : error ? (
        <div className="gp-empty-agenda" role="alert">
          <p>{error.message}</p>
          <button className="gp-btn-create" onClick={() => refetch()}>
            Try again
          </button>
        </div>
      ) : places.length === 0 ? (
        <div className="gp-empty-agenda">
          <Compass size={30} />
          <h3>No places found</h3>
          <p>
            {data.destination
              ? 'Try another city, state, or search.'
              : 'This destination is not in the catalog yet. Choose a catalog destination when creating a group.'}
          </p>
        </div>
      ) : (
        <>
          <p className="gp-catalog-results-note">
            Showing {((data.page || 1) - 1) * (data.per_page || 24) + 1}-
            {Math.min((data.page || 1) * (data.per_page || 24), data.total)} of{' '}
            {data.total.toLocaleString()} places
          </p>
          {regions.map((region) => (
            <section
              className="gp-catalog-region"
              key={region.key}
              aria-label={`${region.city}, ${region.state}`}
            >
              <div className="gp-catalog-region-heading">
                <span>{region.state}</span>
                <h2>
                  <MapPin size={18} />
                  {region.city}
                </h2>
              </div>
              <div className="gp-discovery-grid">
                {region.places.map((item) => {
                  const rating = Number.parseFloat(item.rating);
                  return (
                    <article className="gp-discovery-card gp-catalog-card" key={item.id}>
                      <div className="gp-discovery-image">
                        <span className="gp-discovery-placeholder">
                          <Compass size={40} />
                        </span>
                        {/^https?:\/\//i.test(item.photo_url || '') && (
                          <img
                            src={item.photo_url}
                            alt=""
                            loading="lazy"
                            onError={(e) => {
                              e.currentTarget.style.display = 'none';
                            }}
                          />
                        )}
                        <span className="gp-discovery-theme">
                          {(item.category || 'Place').replace(/_/g, ' ')}
                        </span>
                      </div>
                      <div className="gp-discovery-body">
                        <div className="gp-discovery-title">
                          <h3>{item.name}</h3>
                          {Number.isFinite(rating) && rating > 0 && (
                            <span>
                              <Star size={11} fill="currentColor" />
                              {rating.toFixed(1)}
                            </span>
                          )}
                        </div>
                        <p className="gp-discovery-address">
                          <MapPin size={12} />
                          {[item.city_name, item.state_name].filter(Boolean).join(', ')}
                        </p>
                        <p className="gp-discovery-description">
                          {item.description || item.address || 'Explore this place on your trip.'}
                        </p>
                      </div>
                    </article>
                  );
                })}
              </div>
            </section>
          ))}
          {data.total_pages > 1 && (
            <nav className="gp-catalog-pagination" aria-label="Library pages">
              <button
                className="gp-modal-btn-secondary"
                disabled={filters.page === 1}
                onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
              >
                <ChevronLeft size={16} />
                Previous
              </button>
              <span>
                Page {data.page} of {data.total_pages}
              </span>
              <button
                className="gp-modal-btn-secondary"
                disabled={filters.page >= data.total_pages}
                onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
              >
                Next
                <ChevronRight size={16} />
              </button>
            </nav>
          )}
        </>
      )}
    </div>
  );
}
