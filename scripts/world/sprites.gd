class_name Sprites
extends RefCounted
## Koddan pixel art: satır dizisi + palet → 4x büyütülmüş, mipmap'li doku (Kenney tile'larıyla aynı piksel ölçeği).

const PALETTE := {
	"t": Color("8a3a8a"),
	"u": Color("c0392b"),
	"z": Color("222222"),
	"a": Color("c8c8c8"),
	"q": Color("d9a77a"),
	"k": Color("2b1d14"), "r": Color("b8432f"), "R": Color("e0704f"), "w": Color("6e4426"), "W": Color("9c6438"),
	"s": Color("7d7d88"), "S": Color("b4b4be"), "d": Color("3a3a46"), "b": Color("3c78c8"), "B": Color("86c0f2"),
	"y": Color("d9c27a"), "g": Color("4f8a3a"), "G": Color("7cc04f"), "f": Color("f1d6b0"), "h": Color("5a3a22"),
	"c": Color("1d70b8"), "C": Color("5fb0f0"), "o": Color("e08a2e"), "O": Color("ffc35a"), "x": Color("ffffff"),
	"m": Color("c8a070"), "n": Color("8a5a36"), "p": Color("b84a8a"), "e": Color("e8e4dc"), "l": Color("2e5a20"),
}

const WELL := [
	"....kkkkkkkk....",
	"...krRRRRRRrk...",
	"..krRRRRRRRRrk..",
	".krrrrrrrrrrrrk.",
	"..kw...yy...wk..",
	"..kW...y....Wk..",
	"..kw..kyk...wk..",
	"..kW..kwk...Wk..",
	".kkSkkkkkkkkSkk.",
	"kSsSsSsSsSsSsSsk",
	"ksdbbBbbbbBbbdsk",
	"kSdbBbbbbbbBbdSk",
	"ksSsSsSsSsSsSssk",
	"kSsSsSsSsSsSsSSk",
	".kkkkkkkkkkkkkk.",
	"................",
]

static var _cache := {}


static func get_tex(name: String, rows: Array) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var h := rows.size()
	var w: int = rows[0].length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var ch: String = rows[y][x]
			if PALETTE.has(ch):
				img.set_pixel(x, y, PALETTE[ch])
	img.resize(w * 4, h * 4, Image.INTERPOLATE_NEAREST)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[name] = t
	return t


static func well() -> Texture2D:
	return get_tex("well", WELL)


const PORTRAITS := {
	"hasan": [
		"................",
		"....wwwwwwww....",
		"...wWWWWWWWWw...",
		"..wwwwwwwwwwwww.",
		"...afffffffffa..",
		"...fkkfffffkkf..",
		"...ffkffffffkf..",
		"...fffffqqffff..",
		"...faaaaaaaaaf..",
		"....ffaffffaf...",
		".....qffffffq...",
		"....nnmmmmmmnn..",
		"...nnnmmmmmmnnn.",
		"..nnnnmmmmmmnnnn",
		"..nnnnmmmmmmnnnn",
		"..nnnnmmmmmmnnnn",
	],
	"cop": [
		"......hhhh......",
		".....hhhhhh.....",
		"....hhhhhhhh....",
		"...hhffffffhh...",
		"...hffffffffh...",
		"...hfkffffkfh...",
		"...hffffffffh...",
		"....ffffqfff....",
		"....fffrrfff....",
		".....ffffff.....",
		".....qffffq.....",
		"...cccxxxxccc...",
		"..ccccxxxxcccc..",
		"..cGGcxxxxcccc..",
		"..cGgcxxxxcccc..",
		"..ccccxxxxcccc..",
	],
	"fire": [
		"....uuuuuuuu....",
		"...uuuuuuuuuu...",
		"..uuuuOOOOuuuu..",
		"..uuuuuuuuuuuu..",
		".uuuuuuuuuuuuuu.",
		"...ffffffffff...",
		"...fkkffffkkf...",
		"...ffffffffff...",
		"...ffffqqffff...",
		"...ffhhhhhhff...",
		"....ffffffff....",
		"...dddOOOOddd...",
		"..ddddddddddddd.",
		"..dOOddddddOOdd.",
		"..dddddddddddd..",
		"..dddddddddddd..",
	],
	"teacher": [
		".....hhhhhh.....",
		"....hhhhhhhh....",
		"...hhhhhhhhhh...",
		"...hhffffffhh...",
		"..hhffffffffhh..",
		"..hhzzzzzzzzhh..",
		"..hhzkfzzfkzhh..",
		"..hhffffffffhh..",
		"..hhffffqfffhh..",
		"..hhfffrrfffhh..",
		"..hh.ffffff.hh..",
		"....ttteettt....",
		"...tttteettttt..",
		"..tttttettttttt.",
		"..ttttteettttt..",
		"..tttttettttttt.",
	],
	"farmer": [
		"....pppppppp....",
		"...pppppppppp...",
		"..ppxpppxppppp..",
		"..pppppppppppp..",
		"..ppffffffffpp..",
		"..ppfkkffkkfpp..",
		"..ppffffffffpp..",
		"..ppfffqqfffpp..",
		"..ppfffrrfffpp..",
		"...pppffffppp...",
		"....pppppppp....",
		"...ggggyyyggg...",
		"..gggggyygggggg.",
		"..ggGgggggggGgg.",
		"..ggggggggggggg.",
		"..ggggggggggggg.",
	],
	"press": [
		"....hhhhhhhh....",
		"...hhhhhhhhhh...",
		"...hhhhhhhhhhh..",
		"...hhffffffhh...",
		"...hffffffffh...",
		"...ffkffffkff...",
		"...ffffffffff...",
		"...fffffqffff...",
		"....ffffrrfff...",
		".....ffffff.....",
		".....qffffq.....",
		"...ssskkkksss...",
		"..sssssskzzzss..",
		"..sssssszzzzss..",
		"..sssssszCzzss..",
		"..sssssszzzzss..",
	],
}


