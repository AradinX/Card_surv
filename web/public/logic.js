// "Dzień 50" — pure rules module (no imports, no timers, JSON-safe state).
// Solo survival card roguelike: Act I settlement building on a 3x2 biome
// board, BUM catastrophe mid-run, Act II monsters, win at day 30.
// All player-visible text lives in strings.js — this module logs CODES.

export const meta = { game: "dzien-50", minPlayers: 1, maxPlayers: 1 };

// --- Balance constants (ported from the Godot vertical slice) ---
export const C = {
	WIN_DAY: 30,
	BUM_MIN: 12,
	BUM_MAX: 15,
	HAND: 4,
	MOVE_COST: 1,
	HUNGER_DECAY: 2,
	THIRST_DECAY: 2,
	WARMTH_DECAY: 1,
	FOOD_VALUE: 3, // Kucharz: 2 * 1.5
	WATER_VALUE: 2,
	DEFICIENCY_DMG: 2,
	NIGHT_PROTECTION: 2,
	TOOLS_BONUS: 1,
	BUILD_ENERGY_DELTA: 1, // Kucharz: building costs +1 energy
	XP_CARD: 1,
	XP_BUILDING: 3,
	XP_BASE: 8,
	XP_GROWTH: 4,
	MAX_START: 10,
	GRID_COLS: 3,
	BOARD: 6,
};

// --- Cards: t = "a" action | "b" building ---
export const CARDS = {
	forage: { t: "a", e: 1, food: 1, hunger: 1 },
	gather_wood: { t: "a", e: 2, wood: 2 },
	hunt: { t: "a", e: 3, food: 3 },
	scavenge: { t: "a", e: 2, materials: 2 },
	rest: { t: "a", e: 0, energy: 2 },
	first_aid: { t: "a", e: 1, costM: 1, hp: 2 },
	explore: { t: "a", e: 3, special: "explore" },
	campfire_act: { t: "a", e: 1, costW: 2, warmth: 2 },
	find_water: { t: "a", e: 1, water: 2 },
	murky_water: { t: "a", e: 1, water: 2, hp: -1 },
	adrenaline: { t: "a", e: 0, hp: -1, energy: 3 },
	big_hunt: { t: "a", e: 4, food: 5 },
	expedition: { t: "a", e: 4, special: "double_explore" },
	feast: { t: "a", e: 1, costF: 3, hunger: 5, hp: 1 },
	fishing: { t: "a", e: 2, food: 2 },
	gather_sticks: { t: "a", e: 1, wood: 1 },
	herbs: { t: "a", e: 2, hp: 2 },
	scout: { t: "a", e: 1, special: "draw_two" },
	snare_trap: { t: "a", e: 1, costM: 1, food: 2 },
	woodcraft: { t: "a", e: 2, costW: 1, materials: 2 },
	craft_tools: { t: "a", e: 2, costM: 2, special: "craft_tools" },
	bld_campfire: { t: "b", e: 1, costW: 2, hp: 6, night: { warmth: 2 } },
	bld_well: { t: "b", e: 2, costW: 1, costM: 1, hp: 8, night: { water: 2 } },
	bld_hut: { t: "b", e: 2, costW: 3, hp: 8, protection: true },
	bld_palisade: { t: "b", e: 2, costW: 2, costM: 2, hp: 12, defBld: 2 },
	bld_torches: { t: "b", e: 1, costW: 1, costM: 1, hp: 5, night: { warmth: 1 }, defPlayer: 1 },
};

// --- End-of-day events; monsters carry m: {p: player dmg, b: building dmg} ---
export const EVENTS = {
	berry_patch: { food: 2 },
	calm_day: {},
	cold_night: { warmth: -3, protected: true },
	fog: { nextE: -1 },
	lucky_find: { materials: 2 },
	rain: { hp: -1, warmth: -1, water: 1, protected: true },
	rats: { food: -2 },
	sickness: { hp: -2, nextE: -1 },
	storm: { hp: -3, protected: true },
	sunny: { nextE: 1 },
	wanderer: { food: 1, materials: 1 },
	wolves: { hp: -3, food: -1, protected: true },
	plague_rot: { food: -2, hp: -1 },
	zgnilec: { m: { p: 3, b: 2 } },
	wyjec: { m: { p: 4, b: 0 } },
};
const BASE_EVENTS = [
	"berry_patch", "calm_day", "cold_night", "fog", "lucky_find", "rain",
	"rats", "sickness", "storm", "sunny", "wanderer", "wolves",
];
const BUM_EVENTS = ["zgnilec", "zgnilec", "zgnilec", "zgnilec", "wyjec", "wyjec", "wyjec", "plague_rot", "plague_rot"];

