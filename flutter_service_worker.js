'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "888483df48293866f9f41d3d9274a779",
"icons/Icon-512.png": "2031554b770a54b03f1c27ed032a35d6",
"icons/Icon-maskable-512.png": "2031554b770a54b03f1c27ed032a35d6",
"icons/Icon-192.png": "f7b2d8f56492a2cadcc1cf93c2c57067",
"icons/Icon-maskable-192.png": "f7b2d8f56492a2cadcc1cf93c2c57067",
"manifest.json": "7ddbb27b61c7f996ae576ffc10a1f802",
"index.html": "1f9206afe3b57eb69d6c01e71b36b97d",
"/": "1f9206afe3b57eb69d6c01e71b36b97d",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "4bf0a8a4f3957fbbec537053108919eb",
"assets/assets/music/Mr_Smith-Azul.mp3": "9463595498dc48b3d3d6805fb7c19dc7",
"assets/assets/music/Mr_Smith-Sonorus.mp3": "9353b7bb732002062e2c9107a95f3d2a",
"assets/assets/music/README.md": "035041cfb2070f794172dedb2aa709b6",
"assets/assets/music/Mr_Smith-Sunday_Solitude.mp3": "5fb1f2fbf4314eb5df35b62706942698",
"assets/assets/images/back.png": "3c82301693d5c4140786184a06c23f7e",
"assets/assets/images/2x/back.png": "85cda8f41a13153d6f3fb1c403f272ea",
"assets/assets/images/2x/restart.png": "83aea4677055df9b0d8171f5315f2a60",
"assets/assets/images/2x/settings.png": "8404e18c68ba99ca0b181bd96ace0376",
"assets/assets/images/goblin_cards/goblin_bg_001.png": "8e4765b1a36a0eb86c0374792b05934d",
"assets/assets/images/goblin_cards/goblin_1_012.png": "20868035aa43944efb4daa9c7a0ec212",
"assets/assets/images/goblin_cards/goblin_qr.png": "f250c6f06865ff0fda5abe078667048a",
"assets/assets/images/goblin_cards/goblin_1_000.png": "bbf6b3ec6bb048480ee308e1971aba05",
"assets/assets/images/goblin_cards/goblin_1_010.png": "07dea8f3f5d38113ba3b54e90566eb16",
"assets/assets/images/goblin_cards/goblin_1_004.png": "e7298daf6867399d59186c2dfa9503f8",
"assets/assets/images/goblin_cards/goblin_1_007.png": "d156687bc0f874f4a36e10837284d985",
"assets/assets/images/goblin_cards/goblin_1_008.png": "550fa43416149d28a2823f423aa47220",
"assets/assets/images/goblin_cards/goblin_1_017.png": "a97c4666bd14269b73b85c4407d47876",
"assets/assets/images/goblin_cards/goblin_1_009.png": "164bac14168aa43c3d9377139b067670",
"assets/assets/images/goblin_cards/goblin_1_015.png": "71b29fc37d988a3fb8bda4ef43f10b23",
"assets/assets/images/goblin_cards/goblin_1_014.png": "ce39ccd10bcf3e5ffea01824a7ab1974",
"assets/assets/images/goblin_cards/goblin_1_016.png": "bf7ea77669d6a6b5006e4c748d9bb2c2",
"assets/assets/images/goblin_cards/goblin_1_005.png": "bc29634536521ee2246f4ae7756a7cb6",
"assets/assets/images/goblin_cards/goblin_1_011.png": "0e51edb0f8f070d4e73a3fd86fedb3ff",
"assets/assets/images/goblin_cards/goblin_1_006.png": "9e1620195c1fbe2bfec711f207beafc4",
"assets/assets/images/goblin_cards/goblin_1_002.png": "d446503d27aa45385cb7bd4961978677",
"assets/assets/images/goblin_cards/goblin_1_013.png": "688b19edd1194a21eadaff023a26a1e6",
"assets/assets/images/goblin_cards/goblin_1_003.png": "e85262154d31fd26a634fe285c1a0699",
"assets/assets/images/goblin_cards/goblin_1_001.png": "82ace7e47ad492a34780bad5fcf4d354",
"assets/assets/images/goblin_cards/goblin_bg_002.png": "4c1cec580959daea7add6c381baf6876",
"assets/assets/images/3.5x/back.png": "85db134e26410547037485447f659277",
"assets/assets/images/3.5x/restart.png": "583169ac365d9515fc12f29e3b530de0",
"assets/assets/images/3.5x/settings.png": "c977a1e6c59e8cfd5cd88a0c973928fc",
"assets/assets/images/3x/back.png": "88a977a654df5a490037340f90a5a19e",
"assets/assets/images/3x/restart.png": "429270ce832c881b80fbd592e5ff1e0e",
"assets/assets/images/3x/settings.png": "21ff2cc135a762f74ed1a80aac6502bb",
"assets/assets/images/restart.png": "d3d2e3f3b2f6cb1e1a69b8b2529096f7",
"assets/assets/images/settings.png": "840fd7e3337c743046bf992ef18a10b8",
"assets/assets/images/zoo_cards/zoo_cards_007.png": "0e8bfbbeefc1649c6e9bd6e46c49be68",
"assets/assets/images/zoo_cards/zoo_cards_010.png": "4cc18980b95e8db2d32122289c695dd0",
"assets/assets/images/zoo_cards/zoo_cards_005.png": "155b306fb81952ea1c08735e9fc6f2a9",
"assets/assets/images/zoo_cards/zoo_cards_008.png": "0606648e5699915e4820a43c5a19a5fc",
"assets/assets/images/zoo_cards/zoo_cards_006.png": "00be409ab7ef9501e4ac59f05d274769",
"assets/assets/images/zoo_cards/zoo_cards_000.png": "f3b741f1d6499d711534bf1a9634b8f0",
"assets/assets/images/zoo_cards/zoo_cards_011.png": "198655a538847be22a8504f8464ade3e",
"assets/assets/images/zoo_cards/zoo_cards_012.png": "4662335884fd2ebe3118aa0a3733ef3b",
"assets/assets/images/zoo_cards/zoo_bg_002.png": "65ccfcf48989aa0b11504384c3650148",
"assets/assets/images/zoo_cards/zoo_cards_009.png": "dd2cfef2961a8f4f7d737ed00392e11a",
"assets/assets/images/zoo_cards/zoo_cards_013.png": "406e4bd242d736ffad882dfba2a7c4dc",
"assets/assets/images/zoo_cards/zoo_cards_002.png": "55874cba98d003b8e9bfd8e6ff7f45c5",
"assets/assets/images/zoo_cards/zoo_cards_001.png": "664d4bebc1fee686a183027204271c25",
"assets/assets/images/zoo_cards/zoo_bg_001.png": "9b121eb4e3abddb53790696959a2c811",
"assets/assets/images/zoo_cards/zoo_cards_003.png": "6f992391e36592a78a1549d41eae04c8",
"assets/assets/images/zoo_cards/zoo_cards_004.png": "28d756dd318514f2eede0b66af1797b7",
"assets/assets/images/zoo_cards/zoo_cards_back_001.png": "a3137909da76b93fa7b8422affe1c4d9",
"assets/assets/sfx/swishswish1.mp3": "219b0f5c2deec2eda0a9e0e941894cb6",
"assets/assets/sfx/k1.mp3": "37ffb6f8c0435298b0a02e4e302e5b1f",
"assets/assets/sfx/hash3.mp3": "38aad045fbbf951bf5e4ca882b56245e",
"assets/assets/sfx/p1.mp3": "ad28c0d29ac9e8adf9a91a46bfbfac82",
"assets/assets/sfx/wehee1.mp3": "5a986231104c9f084104e5ee1c564bc4",
"assets/assets/sfx/hash2.mp3": "d26cb7676c3c0d13a78799b3ccac4103",
"assets/assets/sfx/oo1.mp3": "94b9149911d0f2de8f3880c524b93683",
"assets/assets/sfx/fwfwfwfw1.mp3": "d0f7ee0256d1f0d40d77a1264f23342b",
"assets/assets/sfx/dsht1.mp3": "c99ece72f0957a9eaf52ade494465946",
"assets/assets/sfx/spsh1.mp3": "2e1354f39a5988afabb2fdd27cba63e1",
"assets/assets/sfx/haw1.mp3": "00db66b69283acb63a887136dfe7a73c",
"assets/assets/sfx/yay1.mp3": "8d3b940e33ccfec612d06a41ae616f71",
"assets/assets/sfx/kch1.mp3": "a832ed0c8798b4ec95c929a5b0cabd3f",
"assets/assets/sfx/hh2.mp3": "4d39e7365b89c74db536c32dfe35580b",
"assets/assets/sfx/kss1.mp3": "fd0664b62bb9205c1ba6868d2d185897",
"assets/assets/sfx/README.md": "33033a0943d1325f78116fcf4b8a96ec",
"assets/assets/sfx/sh1.mp3": "f695db540ae0ea850ecbb341a825a47b",
"assets/assets/sfx/wssh1.mp3": "cf92e8d8483097569e3278c82ac9f871",
"assets/assets/sfx/k2.mp3": "8ec44723c33a1e41f9a96d6bbecde6b9",
"assets/assets/sfx/hh1.mp3": "fab21158730b078ce90568ce2055db07",
"assets/assets/sfx/p2.mp3": "ab829255f1ef20fbd4340a7c9e5157ad",
"assets/assets/sfx/lalala1.mp3": "b0b85bf59814b014ff48d6d79275ecfd",
"assets/assets/sfx/hash1.mp3": "f444469cd7a5a27062580ecd2b481770",
"assets/assets/sfx/fwfwfwfwfw1.mp3": "46355605b43594b67a39170f89141dc1",
"assets/assets/sfx/wssh2.mp3": "255c455d9692c697400696cbb28511cc",
"assets/assets/sfx/ehehee1.mp3": "52f5042736fa3f4d4198b97fe50ce7f3",
"assets/assets/sfx/sh2.mp3": "e3212b9a7d1456ecda26fdc263ddd3d0",
"assets/assets/sfx/ws1.mp3": "5cfa8fda1ee940e65a19391ddef4d477",
"assets/assets/fonts/Permanent_Marker/PermanentMarker-Regular.ttf": "c863f8028c2505f92540e0ba7c379002",
"assets/assets/translations/en.json": "e6c46abf2853720f01a797ecf00fcae4",
"assets/assets/translations/zh-TW.json": "4e164186a850a4af56bcad8a38126267",
"assets/assets/translations/ja.json": "46aa3692c915d6d7e9a37e6692bef911",
"assets/fonts/MaterialIcons-Regular.otf": "c2abec87a7790ae4c2b9baa88630d7d2",
"assets/NOTICES": "535ed80efb8f2f20849a01606f0b4e5e",
"assets/FontManifest.json": "5e2e227128bf6801aac836244107e2d2",
"assets/AssetManifest.bin": "eedc884bf2e4ba7c4c175457053ef0c7",
"assets/AssetManifest.json": "6b11909fced656d70b32d7132788c592",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"favicon.png": "015516bf31252959e84c581e8e1bd1e7",
"flutter_bootstrap.js": "b3feedc93fb1f109216e07bbf136f438",
"version.json": "e72e233bd2f6fd2044fe74f1367cb635",
"main.dart.js": "a8635bfeb86ee706645643e3431415bd"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
