--- @since 25.4.8

local M = {}

function M:peek(job)
	if not job.file then
		return
	end

	local child, err = Command("bat")
		:arg({
			"--style",
			"plain",
			"--color",
			"always",
			"--theme",
			"Catppuccin Mocha",
			"--map-syntax",
			"*.surql:SQL",
			"--map-syntax",
			"*.surrealql:SQL",
			"--map-syntax",
			"*.hurl:HTTP Request and Response",
			tostring(job.file.url),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return ya.preview_widget(job, ui.Text.parse("Error executing bat: " .. (err or "")):area(job.area):wrap(ui.Wrap.YES))
	end

	local limit = job.area.h
	local i, outs = 0, {}
	repeat
		local next, event = child:read_line()
		if event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			outs[#outs + 1] = next
		end
	until i >= job.skip + limit

	child:start_kill()

	if job.skip > 0 and #outs == 0 then
		ya.manager_emit("peek", { math.max(0, job.skip - limit), only_if = job.file.url, upper_bound = false })
		return
	end

	local s = table.concat(outs, ""):gsub("\t", "  ")
	ya.preview_widget(job, ui.Text.parse(s):area(job.area))
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.manager_emit("peek", {
			math.max(0, cx.active.preview.skip + job.units),
			only_if = job.file.url,
		})
	end
end

return M