// --- Biomes: normal face + corrupted face (after BUM) ---
export const BIOMES = {
	forest: {
		slots: 3,
		gather: ["gather_wood", "forage", "hunt", "find_water"],
		extraEvents: ["wolves"],
		corGather: ["scavenge", "murky_water"],
	},
	meadows: {
		slots: 4,
		gather: ["forage", "snare_trap"],
		extraEvents: ["sunny"],
		corGather: ["scavenge"],
	},
	mountains: {
		slots: 2,
		gather: ["scavenge", "gather_sticks", "find_water"],
		extraEvents: ["cold_night", "storm"],
		corGather: ["gather_sticks", "murky_water"],
	},
};
const BIOME_POOL = ["forest", "meadows", "mountains"];

export const STARTER_DECK = [
	"forage", "forage", "gather_wood", "gather_wood", "hunt", "scavenge",
	"rest", "first_aid", "explore", "bld_campfire", "bld_well", "bld_hut",
];
export const REWARD_POOL_1 = [
	"adrenaline", "big_hunt", "campfire_act", "craft_tools", "expedition",
	"explore", "feast", "find_water", "first_aid", "fishing", "forage",
	"gather_sticks", "gather_wood", "herbs", "hunt", "rest", "scavenge",
	"scout", "snare_trap", "woodcraft",
];
export const REWARD_POOL_2 = REWARD_POOL_1.concat(["bld_palisade", "bld_torches"]);

// --- Deterministic RNG (mulberry32 over state.rng) ---
function rand(st) {
	st.rng = (st.rng + 0x6D2B79F5) >>> 0;
	let r = st.rng;
	r = Math.imul(r ^ (r >>> 15), r | 1);
	r ^= r + Math.imul(r ^ (r >>> 7), r | 61);
	return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
}
function randInt(st, lo, hi) { return lo + Math.floor(rand(st) * (hi - lo + 1)); }
function shuffle(st, arr) {
	for (let i = arr.length - 1; i > 0; i--) {
		const j = randInt(st, 0, i);
		const t = arr[i]; arr[i] = arr[j]; arr[j] = t;
	}
	return arr;
}

function log(st, entry) {
	st.log.push(entry);
	if (st.log.length > 200) st.log.splice(0, st.log.length - 200);
}

// --- Setup ---
export function setup(players, seed) {
	const st = {
		pid: players && players[0] ? players[0] : "solo",
		rng: (seed === undefined || seed === null) ? ((Math.random() * 4294967296) >>> 0) : (seed >>> 0),
		day: 1, act: 1, bumDay: 0, bumHappened: false,
		hp: C.MAX_START, maxHp: C.MAX_START,
		hunger: 8, thirst: 8, warmth: 8,
		energy: C.MAX_START, maxEnergy: C.MAX_START,
		food: 2, water: 2, wood: 0, materials: 0,
		tools: false, nextDayE: 0,
		xp: 0, level: 1, pending: 0, cardChoices: null,
		deck: STARTER_DECK.slice(),
		drawPile: [], hand: [],
		board: [], pos: 0, usedGathers: [],
		eventDraw: [], eventDiscard: [],
		log: [], over: false, won: false,
	};
	st.bumDay = randInt(st, C.BUM_MIN, C.BUM_MAX);
	// Board: every pool biome at least once, the rest random, then placed randomly.
	const picked = shuffle(st, BIOME_POOL.slice());
	while (picked.length < C.BOARD) picked.push(BIOME_POOL[randInt(st, 0, BIOME_POOL.length - 1)]);
	shuffle(st, picked);
	st.board = picked.map((b) => ({ b, cor: false, blds: [] }));
	st.pos = randInt(st, 0, C.BOARD - 1);
	// Event deck: base events + each board tile's biome hazards.
	const events = BASE_EVENTS.slice();
	for (const tile of st.board) events.push(...BIOMES[tile.b].extraEvents);
	st.eventDraw = shuffle(st, events);
	dawn(st);
	return st;
}

