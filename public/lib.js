export function classifyGI(gi) {
  if (gi == null) return null;
  if (gi <= 55) return 'low';
  if (gi <= 69) return 'medium';
  return 'high';
}

export function classifyGL(gl) {
  if (gl == null) return null;
  if (gl <= 10) return 'low';
  if (gl <= 19) return 'medium';
  return 'high';
}

const GI_COLORS = {
  low: '#7a9a5a',
  medium: '#c4a23a',
  high: '#c26a4a',
};

export function getGIColor(classification) {
  return GI_COLORS[classification] ?? '#5c4a3a';
}
