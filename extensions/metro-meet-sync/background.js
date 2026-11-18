/**
 * Metro Institute Meet Sync - Background Service Worker
 * Berjalan di background extension untuk menjamin pengiriman webhook bebas CORS.
 */

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'SEND_MEET_WEBHOOK') {
    const { targetUrl, authHeader, payload } = request;

    fetch(targetUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: JSON.stringify(payload),
    })
      .then(async (response) => {
        const data = await response.json().catch(() => ({}));
        console.log('Background webhook response:', response.status, data);
        sendResponse({ success: response.ok, status: response.status, data });
      })
      .catch((err) => {
        console.error('Background webhook error:', err);
        sendResponse({ success: false, error: err.message });
      });

    return true; // Menandakan respon asynchronous
  }
});