function dawn(st) {
	st.usedGathers = [];
	st.energy = Math.max(1, Math.min(st.maxEnergy + st.nextDayE, st.maxEnergy + 1));
	st.nextDayE = 0;
	st.drawPile = shuffle(st, st.deck.slice());
	st.hand = st.drawPile.splice(0, C.HAND);
	log(st, { t: "day", d: st.day });
}

// --- Helpers ---
export function areAdjacent(a, b) {
	if (a === b || a < 0 || b < 0 || a >= C.BOARD || b >= C.BOARD) return false;
	const ra = Math.floor(a / C.GRID_COLS), rb = Math.floor(b / C.GRID_COLS);
	const ca = a % C.GRID_COLS, cb = b % C.GRID_COLS;
	return Math.abs(ra - rb) + Math.abs(ca - cb) === 1;
}
export function gatherList(st) {
	const tile = st.board[st.pos];
	return tile.cor ? BIOMES[tile.b].corGather : BIOMES[tile.b].gather;
}
export function xpCost(level) { return C.XP_BASE + C.XP_GROWTH * (level - 1); }
function bldActive(b) { return !b.ruin; }
function anyActive(st, pred) {
	for (const tile of st.board) for (const b of tile.blds) if (bldActive(b) && pred(CARDS[b.id])) return true;
	return false;
}
function defSum(st, key) {
	let sum = 0;
	for (const tile of st.board) for (const b of tile.blds) if (bldActive(b) && CARDS[b.id][key]) sum += CARDS[b.id][key];
	return sum;
}
function reflag(b) {
	if (b.hp <= 0 || b.hp < Math.ceil(b.maxHp * 0.5)) { b.ruin = true; b.hp = Math.max(0, b.hp); }
}
export function repairWoodCost(b) { return Math.ceil((b.maxHp - b.hp) / 3); }

function costCheck(st, card, isBuilding) {
	const e = card.e + (isBuilding ? C.BUILD_ENERGY_DELTA : 0);
	if (st.energy < e) return "noEnergy";
	if ((card.costF || 0) > st.food) return "noFood";
	if ((card.costW || 0) > st.wood) return "noWood";
	if ((card.costM || 0) > st.materials) return "noMaterials";
	return null;
}
export function cardBlockReason(st, id) {
	const card = CARDS[id];
	if (!card) return "invalid";
	if (card.t === "b") {
		const tile = st.board[st.pos];
		if (tile.blds.length >= BIOMES[tile.b].slots) return "noSlot";
		return costCheck(st, card, true);
	}
	if (card.special === "craft_tools" && st.tools) return "hasTools";
	return costCheck(st, card, false);
}
export function gatherBlockReason(st, id) {
	if (!gatherList(st).includes(id)) return "invalid";
	if (st.usedGathers.includes(st.pos + ":" + id)) return "gatherUsed";
	return costCheck(st, CARDS[id], false);
}
export function moveBlockReason(st, tile) {
	if (!areAdjacent(st.pos, tile)) return "notAdjacent";
	if (st.energy < C.MOVE_COST) return "noEnergy";
	return null;
}

// --- Contract: validateAction ---
export function validateAction(state, playerId, action) {
	if (!action || typeof action.type !== "string") return { ok: false, error: "invalid" };
	if (state.over) return { ok: false, error: "dayOver" };
	const fail = (code) => ({ ok: false, error: code });
	switch (action.type) {
		case "play": {
			if (!Number.isInteger(action.index) || action.index < 0 || action.index >= state.hand.length) return fail("invalid");
			const r = cardBlockReason(state, state.hand[action.index]);
			return r ? fail(r) : { ok: true };
		}
		case "gather": {
			const r = gatherBlockReason(state, action.card);
			return r ? fail(r) : { ok: true };
		}
		case "move": {
			if (!Number.isInteger(action.tile)) return fail("invalid");
			const r = moveBlockReason(state, action.tile);
			return r ? fail(r) : { ok: true };
		}
		case "endDay":
			return { ok: true };
		case "reward": {
			if (state.pending <= 0 || state.cardChoices) return fail("invalid");
			if (!["energy", "health", "card"].includes(action.kind)) return fail("invalid");
			return { ok: true };
		}
		case "pickCard": {
			if (!state.cardChoices || !state.cardChoices.includes(action.card)) return fail("invalid");
			return { ok: true };
		}
		case "repair": {
			const b = (state.board[action.tile] || { blds: [] }).blds[action.slot];
			if (!b || b.ruin || b.hp >= b.maxHp) return fail("invalid");
			if (state.energy < 2) return fail("noEnergy");
			if (state.wood < repairWoodCost(b)) return fail("noWood");
			return { ok: true };
		}
		case "dismantle": {
			const b = (state.board[action.tile] || { blds: [] }).blds[action.slot];
			if (!b || !b.ruin) return fail("invalid");
			if (state.energy < 1) return fail("noEnergy");
			return { ok: true };
		}
		default:
			return fail("invalid");
	}
}

