extends RefCounted

const CLUES = {
 "notebook": ["01 / Victim's notebook", "22:10 — Audit complete. Security access logs were altered. Meet R at 22:30. Backup locked away.

A meeting was planned, not a surprise intrusion.", "A planned meeting with R; the victim was auditing access logs."],
 "footprint": ["02 / Partial boot print", "A wet size-11 utility boot impression leads FROM the service corridor toward the desk. A triangular heel section is missing. No matching track enters through the window.", "A damaged utility boot came through the service corridor."],
 "window": ["03 / Broken window", "Most glass lies on the OUTSIDE ledge. The latch was opened from inside. Dust on the inner sill is undisturbed.

The supposed entry point was staged after the confrontation.", "Glass distribution and an undisturbed sill contradict entry here."],
 "phone": ["04 / Phone messages", "21:42 ALEX: I want my money. We need to talk.
21:49 VICTIM: Tomorrow. Tonight is the audit.
22:08 MAYA: At the late screening. Back after midnight.
22:16 R: Service door. 22:30. Bring the original log.
22:18 VICTIM: It is in the drawer. You cannot erase this.", "R arranged a 22:30 meeting through the service entrance."],
 "key": ["05 / Brass drawer key", "A small brass key tagged DESK. Found beside the couch.

Collected: use it on the locked desk drawer.", "Unlocks the desk drawer."],
 "ledger": ["06 / Original access ledger", "22:28 — SERVICE / credential S-03 / R. VALE
22:36 — SERVICE / credential S-03 / R. VALE
22:41 — MAIN / patrol arrival

S-03 was assigned to Ryan Vale. A handwritten note records unauthorized paid access approved by S-03. The terminal override code is 0311.", "Ryan's credential entered at 22:28; his audit motive is recorded."],
 "cctv": ["07 / Recovered CCTV", "22:28:14 — Utility-uniform figure enters service corridor.
22:36:02 — Same figure leaves; right heel has a triangular gap.
22:35:18 — Window glass falls outward. No entry through window.

The face is obscured. Combine this with credential and boot evidence.", "Service corridor footage links the damaged boot to the entry."],
 "blood": ["08 / Disturbance at desk", "A small blood trace and a fallen glass mark the desk edge. Furniture suggests a brief struggle, with no trail from the window. Estimated incident window: 22:28–22:36.

No graphic remains are present; the victim was removed by responders.", "The confrontation occurred at the desk, not at the window."]
}
const PEOPLE = {
 "Alex": ["FRIEND • freelance photographer", "I sent that message. I was angry about the loan. But I was on a video call from 22:20 to 22:50. I never came upstairs.", "The threatening message is mine. The call record is available to police. I wear size-8 trainers, not utility boots.", "Threats are suspicious, but the timing and boot evidence do not put Alex in the apartment."],
 "Ryan": ["SECURITY • employee S-03", "I finished my round at 22:00. Nobody used the service door after that. I stayed in the lobby. The intruder must have used the window.", "S-03 is my credential, yes. I said nobody entered because… I did not want the audit to come up. The damaged boot is mine. I went up to get the log back. That does not prove what happened at the desk.", "His service-door denial conflicts with the ledger; the boot and footage tie him to the corridor."],
 "Maya": ["ROOMMATE • architecture student", "I left at 21:30 for a film and returned after midnight. The window latch was intact when I left. He was expecting someone from security.", "The screening ticket is timestamped 21:51 across town. I knew about the audit, but not the drawer code. The glass outside means someone inside broke it.", "Her account of the latch supports staging. She knew about the audit, but no recovered trace places her at the scene."]
}
const LINKS = {
 "ledger|phone": "PLANNED MEETING / R's message and S-03's entry coincide. The original log provides a motive.",
 "cctv|footprint": "PHYSICAL CORROBORATION / The corridor figure and the scene print share a damaged right heel.",
 "cctv|window": "STAGED ENTRY / No window entry is visible; glass falls outward during the service-door visit.",
 "ledger|notebook": "AUDIT MOTIVE / The victim's appointment concerns the access fraud in the original ledger."
}
static func pair(a: String, b: String) -> String:
 var items = [a,b]
 items.sort()
 return "|".join(items)


