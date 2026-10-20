// Purpose: Adjusts selected provider shield-label expressions to tolerate missing ref_length values while preserving the rest of the map style.
const shields = new Set(['highway-shield-non-us', 'highway-shield-us-interstate', 'road_shield_us']);

function safeReferenceLength(expression) {
  if (!Array.isArray(expression)) return expression;
  if (expression.length === 2 && expression[0] === 'get' && expression[1] === 'ref_length')
    return ['number', ['get', 'ref_length'], 99];
  return expression.map(safeReferenceLength);
}

// Missing ref_length means no usable shield label; exclude it without a
// numeric-expression warning from the provider's optional tile property.
export function openFreeMapStyle(_previous, next) {
  return {...next, layers: next.layers.map(layer => shields.has(layer.id) && layer.filter
    ? {...layer, filter: safeReferenceLength(layer.filter)} : layer)};
}