// --- Contract: applyAction (clone, mutate the clone, return it) ---
export function applyAction(state, playerId, action) {
	const st = JSON.parse(JSON.stringify(state));
	switch (action.type) {
		case "play": playCard(st, action.index); break;
		case "gather": playGather(st, action.card); break;
		case "move": doMove(st, action.tile); break;
		case "endDay": night(st); break;
		case "reward": claimReward(st, action.kind); break;
		case "pickCard": pickCard(st, action.card); break;
		case "repair": doRepair(st, action.tile, action.slot); break;
		case "dismantle": doDismantle(st, action.tile, action.slot); break;
	}
	return st;
}

function grantXp(st, n) {
	st.xp += n;
	while (st.xp >= xpCost(st.level)) {
		st.xp -= xpCost(st.level);
		st.level += 1;
		st.pending += 1;
		log(st, { t: "levelup", lvl: st.level });
	}
}

function applyEffects(st, card) {
	st.energy -= card.e;
	st.food -= card.costF || 0;
	st.wood -= card.costW || 0;
	st.materials -= card.costM || 0;
	let food = card.food || 0, wood = card.wood || 0;
	if (st.tools) {
		if (food > 0) food += C.TOOLS_BONUS;
		if (wood > 0) wood += C.TOOLS_BONUS;
	}
	st.food += food;
	st.water += card.water || 0;
	st.wood += wood;
	st.materials += card.materials || 0;
	st.hp = Math.max(0, Math.min(st.hp + (card.hp || 0), st.maxHp));
	st.hunger = Math.max(0, Math.min(st.hunger + (card.hunger || 0), C.MAX_START));
	st.warmth = Math.max(0, Math.min(st.warmth + (card.warmth || 0), C.MAX_START));
	st.energy = Math.max(0, Math.min(st.energy + (card.energy || 0), st.maxEnergy + 1));
	switch (card.special) {
		case "craft_tools": st.tools = true; log(st, { t: "tools" }); break;
		case "explore": rollExplore(st); break;
		case "double_explore": rollExplore(st); rollExplore(st); break;
		case "draw_two":
			st.hand.push(...st.drawPile.splice(0, 2));
			log(st, { t: "drawTwo" });
			break;
	}
}

function rollExplore(st) {
	const roll = randInt(st, 0, 3);
	if (roll === 0) st.food += 2;
	else if (roll === 1) st.wood += 2;
	else if (roll === 2) st.materials += 2;
	else { st.water += 1; st.food += 1; }
	log(st, { t: "explore", roll });
}

function checkDeath(st) {
	if (st.hp > 0) return false;
	st.over = true; st.won = false;
	log(st, { t: "lose" });
	return true;
}

function playCard(st, index) {
	const id = st.hand[index];
	const card = CARDS[id];
	st.hand.splice(index, 1);
	if (card.t === "b") {
		st.energy -= card.e + C.BUILD_ENERGY_DELTA;
		st.food -= card.costF || 0;
		st.wood -= card.costW || 0;
		st.materials -= card.costM || 0;
		const tile = st.board[st.pos];
		tile.blds.push({ id, hp: card.hp, maxHp: card.hp, ruin: false });
		const di = st.deck.indexOf(id);
		if (di >= 0) st.deck.splice(di, 1);
		log(st, { t: "build", c: id, n: tile.blds.length, max: BIOMES[tile.b].slots });
		grantXp(st, C.XP_BUILDING);
	} else {
		log(st, { t: "play", c: id });
		applyEffects(st, card);
		grantXp(st, C.XP_CARD);
	}
	checkDeath(st);
}

