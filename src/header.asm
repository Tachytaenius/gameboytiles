SECTION "Header", ROM0[$0100]
	jp Init
	ds $150 - @, 0
