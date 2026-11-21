const config = require('../config');
const { createMemoryStore } = require('./memoryStore');

let store;

function getStore() {
  if (!store) {
    if (config.dbDriver === 'firestore') {
      const { createFirestoreStore } = require('./firestoreStore');
      store = createFirestoreStore(config.firebase);
    } else {
      store = createMemoryStore();
    }
  }
  return store;
}

// Lets tests swap in a fresh store.
function setStore(s) {
  store = s;
}

module.exports = { getStore, setStore };
