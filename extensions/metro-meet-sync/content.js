/**
 * Metro Institute - Google Meet Auto Attendance Content Script
 * Otomatis mendeteksi peserta, menghitung durasi aktif, dan melakukan
 * AUTO-POST ke Webhook API Metro Institute saat meeting berakhir.
 */

(function () {
  'use strict';

  // Cegah inisialisasi ganda
  if (window.__METRO_MEET_SYNC_LOADED__) return;
  window.__METRO_MEET_SYNC_LOADED__ = true;

  const DEFAULT_API_URL = 'https://api.metroinstitute.site/api/v1/webhook/google-meet';
  const DEFAULT_SECRET = 'metro-meet-secret-2026';
  const SCAN_INTERVAL_MS = 4000; // Pindai setiap 4 detik

  let config = {
    apiUrl: DEFAULT_API_URL,
    secret: DEFAULT_SECRET,
    autoPost: true,
  };

  // Muat konfigurasi dari storage
  if (typeof chrome !== 'undefined' && chrome.storage && chrome.storage.sync) {
    chrome.storage.sync.get(['apiUrl', 'secret', 'autoPost'], (res) => {
      if (res.apiUrl) config.apiUrl = res.apiUrl;
      if (res.secret) config.secret = res.secret;
      if (typeof res.autoPost === 'boolean') config.autoPost = res.autoPost;
    });
  }

  // State Pelacakan
  let meetCode = null;
  let meetingStartTime = null;
  const participantsMap = new Map(); // key: cleanName -> participant object
  let isExpanded = false;
  let hasSentFinal = false;

  // Ekstrak kode Google Meet dari URL
  function extractMeetCode() {
    const path = window.location.pathname.replace(/^\//, '').split('?')[0];
    const match = path.match(/[a-z]{3}-[a-z]{4}-[a-z]{3}/i);
    if (match) return match[0].toLowerCase();
    if (path.length >= 9 && !path.includes('/') && path !== 'landing') {
      return path.toLowerCase();
    }
    return null;
  }

  // Format detik ke HH:MM:SS atau MM:SS
  function formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) {
      return `${h}:${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
    }
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  }

  // Bersihkan nama dari tag bawaan Meet ("Anda", "(You)", dll)
  function cleanParticipantName(rawName) {
    if (!rawName) return '';
    return rawName
      .replace(/\(Anda\)/gi, '')
      .replace(/\(You\)/gi, '')
      .replace(/\(Tamu\)/gi, '')
      .replace(/\(Guest\)/gi, '')
      .replace(/\(Presentation\)/gi, '')
      .replace(/\(Presentasi\)/gi, '')
      .trim();
  }

  // Injeksi UI Dock dan Floating Drawer
  function injectMetroUI() {
    if (document.getElementById('metro-meet-container')) return;

    const container = document.createElement('div');
    container.id = 'metro-meet-container';

    const logoUrl = (typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.getURL)
      ? chrome.runtime.getURL('icons/icon-48.png')
      : '';

    container.innerHTML = `
      <div class="metro-pill-badge" id="metro-pill">
        <span class="metro-status-dot"></span>
        <img class="metro-brand-logo" src="${logoUrl}" alt="Metro" onerror="this.style.display='none'">
        <span class="metro-pill-title">Metro Sync</span>
        <span class="metro-pill-counter" id="metro-counter">0 Peserta</span>
      </div>

      <div class="metro-expanded-card hidden" id="metro-card">
        <div class="metro-card-header">
          <div class="metro-brand-group">
            <img class="metro-brand-logo" src="${logoUrl}" alt="Metro" onerror="this.style.display='none'">
            <div>
              <div class="metro-brand-title">
                Metro Institute
                <span class="metro-badge-auto">AUTO-SYNC</span>
              </div>
            </div>
          </div>
          <button class="metro-close-btn" id="metro-close-btn" title="Tutup">✕</button>
        </div>

        <div class="metro-info-bar">
          <div>Room: <span class="metro-code-tag" id="metro-room-code">${meetCode || '-'}</span></div>
          <div>Durasi: <span class="metro-timer-tag" id="metro-timer">00:00</span></div>
        </div>

        <div class="metro-attendee-list" id="metro-attendee-list">
          <div class="metro-empty-state">Mendeteksi peserta Google Meet...</div>
        </div>

        <div class="metro-card-footer">
          <div class="metro-sync-status-text" id="metro-status-text">
            🟢 Auto-Sync Aktif (Kirim otomatis saat call ditutup)
          </div>
          <button class="metro-btn-primary" id="metro-sync-now-btn">
            🚀 Kirim Presensi Sekarang
          </button>
          <button class="metro-btn-secondary" id="metro-export-csv-btn">
            📥 Download Backup CSV
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(container);

    // Event listeners UI
    const pill = document.getElementById('metro-pill');
    const card = document.getElementById('metro-card');
    const closeBtn = document.getElementById('metro-close-btn');
    const syncNowBtn = document.getElementById('metro-sync-now-btn');
    const exportCsvBtn = document.getElementById('metro-export-csv-btn');

    pill.addEventListener('click', () => {
      isExpanded = !isExpanded;
      if (isExpanded) {
        card.classList.remove('hidden');
        renderAttendees();
      } else {
        card.classList.add('hidden');
      }
    });

    closeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      isExpanded = false;
      card.classList.add('hidden');
    });

    syncNowBtn.addEventListener('click', () => {
      sendAttendanceWebhook({ isFinal: false, isManual: true });
    });

    exportCsvBtn.addEventListener('click', () => {
      exportCSV();
    });
  }

  // Notifikasi Toast Mengambang
  function showToast(message, isSuccess = true) {
    const existing = document.querySelector('.metro-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.className = 'metro-toast';
    toast.style.borderColor = isSuccess ? '#0df293' : '#ef4444';
    toast.innerHTML = `
      <span>${isSuccess ? '✅' : '⚠️'}</span>
      <div>${message}</div>
    `;
    document.body.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(-20px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 4500);
  }

  // Pindai DOM Google Meet untuk mendeteksi peserta
  function scanParticipants() {
    const now = Date.now();
    const currentlySeen = new Set();

    // 1. Ambil dari panel daftar orang (People panel)
    // Berbagai selector Google Meet terbaru
    const peopleListItems = document.querySelectorAll(
      'div[role="listitem"], div[data-participant-id], div[aria-label*="daftar peserta"], div[aria-label*="Participants"]'
    );

    peopleListItems.forEach((item) => {
      // Cari nama dalam elemen
      const nameElem = item.querySelector(
        'span[title], .zWGUib, .jZwTjd, [dir="auto"]'
      );
      if (nameElem && nameElem.textContent) {
        const clean = cleanParticipantName(nameElem.textContent);
        if (clean && clean.length > 1 && !clean.toLowerCase().includes('people') && !clean.toLowerCase().includes('orang')) {
          currentlySeen.add(clean);
        }
      }
    });

    // 2. Ambil dari video tiles di layar utama
    const videoTiles = document.querySelectorAll(
      'div[data-self-name], [data-requested-participant-id], div.poVWob'
    );

    videoTiles.forEach((tile) => {
      const selfName = tile.getAttribute('data-self-name');
      if (selfName) {
        const clean = cleanParticipantName(selfName);
        if (clean) currentlySeen.add(clean);
      }
      const label = tile.querySelector('.zWGUib, .jZwTjd, [dir="auto"]');
      if (label && label.textContent) {
        const clean = cleanParticipantName(label.textContent);
        if (clean && clean.length > 1) currentlySeen.add(clean);
      }
    });

    // 3. Fallback: Cari nama pengguna sendiri jika belum terdaftar
    const selfChip = document.querySelector('div[data-self-name]');
    if (selfChip) {
      const selfName = cleanParticipantName(selfChip.getAttribute('data-self-name'));
      if (selfName) currentlySeen.add(selfName);
    }

    // Perbarui participantsMap
    const intervalSec = Math.round(SCAN_INTERVAL_MS / 1000);
    currentlySeen.forEach((name) => {
      if (!participantsMap.has(name)) {
        participantsMap.set(name, {
          displayName: name,
          email: '', // Diisi jika mentor/mentee punya email di workspace
          firstSeen: now,
          lastSeen: now,
          totalSeconds: intervalSec,
          joinTime: new Date(now).toISOString(),
          leaveTime: new Date(now).toISOString(),
        });
      } else {
        const p = participantsMap.get(name);
        p.lastSeen = now;
        p.totalSeconds += intervalSec;
        p.leaveTime = new Date(now).toISOString();
      }
    });

    // Perbarui counter di badge UI
    const counterElem = document.getElementById('metro-counter');
    if (counterElem) {
      counterElem.textContent = `${participantsMap.size} Peserta`;
    }

    // Perbarui timer meeting
    if (meetingStartTime) {
      const elapsedSeconds = Math.floor((now - meetingStartTime) / 1000);
      const timerElem = document.getElementById('metro-timer');
      if (timerElem) {
        timerElem.textContent = formatDuration(elapsedSeconds);
      }
    }

    if (isExpanded) {
      renderAttendees();
    }
  }

  // Render daftar peserta di drawer
  function renderAttendees() {
    const listElem = document.getElementById('metro-attendee-list');
    if (!listElem) return;

    if (participantsMap.size === 0) {
      listElem.innerHTML = `<div class="metro-empty-state">Belum ada peserta terdeteksi.<br><small style="color: #64748b;">Tips: Buka panel "Orang" sekali di Meet untuk deteksi instan.</small></div>`;
      return;
    }

    const totalMeetSec = meetingStartTime ? Math.max(1, (Date.now() - meetingStartTime) / 1000) : 1;
    let html = '';

    const sorted = Array.from(participantsMap.values()).sort((a, b) => b.totalSeconds - a.totalSeconds);

    sorted.forEach((p) => {
      const minutes = Math.ceil(p.totalSeconds / 60);
      const pct = Math.round((p.totalSeconds / totalMeetSec) * 100);
      const isMet = pct >= 80;

      html += `
        <div class="metro-attendee-item">
          <div class="metro-attendee-name" title="${p.displayName}">${p.displayName}</div>
          <div class="metro-attendee-meta">
            <span class="metro-attendee-duration">${minutes} m (${formatDuration(p.totalSeconds)})</span>
            <span class="metro-attendee-status ${isMet ? 'hadir' : 'kurang'}">
              ${isMet ? 'Hadir 🟢' : 'Aktif 🟡'}
            </span>
          </div>
        </div>
      `;
    });

    listElem.innerHTML = html;
  }

  // Kirim data presensi ke Webhook API Metro Institute
  async function sendAttendanceWebhook(options = {}) {
    const { isFinal = false, isManual = false, useKeepalive = false } = options;

    if (participantsMap.size === 0) {
      if (isManual) showToast('Belum ada data peserta yang terdeteksi untuk dikirim.', false);
      return;
    }

    if (isFinal && hasSentFinal) {
      return; // Sudah dikirim
    }

    const statusText = document.getElementById('metro-status-text');
    if (statusText) statusText.textContent = '⏳ Mengirim presensi ke server Metro Institute...';

    const durationMinutes = meetingStartTime
      ? Math.max(1, Math.ceil((Date.now() - meetingStartTime) / 60000))
      : 60;

    const participantsArray = Array.from(participantsMap.values()).map((p) => ({
      displayName: p.displayName,
      email: p.email || '',
      durationMinutes: Math.max(1, Math.ceil(p.totalSeconds / 60)),
      joinTime: p.joinTime,
      leaveTime: p.leaveTime,
    }));

    const payload = {
      eventType: 'meeting.ended',
      conferenceId: meetCode,
      durationMinutes: durationMinutes,
      actualDurationMinutes: durationMinutes,
      participants: participantsArray,
    };

    const targetUrl = config.apiUrl || DEFAULT_API_URL;
    const authHeader = `Bearer ${config.secret || DEFAULT_SECRET}`;

    try {
      if (useKeepalive && typeof fetch !== 'undefined') {
        fetch(targetUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: JSON.stringify(payload),
          keepalive: true,
        }).catch((e) => console.warn('Keepalive POST sent with result:', e));
        hasSentFinal = true;
        return;
      }

      const response = await fetch(targetUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json().catch(() => ({}));

      if (response.ok && data.success) {
        if (isFinal) hasSentFinal = true;
        const msg = `Presensi berhasil dikirim! (${participantsArray.length} peserta tercatat di Metro Institute)`;
        if (statusText) statusText.textContent = `✅ ${msg}`;
        showToast(msg, true);
      } else {
        const errorMsg = data.message || `HTTP ${response.status}`;
        if (statusText) statusText.textContent = `⚠️ Gagal kirim: ${errorMsg}`;
        if (isManual) showToast(`Gagal kirim: ${errorMsg}`, false);
      }
    } catch (err) {
      console.error('Metro Meet Sync error:', err);
      const errStr = err.message || 'Koneksi gagal';
      if (statusText) statusText.textContent = `❌ Koneksi terputus: ${errStr}`;
      if (isManual) showToast(`Gagal menghubungi server: ${errStr}`, false);
    }
  }

  // Export CSV Cadangan
  function exportCSV() {
    if (participantsMap.size === 0) {
      showToast('Belum ada data peserta untuk diunduh.', false);
      return;
    }

    let csv = 'Nama Peserta,Email,Durasi (Menit),Detik Aktif,Waktu Masuk,Waktu Keluar\n';
    participantsMap.forEach((p) => {
      const minutes = Math.ceil(p.totalSeconds / 60);
      csv += `"${p.displayName}","${p.email || ''}",${minutes},${p.totalSeconds},"${p.joinTime}","${p.leaveTime}"\n`;
    });

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Presensi_Meet_${meetCode || 'metro'}_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('File CSV cadangan berhasil diunduh!', true);
  }

  // Deteksi aksi tutup meeting atau "Akhiri panggilan untuk semua orang" (Leave call for all)
  function isEndCallAction(element) {
    if (!element) return false;
    const btn = element.closest('button, div[role="button"], span[role="button"], a[role="button"]');
    if (!btn) return false;

    const text = (btn.innerText || btn.textContent || '').toLowerCase().trim();
    const aria = (btn.getAttribute('aria-label') || '').toLowerCase();
    const tooltip = (btn.getAttribute('data-tooltip') || '').toLowerCase();
    const callAction = (btn.getAttribute('data-call-action') || '').toLowerCase();
    const jsname = btn.getAttribute('jsname') || '';

    // Deteksi khusus opsi dialog "Akhiri panggilan untuk semua orang" / "End the call for everyone"
    if (
      text.includes('semua orang') ||
      text.includes('semua') ||
      text.includes('everyone') ||
      text.includes('for all') ||
      text.includes('akhiri panggilan') ||
      text.includes('end the call') ||
      text.includes('tinggalkan panggilan') ||
      text.includes('leave call') ||
      text.includes('keluar') ||
      aria.includes('akhiri') ||
      aria.includes('tinggalkan') ||
      aria.includes('leave') ||
      aria.includes('end the call') ||
      tooltip.includes('akhiri') ||
      tooltip.includes('tinggalkan') ||
      tooltip.includes('leave') ||
      callAction.includes('end_for_all') ||
      callAction.includes('leave') ||
      jsname === 'CQylAd'
    ) {
      return true;
    }
    return false;
  }

  // Deteksi layar "Rapat telah berakhir" / "Anda telah meninggalkan rapat"
  function checkMeetingEndedScreen() {
    if (hasSentFinal || participantsMap.size === 0) return;
    const bodyText = (document.body ? document.body.innerText || '' : '').toLowerCase();
    if (
      bodyText.includes('anda telah meninggalkan rapat') ||
      bodyText.includes("you've left the meeting") ||
      bodyText.includes('you left the meeting') ||
      bodyText.includes('rapat telah berakhir') ||
      bodyText.includes('the meeting has ended') ||
      bodyText.includes('panggilan telah berakhir') ||
      bodyText.includes('panggilan telah selesai')
    ) {
      console.log('Metro Meet: Layar rapat selesai terdeteksi -> Auto-POSTing presensi!');
      sendAttendanceWebhook({ isFinal: true, useKeepalive: true });
    }
  }

  // Intercept tombol "Tinggalkan Panggilan" dan "Akhiri Panggilan untuk Semua Orang" untuk AUTO-POST
  function setupAutoPostListeners() {
    // Tangkap klik pada tombol leave call atau dialog "Akhiri panggilan untuk semua"
    document.addEventListener(
      'click',
      (e) => {
        if (config.autoPost && !hasSentFinal && isEndCallAction(e.target)) {
          console.log('Metro Meet: Aksi Leave Call / Akhiri untuk semua terdeteksi -> Auto-POSTing presensi!');
          sendAttendanceWebhook({ isFinal: true, useKeepalive: true });
        }
      },
      true
    );

    // Tangkap penutupan tab / browser
    window.addEventListener('beforeunload', () => {
      if (config.autoPost && !hasSentFinal && participantsMap.size > 0) {
        sendAttendanceWebhook({ isFinal: true, useKeepalive: true });
      }
    });

    window.addEventListener('pagehide', () => {
      if (config.autoPost && !hasSentFinal && participantsMap.size > 0) {
        sendAttendanceWebhook({ isFinal: true, useKeepalive: true });
      }
    });
  }

  // Loop inisialisasi & pemantauan URL
  function init() {
    const currentCode = extractMeetCode();

    if (currentCode) {
      if (!meetCode) {
        meetCode = currentCode;
        meetingStartTime = Date.now();
        console.log(`Metro Institute Meet Sync diaktifkan untuk room: ${meetCode}`);
        injectMetroUI();
        setupAutoPostListeners();

        // Mulai scanning rutin
        setInterval(() => {
          scanParticipants();
          checkMeetingEndedScreen();
        }, SCAN_INTERVAL_MS);
      }
    }
  }

  // Jalankan inisialisasi saat siap
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Pantau perubahan URL SPA Google Meet
  let lastUrl = location.href;
  new MutationObserver(() => {
    checkMeetingEndedScreen();
    const url = location.href;
    if (url !== lastUrl) {
      lastUrl = url;
      init();
    }
  }).observe(document, { subtree: true, childList: true });
})();
