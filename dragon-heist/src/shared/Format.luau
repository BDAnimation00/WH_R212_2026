-- Mise en forme des nombres et des durées pour l'affichage.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.Number(n)
	n = math.floor(n)
	local value = n
	local index = 1
	while math.abs(value) >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	if index == 1 then
		return tostring(n)
	end
	return string.format("%.1f%s", value, SUFFIXES[index])
end

function Format.Time(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("%dm %02ds", minutes, secs)
	end
	return string.format("%ds", secs)
end

return Format