function playGather(st, id) {
	st.usedGathers.push(st.pos + ":" + id);
	log(st, { t: "gather", c: id });
	applyEffects(st, CARDS[id]);
	grantXp(st, C.XP_CARD);
	checkDeath(st);
}

function doMove(st, tile) {
	st.energy -= C.MOVE_COST;
	st.pos = tile;
	log(st, { t: "move", b: st.board[tile].b, cor: st.board[tile].cor });
}

function claimReward(st, kind) {
	if (kind === "energy") {
		st.pending -= 1;
		st.maxEnergy += 1;
		st.energy = Math.min(st.energy + 1, st.maxEnergy + 1);
		log(st, { t: "rewardEnergy", v: st.maxEnergy });
	} else if (kind === "health") {
		st.pending -= 1;
		st.maxHp += 1;
		st.hp = Math.min(st.hp + 3, st.maxHp);
		log(st, { t: "rewardHealth", v: st.maxHp });
	} else {
		const pool = (st.act === 2 ? REWARD_POOL_2 : REWARD_POOL_1).slice();
		shuffle(st, pool);
		st.cardChoices = pool.slice(0, 3);
	}
}

function pickCard(st, id) {
	st.deck.push(id);
	st.pending -= 1;
	st.cardChoices = null;
	log(st, { t: "rewardCard", c: id });
}

function doRepair(st, tileIdx, slot) {
	const b = st.board[tileIdx].blds[slot];
	st.energy -= 2;
	st.wood -= repairWoodCost(b);
	b.hp = b.maxHp;
	log(st, { t: "repair", c: b.id });
}

function doDismantle(st, tileIdx, slot) {
	const b = st.board[tileIdx].blds[slot];
	const card = CARDS[b.id];
	const wood = Math.floor((card.costW || 0) / 2);
	const mat = Math.floor((card.costM || 0) / 2);
	st.energy -= 1;
	st.wood += wood;
	st.materials += mat;
	st.board[tileIdx].blds.splice(slot, 1);
	// The blueprint survives: the card returns to the deck, so the
	// settlement can be rebuilt after the BUM (Act II loop).
	st.deck.push(b.id);
	log(st, { t: "dismantle", c: b.id, w: wood, m: mat });
}

// --- Night sequence ---
function night(st) {
	st.hand = [];
	// 1. Building passives (only intact buildings work).
	for (const tile of st.board) {
		for (const b of tile.blds) {
			const card = CARDS[b.id];
			if (!bldActive(b) || !card.night) continue;
			if (card.night.warmth) st.warmth = Math.min(st.warmth + card.night.warmth, C.MAX_START);
			if (card.night.water) st.water += card.night.water;
		}
	}
	// 2. Event card (or a monster, in Act II).
	resolveEvent(st);
	if (checkDeath(st)) return;
	// 3. Foreshadowing before the BUM.
	if (!st.bumHappened && st.day >= 8 && st.day < st.bumDay) {
		log(st, { t: "sign", i: (st.day - 8) % 4 });
	}
	// 4. Needs: hunger, thirst, warmth.
	st.hunger = Math.max(0, st.hunger - C.HUNGER_DECAY);
	while (st.food > 0 && st.hunger <= C.MAX_START - C.FOOD_VALUE) {
		st.food -= 1; st.hunger += C.FOOD_VALUE;
		log(st, { t: "eat", v: C.FOOD_VALUE });
	}
	if (st.hunger <= 0) { st.hp -= C.DEFICIENCY_DMG; log(st, { t: "starve" }); }
	st.thirst = Math.max(0, st.thirst - C.THIRST_DECAY);
	while (st.water > 0 && st.thirst <= C.MAX_START - C.WATER_VALUE) {
		st.water -= 1; st.thirst += C.WATER_VALUE;
		log(st, { t: "drink", v: C.WATER_VALUE });
	}
	if (st.thirst <= 0) { st.hp -= C.DEFICIENCY_DMG; log(st, { t: "dehydrate" }); }
	st.warmth = Math.max(0, st.warmth - C.WARMTH_DECAY);
	if (st.warmth <= 0) { st.hp -= C.DEFICIENCY_DMG; log(st, { t: "freeze" }); }
	st.hp = Math.max(0, st.hp);
	if (checkDeath(st)) return;
	// 5. BUM strikes at the end of its day.
	if (!st.bumHappened && st.day >= st.bumDay) doBum(st);
	// 6. Win / next day.
	if (st.day >= C.WIN_DAY) {
		st.over = true; st.won = true;
		log(st, { t: "win" });
		return;
	}
	st.day += 1;
	dawn(st);
}

