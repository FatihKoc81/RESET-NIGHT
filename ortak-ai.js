/* APP -> Ortak AI Merkezi. Gizli GATEWAY_TOKEN istemciye konmaz.
 * Yalnızca açıkça çağrılan sohbet/mesaj içerikleri gönderilir; uygulama verileri otomatik aktarılmaz.
 */
(function () {
  "use strict";
  var PROJECT = document.documentElement.getAttribute("data-ai-project") || "RESET-NIGHT";
  var BASE = "https://ortak-ai-merkezi.fatihkoc7.workers.dev";
  var authReady = null;

  function init() {
    if (!window.firebase || !window.FIREBASE_CONFIG) {
      return Promise.reject(new Error("Firebase SDK veya yapılandırması yüklenemedi."));
    }
    if (!firebase.apps.length) firebase.initializeApp(window.FIREBASE_CONFIG);
    var auth = firebase.auth();
    if (auth.currentUser) return Promise.resolve(auth.currentUser);
    if (!authReady) {
      authReady = auth.signInAnonymously().then(function (credential) {
        return credential.user;
      }).catch(function (error) {
        authReady = null;
        throw error;
      });
    }
    return authReady;
  }

  function token() {
    return init().then(function (user) { return user.getIdToken(); });
  }

  function request(path, options) {
    return token().then(function (idToken) {
      var headers = Object.assign({}, options && options.headers, {
        "Authorization": "Bearer " + idToken,
        "Content-Type": "application/json"
      });
      return fetch(BASE + path, Object.assign({}, options || {}, {
        headers: headers,
        cache: "no-store"
      }));
    }).then(function (response) {
      return response.text().then(function (body) {
        var data;
        try { data = body ? JSON.parse(body) : {}; } catch (_) { data = { raw: body }; }
        if (!response.ok) throw new Error(data.error || data.message || ("HTTP " + response.status));
        return data;
      });
    });
  }

  window.OrtakAIMerkezi = {
    proje: PROJECT,
    durum: function () {
      return init().then(function (user) {
        return { online: true, project: PROJECT, firebaseUid: user.uid };
      });
    },
    sohbet: function (message) {
      if (!message || !String(message).trim()) return Promise.reject(new Error("Mesaj boş olamaz."));
      return request("/app/chat", { method: "POST", body: JSON.stringify({ message: String(message) }) });
    },
    mesajGonder: function (to, content) {
      if (!to || !content || !String(content).trim()) return Promise.reject(new Error("Alıcı ve mesaj gerekli."));
      return request("/app/messages", {
        method: "POST",
        body: JSON.stringify({ from: PROJECT, to: String(to), content: String(content) })
      });
    },
    mesajlariGetir: function () {
      return request("/app/messages?project=" + encodeURIComponent(PROJECT), { method: "GET" });
    },
    seslendir: function (metin, dil) {
      metin = String(metin || "").trim();
      if (!metin) return Promise.reject(new Error("Seslendirilecek metin boş."));
      if (!window.speechSynthesis || typeof window.SpeechSynthesisUtterance !== "function") {
        return Promise.reject(new Error("Bu cihazın tarayıcısında sesli okuma desteklenmiyor."));
      }
      window.speechSynthesis.cancel();
      return new Promise(function (resolve, reject) {
        var utterance = new SpeechSynthesisUtterance(metin);
        utterance.lang = dil || "tr-TR";
        utterance.onend = function () { resolve(true); };
        utterance.onerror = function (event) { reject(new Error(event.error || "Sesli okuma başarısız.")); };
        window.speechSynthesis.speak(utterance);
      });
    },
    sesDurdur: function () {
      if (window.speechSynthesis) window.speechSynthesis.cancel();
    }
  };

  // Oturum hazırlığı; hiçbir uygulama/finans/oyun verisi gönderilmez.
  init().catch(function (error) {
    console.warn("[Ortak AI] Firebase oturumu kurulamadı:", error.message);
  });
})();
