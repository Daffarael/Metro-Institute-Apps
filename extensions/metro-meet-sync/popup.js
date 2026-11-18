/**
 * Metro Institute Meet Sync - Popup Script
 */

document.addEventListener('DOMContentLoaded', () => {
  const DEFAULT_PROD_URL = 'https://api.metroinstitute.site/api/v1/webhook/google-meet';
  const DEFAULT_LOCAL_URL = 'http://localhost:5000/api/v1/webhook/google-meet';
  const DEFAULT_SECRET = 'metro-meet-secret-2026';

  const apiUrlInput = document.getElementById('apiUrl');
  const secretInput = document.getElementById('secret');
  const autoPostInput = document.getElementById('autoPost');
  const saveBtn = document.getElementById('saveBtn');
  const testBtn = document.getElementById('testBtn');
  const presetProd = document.getElementById('preset-prod');
  const presetLocal = document.getElementById('preset-local');
  const statusMsg = document.getElementById('statusMsg');

  function showMessage(text, isSuccess = true) {
    statusMsg.textContent = text;
    statusMsg.style.color = isSuccess ? '#0df293' : '#ef4444';
  }

  // Muat setting tersimpan
  if (typeof chrome !== 'undefined' && chrome.storage && chrome.storage.sync) {
    chrome.storage.sync.get(['apiUrl', 'secret', 'autoPost'], (res) => {
      apiUrlInput.value = res.apiUrl || DEFAULT_PROD_URL;
      secretInput.value = res.secret || DEFAULT_SECRET;
      autoPostInput.checked = typeof res.autoPost === 'boolean' ? res.autoPost : true;
    });
  } else {
    apiUrlInput.value = DEFAULT_PROD_URL;
    secretInput.value = DEFAULT_SECRET;
  }

  // Presets
  presetProd.addEventListener('click', () => {
    apiUrlInput.value = DEFAULT_PROD_URL;
  });

  presetLocal.addEventListener('click', () => {
    apiUrlInput.value = DEFAULT_LOCAL_URL;
  });

  // Simpan
  saveBtn.addEventListener('click', () => {
    const apiUrl = apiUrlInput.value.trim() || DEFAULT_PROD_URL;
    const secret = secretInput.value.trim() || DEFAULT_SECRET;
    const autoPost = autoPostInput.checked;

    if (typeof chrome !== 'undefined' && chrome.storage && chrome.storage.sync) {
      chrome.storage.sync.set({ apiUrl, secret, autoPost }, () => {
        showMessage('✅ Pengaturan berhasil disimpan!');
      });
    } else {
      showMessage('✅ Pengaturan tersimpan di sesi ini.');
    }
  });

  // Uji koneksi ke endpoint webhook backend
  testBtn.addEventListener('click', async () => {
    const apiUrl = apiUrlInput.value.trim() || DEFAULT_PROD_URL;
    const secret = secretInput.value.trim() || DEFAULT_SECRET;

    showMessage('⏳ Menguji koneksi ke server...', true);

    try {
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${secret}`,
        },
        body: JSON.stringify({
          eventType: 'ping',
        }),
      });

      if (response.ok) {
        showMessage('✅ Server terhubung & Secret Key Valid!');
      } else if (response.status === 401) {
        showMessage('❌ 401: Secret key tidak cocok dengan backend.', false);
      } else {
        const data = await response.json().catch(() => ({}));
        showMessage(`⚠️ Respon server: ${data.message || response.statusText}`, false);
      }
    } catch (err) {
      console.error(err);
      showMessage(`❌ Gagal terhubung ke URL: ${err.message}`, false);
    }
  });
});
