-- Dessine docs/plan-map.svg (vue du dessus) à partir de la map contenue dans DragonHeist.rbxlx
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local game = roblox.deserializePlace(fs.readFile("DragonHeist.rbxlx"))
local map = game:GetService("Workspace").Map

local SIZE, SCALE = 760, 1.05
local C = SIZE / 2
local function px(v) return C + v * SCALE end
local function hex(c) return "#" .. c:ToHex() end
local out = { string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">', SIZE, SIZE + 40, SIZE, SIZE + 40),
	string.format('<rect width="%d" height="%d" fill="#1b1f2a"/>', SIZE, SIZE + 40) }

local discs = {}
for _, p in map.NestZones:GetChildren() do table.insert(discs, p) end
table.insert(discs, map.Plaza)
table.sort(discs, function(a, b) return a.Size.Y > b.Size.Y end)
for _, d in discs do
	table.insert(out, string.format('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>', px(d.CFrame.Position.X), px(d.CFrame.Position.Z), d.Size.Y / 2 * SCALE, hex(d.Color)))
end
for _, d in map.Decor:GetChildren() do
	if d.Name == "Leaves" then
		table.insert(out, string.format('<circle cx="%.1f" cy="%.1f" r="5" fill="#2f6e2f"/>', px(d.CFrame.Position.X), px(d.CFrame.Position.Z)))
	elseif d.Name == "Rock" then
		table.insert(out, string.format('<circle cx="%.1f" cy="%.1f" r="4" fill="#2a2020"/>', px(d.CFrame.Position.X), px(d.CFrame.Position.Z)))
	end
end
local labels = { Foret = { "🌲 FORÊT · zone 1", "#d8ffd0" }, Volcan = { "🌋 VOLCAN · zone 2", "#ffc39a" }, Ciel = { "☁️ CIEL · zone 3", "#2b4a6b" } }
for _, z in map.NestZones:GetChildren() do
	local mid = (z:GetAttribute("InnerRadius") + z:GetAttribute("OuterRadius")) / 2
	local l = labels[z.Name]
	table.insert(out, string.format('<text x="%.1f" y="%.1f" font-size="15" text-anchor="middle" fill="%s" font-family="Arial" font-weight="bold">%s</text>', C, px(-mid) + 5, l[2], l[1]))
end
for _, base in map.Bases:GetChildren() do
	local cf = base.Floor.CFrame
	local _, yaw = cf:ToOrientation()
	local deg = -math.deg(yaw)
	local x, z = px(cf.Position.X), px(cf.Position.Z)
	local s = 44 * SCALE
	table.insert(out, string.format('<g transform="translate(%.1f %.1f) rotate(%.1f)"><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#786a5a" stroke="#d8cfc0" stroke-width="2" rx="3"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#50dc78" stroke-width="5"/></g>',
		x, z, deg, -s / 2, -s / 2, s, s, -s / 2 + 2, -s / 2, s / 2 - 2, -s / 2))
	table.insert(out, string.format('<text x="%.1f" y="%.1f" font-size="13" text-anchor="middle" fill="#fff" font-family="Arial" font-weight="bold">%s</text>', x, z + 5, (base.Name:gsub("Base_", "Base "))))
end
table.insert(out, string.format('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#dc3c3c" stroke="#ffd85a" stroke-width="3"/>', C, C, 18 * SCALE))
table.insert(out, string.format('<text x="%.1f" y="%.1f" font-size="12" text-anchor="middle" fill="#fff" font-family="Arial" font-weight="bold">🛒 SHOP</text>', C, C + 4))
table.insert(out, string.format('<text x="%.1f" y="%.1f" font-size="15" text-anchor="middle" fill="#ccc" font-family="Arial">Plus on s’éloigne du centre, plus les œufs sont rares · trait vert = porte</text>', C, SIZE + 26))
table.insert(out, "</svg>")
fs.writeFile("docs/plan-map.svg", table.concat(out, "\n"))
print("docs/plan-map.svg généré")
