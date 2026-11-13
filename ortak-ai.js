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
    },

    konusmayiBaslat: function (aralikMs) {
      var self = this;
      var aktif = true;
      var bilinen = Object.create(null);
      var bekleme = Math.max(5000, Number(aralikMs) || 12000);
      function mesajListesi(data) {
        if (Array.isArray(data)) return data;
        if (data && Array.isArray(data.messages)) return data.messages;
        if (data && Array.isArray(data.items)) return data.items;
        if (data && Array.isArray(data.data)) return data.data;
        return [];
      }
      function tur() {
        if (!aktif) return;
        self.mesajlariGetir().then(function (data) {
          var messages = mesajListesi(data);
          messages.forEach(function (m, index) {
            var from = String(m.from || m.sender || m.project || "");
            var to = String(m.to || "");
            var rawContent = String(m.content || m.message || m.text || "").trim();
            var depthMatch = rawContent.match(/^\[\[ORTAK_AI_TUR:(\d+)\]\]\s*/);
            var depth = depthMatch ? Number(depthMatch[1]) : 0;
            var content = rawContent.replace(/^\[\[ORTAK_AI_TUR:\d+\]\]\s*/, "").trim();
            var id = String(m.id || m.messageId || (from + "|" + content + "|" + index));
            if (!content || depth >= 3 || from === "RESET-NIGHT" || (to && to !== "RESET-NIGHT") || bilinen[id]) return;
            bilinen[id] = true;
            self.seslendir(from + " diyor ki: " + content).catch(function () {});
            self.sohbet("Sen RESET-NIGHT uygulamasının yapay zekâ asistanısın. " +
              from + " uygulamasından şu mesaj geldi: " + content +
              " Kısa, doğal ve Türkçe bir cevap ver. Yalnızca cevabı yaz.").then(function (answer) {
                var reply = String(answer.response || answer.reply || answer.text || "").trim();
                if (reply) {
                  self.mesajGonder(from, "[[ORTAK_AI_TUR:" + (depth + 1) + "]] " + reply).then(function () {
                    self.seslendir("Yanıtım: " + reply).catch(function () {});
                  }).catch(function () {});
                }
              }).catch(function () {});
          });
        }).catch(function () {}).then(function () {
          if (aktif) setTimeout(tur, bekleme);
        });
      }
      tur();
      return function () { aktif = false; };
    }
  };

  // Oturum hazırlığı; hiçbir uygulama/finans/oyun verisi gönderilmez.
  init().catch(function (error) {
    console.warn("[Ortak AI] Firebase oturumu kurulamadı:", error.message);
  });
})();
