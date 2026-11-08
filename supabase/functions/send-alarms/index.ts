// send-alarms: called every minute by pg_cron (see supabase.sql).
// For each user with a device in push_subs, finds items whose reminder time fell in the last
// few minutes (in that user's time zone) and pushes a notification to each of their devices.
// Secrets (Edge Functions → Secrets): VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY.
import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import webpush from "npm:web-push@3.6.7";

webpush.setVapidDetails("mailto:ttttang0923@gmail.com", Deno.env.get("VAPID_PUBLIC_KEY")!, Deno.env.get("VAPID_PRIVATE_KEY")!);
const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

// pure logic between the due markers is also run by test-due.mjs
// <due>
const WINDOW = 5; // minutes; a late or skipped cron run still catches reminders, push_log stops repeats
const mins = (t) => +t.slice(0, 2) * 60 + +t.slice(3, 5);
const nextDay = (d) => new Date(Date.parse(d + "T00:00Z") + 864e5).toISOString().slice(0, 10);
// same rules as itemsOf() in index.html
const itemsOn = (S, ds) => {
  const dow = new Date(ds + "T00:00Z").getUTCDay();
  return [
    ...(S.fixed || []).filter((f) => f.days.includes(dow) && (!f.from || f.from <= ds) && (!f.until || ds <= f.until) && !f.skip?.includes(ds)),
    ...(S.once || []).filter((o) => o.date === ds),
  ];
};
const before = (m) => (m >= 60 ? `${m / 60}h` : `${m} min`);
// reminders due at local minute `now` of local date `date`
const due = (S, date, now) => {
  const out = [];
  for (const [ds, off] of [[date, 0], [nextDay(date), 1440]]) {
    for (const i of itemsOn(S, ds)) {
      if (i.alarm == null || S.done?.[ds + "|" + i.id]) continue;
      const at = off + mins(i.start) - i.alarm;
      if (at > now - WINDOW && at <= now) {
        out.push({ key: `${ds}|${i.id}|${i.start}|${i.alarm}`, title: i.title, body: i.alarm ? `${i.start} · in ${before(i.alarm)}` : `Starting now · ${i.start}` });
      }
    }
  }
  return out;
};
// </due>

const localNow = (tz) => {
  const p = Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23" })
      .formatToParts(new Date()).map((x) => [x.type, x.value]),
  );
  return { date: `${p.year}-${p.month}-${p.day}`, now: +p.hour * 60 + +p.minute };
};

Deno.serve(async () => {
  const { data: subs, error } = await db.from("push_subs").select("endpoint, user_id, sub, tz");
  if (error) return new Response(error.message, { status: 500 });
  if (!subs.length) return new Response("no devices");
  // ponytail: reads every subscribed planner each minute; fine for friends, index alarms in a table if users grow
  const { data: rows } = await db.from("planner").select("user_id, data").in("user_id", [...new Set(subs.map((s) => s.user_id))]);
  let sent = 0;
  for (const r of rows ?? []) {
    const devices = subs.filter((s) => s.user_id === r.user_id);
    const { date, now } = localNow(devices[0].tz || "UTC");
    for (const a of due(r.data, date, now)) {
      // only the first run to log this reminder sends it
      const { error: dup } = await db.from("push_log").insert({ key: r.user_id + "|" + a.key });
      if (dup) continue;
      await Promise.all(devices.map((d) =>
        webpush.sendNotification(d.sub, JSON.stringify({ title: a.title, body: a.body, tag: a.key }))
          .then(() => sent++)
          // 404/410: the device unsubscribed or the app was removed
          .catch((e) => (e.statusCode === 404 || e.statusCode === 410) && db.from("push_subs").delete().eq("endpoint", d.endpoint))
      ));
    }
  }
  await db.from("push_log").delete().lt("at", new Date(Date.now() - 2 * 864e5).toISOString());
  return new Response(`sent ${sent}`);
});
