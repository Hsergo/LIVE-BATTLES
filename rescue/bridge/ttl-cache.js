'use strict';
// Bounded caches for long broadcasts. Values expire even below capacity.
class TtlCache {
  constructor(limit, ttl, now = Date.now) {
    this.limit = limit;
    this.ttl = ttl;
    this.now = now;
    this.items = new Map();
  }
  get size() { return this.items.size; }
  get(key) {
    const entry = this.items.get(key);
    if (!entry) return undefined;
    if (this.now() - entry.at >= this.ttl) {
      this.items.delete(key);
      return undefined;
    }
    return entry.value;
  }
  set(key, value) {
    this.items.delete(key);
    this.items.set(key, {value, at: this.now()});
    while (this.items.size > this.limit) this.items.delete(this.items.keys().next().value);
  }
}
module.exports = {TtlCache};
