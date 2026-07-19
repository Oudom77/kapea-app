export async function mockScan(url) {
  const normalized = url.toLowerCase();

  if (
    normalized.includes('malicious') ||
    normalized.includes('phishing') ||
    normalized.includes('malware')
  ) {
    return {
      stats: {
        harmless: 4,
        malicious: 67,
        suspicious: 1,
        undetected: 0,
      },
      redirectChain: [
        'https://redirect-check.example/',
        'https://credential-check.example/',
      ],
      screenshotUrl: null,
    };
  }

  if (
    normalized.includes('suspicious') ||
    normalized.includes('login') ||
    normalized.includes('bit.ly')
  ) {
    return {
      stats: {
        harmless: 60,
        malicious: 1,
        suspicious: 5,
        undetected: 6,
      },
      redirectChain: ['https://destination-check.example/'],
      screenshotUrl: null,
    };
  }

  return {
    stats: {
      harmless: 64,
      malicious: 0,
      suspicious: 0,
      undetected: 8,
    },
    redirectChain: [],
    screenshotUrl: null,
  };
}