static func portrait(role: String) -> Texture2D:
	return get_tex("p_" + role, PORTRAITS.get(role, PORTRAITS.hasan))


const ICONS := {
	"upgrade": [
		".....kk.....",
		"....kGGk....",
		"...kGGGGk...",
		"..kGGGGGGk..",
		".kGGGGGGGGk.",
		"kkkkGGGGkkkk",
		"...kGGGGk...",
		"...kGggGk...",
		"...kGggGk...",
		"...kGggGk...",
		"...kGGGGk...",
		"...kkkkkk...",
	],
	"move": [
		".....kk.....",
		"....kxxk....",
		"...kxxxxk...",
		"..kk.xx.kk..",
		".kxk.xx.kxk.",
		"kxxxxxxxxxxk",
		"kxxxxxxxxxxk",
		".kxk.xx.kxk.",
		"..kk.xx.kk..",
		"...kxxxxk...",
		"....kxxk....",
		".....kk.....",
	],
	"spray": [
		"....kkkk....",
		"....kddk....",
		"..kkkddkk.G.",
		"..kGGGGGk.GG",
		"..kGgGgGk..G",
		"..kGGGGGkG..",
		"..kGgGgGk...",
		"..kGGGGGk...",
		"..kGgGgGk...",
		"..kGGGGGk...",
		"..kGGGGGk...",
		"..kkkkkkk...",
	],
	"drip": [
		".....kk.....",
		".....kBk....",
		"....kBBk....",
		"....kBBBk...",
		"...kBBBBk...",
		"...kBBBBBk..",
		"..kBxBBBBk..",
		"..kBxBBBBBk.",
		"..kBBBBBBBk.",
		"..kbBBBBBbk.",
		"...kbbbbbk..",
		"....kkkkk...",
	],
	"repair": [
		"..kkkkkk....",
		".kSSSSSSk...",
		".kSSSSSSkk..",
		"..kkkSSSSSk.",
		"....kSkkkk..",
		"....kWk.....",
		"....kWk.....",
		"....kWk.....",
		"....kWk.....",
		"....kWk.....",
		"....kWk.....",
		"....kkk.....",
	],
	"close": [
		"kk........kk",
		"kxk......kxk",
		".kxk....kxk.",
		"..kxk..kxk..",
		"...kxkkxk...",
		"....kxxk....",
		"....kxxk....",
		"...kxkkxk...",
		"..kxk..kxk..",
		".kxk....kxk.",
		"kxk......kxk",
		"kk........kk",
	],
}


static func icon(name: String) -> Texture2D:
	return get_tex("i_" + name, ICONS[name])
