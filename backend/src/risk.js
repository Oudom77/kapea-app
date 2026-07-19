function count(stats, key) {
  const value = stats?.[key];
  return Number.isSafeInteger(value) && value >= 0 ? value : 0;
}

export function classifyRisk(stats, maliciousThreshold = 3) {
  const malicious = count(stats, 'malicious');
  const suspicious = count(stats, 'suspicious');
  const enginesFlagged = malicious + suspicious;
  const totalEngines = Object.values(stats || {}).reduce(
    (total, value) =>
      total + (Number.isSafeInteger(value) && value >= 0 ? value : 0),
    0,
  );

  let tier = 'safe';
  if (malicious >= maliciousThreshold) {
    tier = 'malicious';
  } else if (enginesFlagged > 0) {
    tier = 'suspicious';
  }

  const reasons = [];
  if (malicious > 0) {
    reasons.push(
      `${malicious} security engine${malicious === 1 ? '' : 's'} classified this URL as malicious`,
    );
  }
  if (suspicious > 0) {
    reasons.push(
      `${suspicious} security engine${suspicious === 1 ? '' : 's'} classified this URL as suspicious`,
    );
  }
  if (enginesFlagged === 0) {
    reasons.push('No security engines flagged this URL');
  }

  return {
    tier,
    enginesFlagged,
    totalEngines,
    reasons,
  };
}
