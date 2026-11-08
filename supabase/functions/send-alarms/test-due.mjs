// node supabase/functions/send-alarms/test-due.mjs — checks when reminders fire
import { readFileSync } from "node:fs";
import assert from "node:assert";
const src = readFileSync(new URL("./index.ts", import.meta.url), "utf8").split("// <due>")[1].split("// </due>")[0];
const due = new Function(src + "; return due;")();

const S = {
  fixed: [{ id: "gym", title: "Gym", start: "07:00", days: [1], alarm: 10, skip: ["2026-11-16"] }],
  once: [
    { id: "call", title: "Call", start: "09:00", date: "2026-11-09", alarm: 0 },
    { id: "late", title: "Late", start: "00:05", date: "2026-11-10", alarm: 30 },
    { id: "none", title: "None", start: "09:00", date: "2026-11-09", alarm: null },
  ],
  done: {},
};
const at = (d, hm) => due(S, d, +hm.slice(0, 2) * 60 + +hm.slice(3)).map((a) => a.title);
const m = "2026-11-09"; // a Monday

assert.deepEqual(at(m, "06:50"), ["Gym"]);            // 10 min before 07:00
assert.deepEqual(at(m, "06:54"), ["Gym"]);            // still inside the 5-min catch-up window
assert.deepEqual(at(m, "06:55"), []);                 // window over
assert.deepEqual(at(m, "06:49"), []);                 // not yet
assert.deepEqual(at(m, "09:00"), ["Call"]);           // at start; "None" has no reminder
assert.deepEqual(at(m, "23:35"), ["Late"]);           // 00:05 tomorrow, 30 min before = tonight
assert.deepEqual(at("2026-11-16", "06:50"), []);      // skipped day
assert.deepEqual(at("2026-11-10", "06:50"), []);      // Tuesday, no Gym
S.done["2026-11-09|gym"] = 1;
assert.deepEqual(at(m, "06:50"), []);                 // already checked off
assert.equal(due(S, m, 540)[0].body, "Starting now · 09:00");
console.log("send-alarms due(): all checks passed");
