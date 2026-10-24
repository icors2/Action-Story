class_name ExpDistributor
## Splits mob EXP among damagers. Remainder goes to the top damager so the total is conserved.
## Party share is a Phase 12 hook — callers pass the raw ledger.


static func split(total: int, ledger: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if total <= 0 or ledger.is_empty():
		return out
	var sum: int = 0
	for v: Variant in ledger.values():
		sum += maxi(int(v), 0)
	if sum <= 0:
		return out
	var assigned: int = 0
	var best_eid: int = 0
	var best_dmg: int = -1
	for key: Variant in ledger.keys():
		var eid: int = int(key)
		var dmg: int = maxi(int(ledger[key]), 0)
		var share: int = int(floor(float(total) * float(dmg) / float(sum)))
		out[eid] = share
		assigned += share
		if dmg > best_dmg or (dmg == best_dmg and eid < best_eid):
			best_dmg = dmg
			best_eid = eid
	var leftover: int = total - assigned
	if leftover != 0 and out.has(best_eid):
		out[best_eid] = int(out[best_eid]) + leftover
	return out