function resolveEvent(st) {
	if (st.eventDraw.length === 0) {
		st.eventDraw = shuffle(st, st.eventDiscard);
		st.eventDiscard = [];
	}
	const id = st.eventDraw.pop();
	if (!id) return;
	const ev = EVENTS[id];
	if (ev.m) {
		// Monster night: hits the player and one random intact building.
		const dmgP = Math.max(0, ev.m.p - defSum(st, "defPlayer") - (anyActive(st, (c) => c.protection) ? C.NIGHT_PROTECTION : 0));
		st.hp = Math.max(0, st.hp - dmgP);
		const targets = [];
		st.board.forEach((tile, ti) => tile.blds.forEach((b, bi) => { if (!b.ruin) targets.push([ti, bi]); }));
		let hit = null;
		if (targets.length > 0 && ev.m.b > 0) {
			const [ti, bi] = targets[randInt(st, 0, targets.length - 1)];
			const b = st.board[ti].blds[bi];
			const dmgB = Math.max(0, ev.m.b - defSum(st, "defBld"));
			b.hp -= dmgB;
			reflag(b);
			hit = { c: b.id, dmg: dmgB, ruin: b.ruin };
		}
		log(st, { t: "monster", e: id, dp: dmgP, hit });
	} else {
		let hp = ev.hp || 0, warmth = ev.warmth || 0;
		let sheltered = false;
		if (ev.protected && anyActive(st, (c) => c.protection)) {
			const mh = Math.min(hp + C.NIGHT_PROTECTION, 0);
			const mw = Math.min(warmth + C.NIGHT_PROTECTION, 0);
			if (mh !== hp || mw !== warmth) sheltered = true;
			hp = Math.max(hp, mh);
			warmth = Math.max(warmth, mw);
		}
		st.hp = Math.max(0, Math.min(st.hp + hp, st.maxHp));
		st.warmth = Math.max(0, Math.min(st.warmth + warmth, C.MAX_START));
		st.food = Math.max(0, st.food + (ev.food || 0));
		st.water = Math.max(0, st.water + (ev.water || 0));
		st.materials = Math.max(0, st.materials + (ev.materials || 0));
		st.nextDayE += ev.nextE || 0;
		log(st, { t: "event", e: id, sheltered });
	}
	st.eventDiscard.push(id);
}

function doBum(st) {
	st.bumHappened = true;
	st.act = 2;
	log(st, { t: "bum" });
	for (const tile of st.board) {
		tile.cor = true;
		for (const b of tile.blds) {
			const pct = randInt(st, 20, 80);
			const loss = Math.round(b.maxHp * pct / 100);
			b.hp = Math.max(0, b.hp - loss);
			if (pct >= 50) b.ruin = true;
			reflag(b);
			log(st, { t: "bumDmg", c: b.id, pct, ruin: b.ruin });
		}
	}
	st.eventDraw.push(...BUM_EVENTS);
	shuffle(st, st.eventDraw);
}

// --- Contract: isGameOver / viewFor ---
export function isGameOver(state) {
	if (!state.over) return { over: false };
	if (state.won) return { over: true, winner: state.pid, won: true, days: state.day };
	return { over: true, draw: true, won: false, days: state.day };
}

export function viewFor(state, _playerId) {
	const v = JSON.parse(JSON.stringify(state));
	// Hidden information: deck order, event deck contents, the BUM timing.
	v.drawPile = state.drawPile.length;
	v.eventDraw = state.eventDraw.length;
	v.eventDiscard = state.eventDiscard.length;
	if (!state.bumHappened) v.bumDay = 0;
	return v;
}
