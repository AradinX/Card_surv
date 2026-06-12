// Diagnosis: where do lost runs bleed HP? Aggregates damage sources from
// the logs of lost runs (whole run, plus the final 5 days separately).
import * as L from "../public/logic.js";

function mulberry(seed) {
	let s = seed >>> 0;
	return () => {
		s = (s + 0x6D2B79F5) >>> 0;
		let r = s;
		r = Math.imul(r ^ (r >>> 15), r | 1);
		r ^= r + Math.imul(r ^ (r >>> 7), r | 61);
		return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
	};
}

function playRun(seed) {
	const rng = mulberry(seed ^ 0x9E3779B9);
	let st = L.setup(["solo"], seed);
	const full = [];
	let guard = 0;
	const push = (s) => { full.push(...s.log.slice(full.length > 200 ? 0 : full.length)); };
	while (!st.over && guard++ < 5000) {
		if (st.cardChoices) { st = L.applyAction(st, "solo", { type: "pickCard", card: st.cardChoices[Math.floor(rng() * st.cardChoices.length)] }); continue; }
		if (st.pending > 0) { st = L.applyAction(st, "solo", { type: "reward", kind: ["energy", "health", "card"][Math.floor(rng() * 3)] }); continue; }
		let done = false;
		for (let i = 0; i < st.hand.length; i++) if (!L.cardBlockReason(st, st.hand[i])) { st = L.applyAction(st, "solo", { type: "play", index: i }); done = true; break; }
		if (done) continue;
		for (const g of L.gatherList(st)) if (!L.gatherBlockReason(st, g)) { st = L.applyAction(st, "solo", { type: "gather", card: g }); done = true; break; }
		if (done) continue;
		if (st.act === 2) {
			outer:
			for (let t = 0; t < st.board.length; t++) for (let s = 0; s < st.board[t].blds.length; s++) {
				const b = st.board[t].blds[s];
				if (!b.ruin && b.hp < b.maxHp && st.energy >= 2 && st.wood >= L.repairWoodCost(b)) { st = L.applyAction(st, "solo", { type: "repair", tile: t, slot: s }); done = true; break outer; }
				if (b.ruin && st.energy >= 1) { st = L.applyAction(st, "solo", { type: "dismantle", tile: t, slot: s }); done = true; break outer; }
			}
		}
		if (done) continue;
		if ((st._moves || 0) < 2 && st.energy > L.C.MOVE_COST) {
			const adj = [];
			for (let t = 0; t < L.C.BOARD; t++) if (!L.moveBlockReason(st, t)) adj.push(t);
			if (adj.length) { const m = (st._moves || 0) + 1; st = L.applyAction(st, "solo", { type: "move", tile: adj[Math.floor(rng() * adj.length)] }); st._moves = m; continue; }
		}
		st = L.applyAction(st, "solo", { type: "endDay" });
		delete st._moves;
	}
	return st;
}

const agg = { starve: 0, dehydrate: 0, freeze: 0, monsterHp: 0, eventHp: 0, murkyUses: 0, rebuilds: 0, losses: 0 };
const EVHP = (id) => Math.abs(L.EVENTS[id].hp || 0);
for (let i = 0; i < 100; i++) {
	const st = playRun(1000 + i);
	if (st.won) continue;
	agg.losses++;
	for (const e of st.log) {
		if (e.t === "starve") agg.starve += 2;
		else if (e.t === "dehydrate") agg.dehydrate += 2;
		else if (e.t === "freeze") agg.freeze += 2;
		else if (e.t === "monster") agg.monsterHp += e.dp;
		else if (e.t === "event") agg.eventHp += e.sheltered ? Math.max(0, EVHP(e.e) - 2) : EVHP(e.e);
		else if (e.t === "gather" && e.c === "murky_water") agg.murkyUses++;
		else if (e.t === "build") agg.rebuilds++;
	}
}
console.log(JSON.stringify(agg, null, 1));
console.log("note: log keeps last 200 entries (~most of a run)");
