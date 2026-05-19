/**
 * Rolling state for anomaly detection.
 * Forta bots are stateful — we use in-memory ring buffers.
 */

const ethers = require("ethers");

class RollingWindow {
  constructor(windowMs) {
    this.windowMs = windowMs;
    this.items = [];
  }

  add(value) {
    const now = Date.now();
    this.items.push({ value, ts: now });
    this._evict();
  }

  _evict() {
    const cutoff = Date.now() - this.windowMs;
    while (this.items.length && this.items[0].ts < cutoff) {
      this.items.shift();
    }
  }

  count() {
    this._evict();
    return this.items.length;
  }

  sum() {
    this._evict();
    return this.items.reduce((s, i) => s + BigInt(i.value), 0n);
  }

  average() {
    this._evict();
    if (this.items.length === 0) return 0n;
    return this.sum() / BigInt(this.items.length);
  }
}

class AddressCounter {
  constructor(windowMs) {
    this.windowMs = windowMs;
    this.byAddress = new Map();
  }

  bump(address) {
    if (!this.byAddress.has(address)) {
      this.byAddress.set(address, new RollingWindow(this.windowMs));
    }
    this.byAddress.get(address).add(1);
  }

  count(address) {
    return this.byAddress.get(address)?.count() ?? 0;
  }
}

// Singleton state
const state = {
  // Rolling windows for anomaly detection
  mints24h: new RollingWindow(86400_000),
  burns1h: new RollingWindow(3600_000),
  channelOpensPerAddress: new AddressCounter(60_000),
  registrationsPerAddress: new AddressCounter(3600_000),
  spendsPerAgent: new AddressCounter(60_000),

  // Last-known prices for change detection
  modelPrices: new Map(),

  // Total counters
  alertsByCategory: new Map(),

  // Track if we're in "elevated alert" mode (after a pause event)
  elevatedAlert: false,
  elevatedUntil: 0,
};

function recordAlert(category) {
  const count = state.alertsByCategory.get(category) ?? 0;
  state.alertsByCategory.set(category, count + 1);
}

function maybeElevateAlerts() {
  state.elevatedAlert = true;
  state.elevatedUntil = Date.now() + 3600_000; // 1 hour
}

function isElevated() {
  if (Date.now() > state.elevatedUntil) state.elevatedAlert = false;
  return state.elevatedAlert;
}

module.exports = { state, RollingWindow, AddressCounter, recordAlert, maybeElevateAlerts, isElevated };
