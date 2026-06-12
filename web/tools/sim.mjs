// Headless verification of logic.js against design/thresholds.md.
// Naive bot (reference-style) + contrast bot (deliberately bad) + determinism.
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

function act(stRef, action) {
	const v = L.validateAction(stRef.st, "solo", action);
	if (!v.ok) throw new Error("bot tried illegal action " + JSON.stringify(action) + " -> " + v.error);
	stRef.st = L.applyAction(stRef.st, "solo", action);
}

function playRun(seed, opts) {
	const rng = mulberry(seed ^ 0x9E3779B9);
	const ref = { st: L.setup(["solo"], seed) };
	let guard = 0;
	const deathInfo = { day: 0, act: 1 };
	while (!ref.st.over && guard++ < 5000) {
		const st = ref.st;
		// Claim pending rewards.
		if (st.cardChoices) {
			act(ref, { type: "pickCard", card: st.cardChoices[Math.floor(rng() * st.cardChoices.length)] });
			continue;
		}
		if (st.pending > 0) {
			const kinds = ["energy", "health", "card"];
			act(ref, { type: "reward", kind: kinds[Math.floor(rng() * 3)] });
			continue;
		}
		// Hand first.
		let done = false;
		for (let i = 0; i < st.hand.length; i++) {
			if (opts.noBuild && L.CARDS[st.hand[i]].t === "b") continue;
			if (!L.cardBlockReason(st, st.hand[i])) { act(ref, { type: "play", index: i }); done = true; break; }
		}
		if (done) continue;
		// Gathers.
		for (const g of L.gatherList(st)) {
			if (opts.noWater && (g === "find_water" || g === "murky_water")) continue;
			// Tainted water costs HP — the reference line drinks it only on a deficit.
			if (g === "murky_water" && st.water >= 2) continue;
			if (!L.gatherBlockReason(st, g)) { act(ref, { type: "gather", card: g }); done = true; break; }
		}
		if (done) continue;
		// Act II upkeep: repair, then dismantle.
		if (st.act === 2 && !opts.noBuild) {
			outer:
			for (let t = 0; t < st.board.length; t++) {
				for (let s = 0; s < st.board[t].blds.length; s++) {
					const b = st.board[t].blds[s];
					if (!b.ruin && b.hp < b.maxHp && st.energy >= 2 && st.wood >= L.repairWoodCost(b)) {
						act(ref, { type: "repair", tile: t, slot: s }); done = true; break outer;
					}
					if (b.ruin && st.energy >= 1) {
						act(ref, { type: "dismantle", tile: t, slot: s }); done = true; break outer;
					}
				}
			}
		}
		if (done) continue;
		// Wander (max 2 moves a day).
		if ((st._moves || 0) < 2 && st.energy > L.C.MOVE_COST) {
			const adj = [];
			for (let t = 0; t < L.C.BOARD; t++) if (!L.moveBlockReason(st, t)) adj.push(t);
			if (adj.length > 0) {
				act(ref, { type: "move", tile: adj[Math.floor(rng() * adj.length)] });
				ref.st._moves = (st._moves || 0) + 1;
				continue;
			}
		}
		const dayBefore = ref.st.day;
		act(ref, { type: "endDay" });
		delete ref.st._moves;
		if (ref.st.over && !ref.st.won) { deathInfo.day = dayBefore; deathInfo.act = ref.st.act; }
	}
	if (!ref.st.over) throw new Error("run did not terminate (seed " + seed + ")");
	return { won: ref.st.won, days: ref.st.day, level: ref.st.level, act: ref.st.act, death: deathInfo, end: ref.st };
}

const RUNS = Number(process.argv[2] || 200);
let wins = 0, totalDays = 0, totalLvl = 0, lossDays = [], deathsPreBum = 0, deathsPostBum = 0;
for (let i = 0; i < RUNS; i++) {
	const r = playRun(1000 + i, {});
	wins += r.won ? 1 : 0;
	totalDays += r.days;
	totalLvl += r.level;
	if (!r.won) {
		lossDays.push(r.days);
		if (r.act === 2) deathsPostBum++; else deathsPreBum++;
	}
}
const avgLoss = lossDays.length ? lossDays.reduce((a, b) => a + b, 0) / lossDays.length : 0;
console.log(`naive bot: ${wins}/${RUNS} wins (${(100 * wins / RUNS).toFixed(0)}%), avg ${(totalDays / RUNS).toFixed(1)} days, avg level ${(totalLvl / RUNS).toFixed(1)}`);
console.log(`losses: ${lossDays.length} (avg day ${avgLoss.toFixed(1)}; pre-BUM ${deathsPreBum}, post-BUM ${deathsPostBum})`);

let cWins = 0;
for (let i = 0; i < 100; i++) cWins += playRun(5000 + i, { noBuild: true, noWater: true }).won ? 1 : 0;
console.log(`contrast bot: ${cWins}/100 wins (${cWins}%)`);

const a = playRun(424242, {});
const b = playRun(424242, {});
const same = JSON.stringify(a.end) === JSON.stringify(b.end);
console.log(`determinism: ${same ? "OK" : "FAILED"}`);

const winRate = wins / RUNS;
const ok = winRate >= 0.35 && winRate <= 0.75 && cWins < 5 && same && avgLoss >= 8;
console.log(ok ? "THRESHOLDS OK" : "THRESHOLDS VIOLATED");
process.exit(ok ? 0 : 1);
