local col = 1
local row = 1
for i = 1, #main.t_selGrid do
	if i > motif.select_info.columns * row then
		row = row + 1
		col = 1
	end
	if main.t_selGrid[i].slot ~= 1 then
		main.t_selGrid[i].slot = 1
		start.t_grid[row][col].char = start.f_selGrid(i).char
		start.t_grid[row][col].char_ref = start.f_selGrid(i).char_ref
		start.t_grid[row][col].hidden = start.f_selGrid(i).hidden
		start.t_grid[row][col].skip = start.f_selGrid(i).skip
	end
	col = col + 1
end
selScreenEnd = false

local t_txt_name = {}
for i = 1, 2 do
	table.insert(t_txt_name, main.f_createTextImg(motif.select_info, 'p' .. i .. '_name'))
end

local stageListNo = 0
local txt_selStage = main.f_createTextImg(motif.select_info, 'stage_active')


function start.f_selectScreen()
	start.f_selectReset(false)
	t_recordText = start.f_getRecordText()
	if (not main.selectMenu[1] and not main.selectMenu[2]) or selScreenEnd then
		return true
	end
	main.f_bgReset(motif.selectbgdef.bg)
	main.f_fadeReset('fadein', motif.select_info)
	main.f_playBGM(false, motif.music.select_bgm, motif.music.select_bgm_loop, motif.music.select_bgm_volume, motif.music.select_bgm_loopstart, motif.music.select_bgm_loopend)
	start.f_resetTempData(motif.select_info, '_face')
	local stageActiveCount = 0
	local stageActiveType = 'stage_active'
	timerSelect = 0
	local escFlag = false
	local t_teamMenu = {{}, {}}
	local blinkCount = 0
	local counter = 0 - motif.select_info.fadein_time
	hoverCharacters = {}
	for side = 1, 2 do
		hoverCharacters[side] = {}
		for i = 1, motif.select_info.rows do
			hoverCharacters[side][i] = 1
		end
	end
	numberOfRows = 0
	charsPerRow = {}
	charsInRow = {}
	charsRows = {}
	for i = 1, motif.select_info.rows do
		charsInRow[i] = {}
		local rowChars = 0
		for v = 1, motif.select_info.columns do
			local t = start.t_grid[i][v]
			if t.char ~= nil and t.hidden ~= nil and t.hidden ~= 2 then
				rowChars = rowChars + 1
				table.insert(charsInRow[i], v)
			end
			charsPerRow[i] = rowChars
		end
		if rowChars > 0 then
			numberOfRows = numberOfRows + 1
			table.insert(charsRows, i)
		end
	end
	directions = {}
	directions[1] = "up"
	directions[2] = "down"
	directions[3] = "left"
	directions[4] = "right"
	spacing = {}
	--UP
	spacing[1] = {0, -1 * motif.select_info['cell_size'][2]}
	--Down
	spacing[2] = {0, motif.select_info['cell_size'][2]}
	--Left
	spacing[3] = {-1 * motif.select_info['cell_size'][1], 0}
	--Right
	spacing[4] = {motif.select_info['cell_size'][1], 0}
	slideTimeHor = {}
	slideTimeVer = {}
	for side = 1, 2 do
		slideTimeHor[side] = 0
		slideTimeVer[side] = 0
		for k = 1, 4 do
			if motif.select_info['p' .. side .. '_fp_' .. directions[k] .. '_spacing'] ~= nil then
				spacing[k] = motif.select_info['p' .. side .. '_fp_' .. directions[k] .. '_spacing']
			end	
		end
	end
	-- generate team mode items table
	for side = 1, 2 do
		-- start with all default teammode entires
		local str = 'teammenu_itemname_' .. gamemode() .. '_'
		local t = {
			{data = text:create({}), itemname = 'single', displayname = (motif.select_info[str .. 'single'] or motif.select_info.teammenu_itemname_single), mode = 0, insert = true},
			{data = text:create({}), itemname = 'simul', displayname = (motif.select_info[str .. 'simul'] or motif.select_info.teammenu_itemname_simul), mode = 1, insert = true},
			{data = text:create({}), itemname = 'turns', displayname = (motif.select_info[str .. 'turns'] or motif.select_info.teammenu_itemname_turns), mode = 2, insert = true},
			{data = text:create({}), itemname = 'tag', displayname = (motif.select_info[str .. 'tag'] or motif.select_info.teammenu_itemname_tag), mode = 3, insert = true},
			{data = text:create({}), itemname = 'ratio', displayname = (motif.select_info[str .. 'ratio'] or motif.select_info.teammenu_itemname_ratio), mode = 2, insert = true},
		}
		local activeNum = #t
		-- keep team mode allowed by game mode declaration, but only if it hasn't been disabled by screenpack parameter
		for i = #t, 1, -1 do
			local itemname = t[i].itemname
			if not main.teamMenu[side][itemname]
				or (motif.select_info[str .. itemname] ~= nil and motif.select_info[str .. itemname] == '')
				or (motif.select_info[str .. itemname] == nil and motif.select_info['teammenu_itemname_' .. itemname] == '') then
				t[i].insert = false
				activeNum = activeNum - 1 --track disabled items
			end
		end
		-- first we insert all entries existing in screenpack file in correct order
		for _, name in ipairs(main.f_tableExists(main.t_sort.select_info).teammenu) do
			for k, v in ipairs(t) do
				if v.insert and (name == v.itemname or name == gamemode() .. '_' .. v.itemname) then
					table.insert(t_teamMenu[side], v)
					v.insert = false
					break
				end
			end
		end
		-- then we insert remaining default entries
		for k, v in ipairs(t) do
			if v.insert or (activeNum == 0 and main.teamMenu[side][v.itemname]) then
				table.insert(t_teamMenu[side], v)
				-- if all items are disabled by screenpack add only first default item
				if activeNum == 0 then
					break
				end
			end
		end
		start.c[side].trueX = 1
		start.c[side].trueY = 1
	end
	slideHor = 0
	slideVer = 0
	while not selScreenEnd do
		counter = counter + 1
		--credits
		if main.credits ~= -1 and getKey(motif.attract_mode.credits_key) then
			sndPlay(motif.files.snd_data, motif.attract_mode.credits_snd[1], motif.attract_mode.credits_snd[2])
			main.credits = main.credits + 1
			resetKey()
		end
		--draw clearcolor
		clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(motif.selectbgdef.bg, 0)
		--draw title
		main.txt_mainSelect:draw()
		--draw portraits
		for side = 1, 2 do
			if #start.p[side].t_selTemp > 0 then
				start.f_drawPortraits(start.p[side].t_selTemp, side, motif.select_info, '_face', true)
			end
		end
		--draw cell art
		--[[for row = 1, motif.select_info.rows do
			for col = 1, motif.select_info.columns do
				local t = start.t_grid[row][col]
				if t.skip ~= 1 then
					--draw cell background
					if (t.char ~= nil and (t.hidden == 0 or t.hidden == 3)) or motif.select_info.showemptyboxes == 1 then
						main.f_animPosDraw(
							motif.select_info.cell_bg_data,
							motif.select_info.pos[1] + t.x,
							motif.select_info.pos[2] + t.y,
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
						)
					end
					--draw random cell
					if t.char == 'randomselect' or t.hidden == 3 then
						main.f_animPosDraw(
							motif.select_info.cell_random_data,
							motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
							motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_random_facing)
						)
					--draw face cell
					elseif t.char ~= nil and t.hidden == 0 then
						main.f_animPosDraw(
							start.f_getCharData(t.char_ref).cell_data,
							motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
							motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.portrait_facing)
						)
					end
				end
			end
		end]]--
		for side = 1, 2 do
			if slideTimeHor[side] > 0 then
				slideTimeHor[side] = slideTimeHor[side] - 1
			end
			if slideTimeVer[side] > 0 then
				slideTimeVer[side] = slideTimeVer[side] - 1
			end
			if ((start.p[side].selEnd == false) and (start.p[side].teamEnd == true)) and (((start.p[1].selEnd and main.cpuSide[2]) or side == 1) or main.cpuSide[2] == false) then
				local t_cmd = {}
				if main.coop then
					--[[for i = 1, config.Players do
						if not gamemode('versuscoop') or (i - 1) % 2 + 1 == 1 then
							table.insert(t_cmd, i)
						end
					end]]--
					selectedCounter = 1
					for c, v in pairs(start.p[side].t_selected) do
						selectedCounter = selectedCounter + 1
					end
					if main.cpuSide[2] == false then
						if side == 1 then
							if selectedCounter == 1 then
								selectedCounter = 1
							elseif selectedCounter == 2 then
								selectedCounter = 3
							elseif selectedCounter == 3 then
								selectedCounter = 5
							elseif selectedCounter == 4 then
								selectedCounter = 7
							end
						elseif side == 2 then
							if selectedCounter == 1 then
								selectedCounter = 2
							elseif selectedCounter == 2 then
								selectedCounter = 4
							elseif selectedCounter == 3 then
								selectedCounter = 6
							elseif selectedCounter == 4 then
								selectedCounter = 8
							end
						end
					end
					t_cmd = {selectedCounter}
					if selectedCounter > 1 then
						start.c[selectedCounter].selY = start.c[side].selY
						start.c[selectedCounter].selX = start.c[side].selX
					end
				else
					selectedCounter = 1
					t_cmd = {side}
				end
				moved = false
				if main.f_input(t_cmd, main.f_extractKeys('$U')) then
					start.c[side].trueY = ((start.c[side].trueY - 2) % numberOfRows) + 1
					start.c[side].selY = charsRows[start.c[side].trueY] - 1	
					start.c[side].trueX = hoverCharacters[side][start.c[side].selY + 1]
					start.c[side].selX = charsInRow[start.c[side].selY + 1][hoverCharacters[side][start.c[side].selY + 1]] - 1
					slideVer = -1
					slideTimeVer[side] = motif.select_info['p' .. side .. '_fp_slide_time'] or 50
					moved = true
				end
				if main.f_input(t_cmd, main.f_extractKeys('$D')) then
					start.c[side].trueY = (start.c[side].trueY % numberOfRows) + 1
					start.c[side].selY = charsRows[start.c[side].trueY] - 1	
					start.c[side].trueX = hoverCharacters[side][start.c[side].selY + 1]
					start.c[side].selX = charsInRow[start.c[side].selY + 1][hoverCharacters[side][start.c[side].selY + 1]] - 1
					slideVer = 1
					slideTimeVer[side] = motif.select_info['p' .. side .. '_fp_slide_time'] or 50
					moved = true
				end
				
				if main.f_input(t_cmd, main.f_extractKeys('$F')) then
					start.c[side].trueX = ((start.c[side].trueX) % charsPerRow[start.c[side].selY + 1]) + 1
					start.c[side].selX = charsInRow[start.c[side].selY + 1][start.c[side].trueX] - 1
					hoverCharacters[side][start.c[side].selY + 1] = start.c[side].trueX
					slideHor = 1
					slideTimeHor[side] = motif.select_info['p' .. side .. '_fp_slide_time'] or 50
					moved = true
				end		
				if main.f_input(t_cmd, main.f_extractKeys('$B')) then
					start.c[side].trueX = ((start.c[side].trueX - 2) % charsPerRow[start.c[side].selY + 1]) + 1
					start.c[side].selX = charsInRow[start.c[side].selY + 1][start.c[side].trueX] - 1
					hoverCharacters[side][start.c[side].selY + 1] = start.c[side].trueX		
					slideHor = -1
					slideTimeHor[side] = motif.select_info['p' .. side .. '_fp_slide_time'] or 50
					moved = true
				end
				if moved == true then
					sndPlay(motif.files.snd_data, motif.select_info['p' .. side .. '_cursor_move_snd'][1], motif.select_info['p' .. side .. '_cursor_move_snd'][2])
				end
			end
			if start.p[side].teamEnd == true and (((start.p[side].selEnd == false) and (start.p[side].teamEnd == true)) or (motif.select_info.hideoncompleteselection == 0)) and (((start.p[1].selEnd and main.cpuSide[2]) or side == 1) or main.cpuSide[2] == false) then
				--vertical showcase
				for n = 1, motif.select_info['p' .. side .. '_fp_up'] or 0 do
					main.f_animPosDraw(
						motif.select_info.cell_bg_data,
						motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n),
						motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
						(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
					)
					--print(charsInRow[charsRows[((start.c[side].trueY - 1 - 1) % numberOfRows) + 1]][hoverCharacters[side][charsRows[((start.c[side].trueY - 1 - 1) % numberOfRows) + 1]]])
					--local t = start.t_grid[((start.c[side].selY - n) % numberOfRows) + 1][hoverCharacters[side][((start.c[side].selY - n) % motif.select_info.rows) + 1]]
					local t = start.t_grid[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]][charsInRow[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]][hoverCharacters[side][charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]]]]
					animSetScale(
						start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
						(motif.select_info.portrait_scale[1] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
						(motif.select_info.portrait_scale[2] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
						false
					)
					main.f_animPosDraw(
						start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
						motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n),
						motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
						(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
					)
					for h = 1, motif.select_info['p' .. side .. '_fp_up_' .. n .. '_right'] or 0 do
						if charsPerRow[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]] > h then
							main.f_animPosDraw(
								motif.select_info.cell_bg_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[4][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[4][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
							precalc = charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]
							local t = start.t_grid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] + h - 1) % charsPerRow[precalc]) + 1]]
							main.f_animPosDraw(
								start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[4][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[4][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
						end
					end
					for h = 1, motif.select_info['p' .. side .. '_fp_up_' .. n .. '_left'] or 0 do
						if charsPerRow[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]] > h then
							main.f_animPosDraw(
								motif.select_info.cell_bg_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[3][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[3][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
							precalc = charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]
							local t = start.t_grid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] - h - 1) % charsPerRow[precalc]) + 1]]
							main.f_animPosDraw(
								start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[3][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[3][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
						end
					end
				end
				for n = 1, motif.select_info['p' .. side .. '_fp_down'] or 0 do
					main.f_animPosDraw(
						motif.select_info.cell_bg_data,
						motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n),
						motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
						(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
					)
					local t = start.t_grid[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]][charsInRow[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]][hoverCharacters[side][charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]]]]
					animSetScale(
						start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
						(motif.select_info.portrait_scale[1] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
						(motif.select_info.portrait_scale[2] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
						false
					)
					main.f_animPosDraw(
						start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
						motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n),
						motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
						(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
					)
					for h = 1, motif.select_info['p' .. side .. '_fp_down_' .. n .. '_right'] or 0 do
						--if charsPerRow[((start.c[side].selY + n) % numberOfRows) + 1] > h then
						if charsPerRow[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]] > h then
							main.f_animPosDraw(
								motif.select_info.cell_bg_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[4][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[4][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
							--precalc = charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]
							--precalc = ((hoverCharacters[side][((start.c[side].selY + n) % numberOfRows) + 1]) + h) % charsPerRow[((start.c[side].selY + n) % numberOfRows) + 1]
							--if precalc == 0 then
							--	precalc = charsPerRow[((start.c[side].selY + n) % numberOfRows) + 1]
							--end
							precalc = charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]
							local t = start.t_grid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] + h - 1) % charsPerRow[precalc]) + 1]]
							
							--local t = start.t_grid[((start.c[side].selY + n) % numberOfRows) + 1][charsInRow[precalc][((hoverCharacters[side][precalc] + h - 1) % charsPerRow[precalc]) + 1]]
							main.f_animPosDraw(
								start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[4][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[4][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
						end
					end
					for h = 1, motif.select_info['p' .. side .. '_fp_down_' .. n .. '_left'] or 0 do
						if charsPerRow[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]] > h then
						--if charsPerRow[((start.c[side].selY + n) % numberOfRows) + 1] > h then
							main.f_animPosDraw(
								motif.select_info.cell_bg_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[3][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[3][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
							--precalc = ((hoverCharacters[side][((start.c[side].selY + n) % numberOfRows) + 1]) - h) % charsPerRow[((start.c[side].selY + n) % numberOfRows) + 1]
							--if precalc == 0 then
							--	precalc = charsPerRow[((start.c[side].selY + n) % numberOfRows) + 1]
							--end
							--local t = start.t_grid[((start.c[side].selY + n) % numberOfRows) + 1][precalc]
							precalc = charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]
							local t = start.t_grid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] - h - 1) % charsPerRow[precalc]) + 1]]
							main.f_animPosDraw(
								start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
								motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[3][1] * h),
								motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[3][2] * h),
								(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
							)
						end
					end
				end
				--horizontal displays
				for n = 1, motif.select_info['p' .. side .. '_fp_main_right'] or 0 do
					if charsPerRow[start.c[side].selY + 1] > n then
						main.f_animPosDraw(
							motif.select_info.cell_bg_data,
							motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[4][1])  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
							motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[4][2]),
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
						)
						local t = start.t_grid[start.c[side].selY + 1][charsInRow[start.c[side].selY + 1][((start.c[side].trueX + n - 1) % charsPerRow[start.c[side].selY + 1]) + 1]]
						animSetScale(
							start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
							(motif.select_info.portrait_scale[1] * ((start.f_getCharData(t.char_ref).portrait_scale or 1) or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
							(motif.select_info.portrait_scale[2] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
							false
						)
						main.f_animPosDraw(
							start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
							motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[4][1])  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
							motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[4][2]),
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
						)		
					end
				end
				for n = 1, motif.select_info['p' .. side .. '_fp_main_left'] or 0 do
					if charsPerRow[start.c[side].selY + 1] > n then
						main.f_animPosDraw(
							motif.select_info.cell_bg_data,
							motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[3][1])   + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
							motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[3][2]),
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
						)
						local t = start.t_grid[start.c[side].selY + 1][charsInRow[start.c[side].selY + 1][((start.c[side].trueX - n - 1) % charsPerRow[start.c[side].selY + 1]) + 1]]
						animSetScale(
							start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
							(motif.select_info.portrait_scale[1] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
							(motif.select_info.portrait_scale[2] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * 1,
							false
						)
						main.f_animPosDraw(
							start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
							motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[3][1]) + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
							motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[3][2]),
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
						)		
					end
				end
				
				--main display
				scaleToUse = {}
				if motif.select_info['p' .. side .. '_fp_main_scale'] ~= nil then
					scaleToUse[1] = motif.select_info['p' .. side .. '_fp_main_scale'][1]
					scaleToUse[2] = motif.select_info['p' .. side .. '_fp_main_scale'][2]
				else
					scaleToUse[1] = 1
					scaleToUse[2] = 1
				end
				animSetScale(
					motif.select_info.cell_bg_data,
					scaleToUse[1],
					scaleToUse[2],
					false
				)
				main.f_animPosDraw(
					motif.select_info.cell_bg_data,
					motif.select_info['p' .. side .. '_fp_main_pos'][1] - (((motif.select_info['cell_size'][1] * scaleToUse[1]) - motif.select_info['cell_size'][1]) / 2) + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
					motif.select_info['p' .. side .. '_fp_main_pos'][2] - (((motif.select_info['cell_size'][2] * scaleToUse[2]) - motif.select_info['cell_size'][2]) / 2) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
					(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
				)
				animSetScale(
					motif.select_info.cell_bg_data,
					1,
					1,
					false
				)
				local t = start.t_grid[start.c[side].selY + 1][start.c[side].selX + 1]
				animSetScale(
					start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
					(motif.select_info.portrait_scale[1] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * scaleToUse[1],
					(motif.select_info.portrait_scale[2] * (start.f_getCharData(t.char_ref).portrait_scale or 1) / (main.SP_Viewport43[3] / main.SP_Localcoord[1])) * scaleToUse[2],
					false
				)
				main.f_animPosDraw(
					start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
					motif.select_info['p' .. side .. '_fp_main_pos'][1] - (((motif.select_info['cell_size'][1] * scaleToUse[1]) - motif.select_info['cell_size'][1]) / 2)  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
					motif.select_info['p' .. side .. '_fp_main_pos'][2] - (((motif.select_info['cell_size'][2] * scaleToUse[2]) - motif.select_info['cell_size'][2]) / 2) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
					(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
				)	
			end
		end
		prefix = 'p1_cursor_active'
		-- create spr/anim data, if not existing yet
		if motif.select_info['p1_cursor_active' .. '_data'] == nil then
			-- if cell based variants are not defined we're defaulting to standard pX parameters
			for _, v in ipairs({'_anim', '_spr', '_offset', '_scale', '_facing'}) do
				if motif.select_info[prefix .. v] == nil then
					motif.select_info[prefix .. v] = start.f_getCursorData(pn, param .. v)
				end
			end
			motif.f_loadSprData(motif.select_info, {s = prefix .. '_'})
		end
		-- draw
		--[[main.f_animPosDraw(
			motif.select_info[prefix .. '_data'],
			motif.select_info['p' .. side .. '_fp_main_pos'][1],
			motif.select_info['p' .. side .. '_fp_main_pos'][2],
			(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
		)]]--
		--draw done cursors
		for side = 1, 2 do
			for _, v in pairs(start.p[side].t_selected) do
				if v.cursor ~= nil then
					--get cell coordinates
					local x = v.cursor[1]
					local y = v.cursor[2]
					local t = start.t_grid[y + 1][x + 1]
					--retrieve proper cell coordinates in case of random selection
					--TODO: doesn't work with slot feature
					--if (t.char == 'randomselect' or t.hidden == 3) --[[and not config.TeamDuplicates]] then
					--	x = start.f_getCharData(v.ref).col - 1
					--	y = start.f_getCharData(v.ref).row - 1
					--	t = start.t_grid[y + 1][x + 1]
					--end
					--render only if cell is not hidden
					if t.hidden ~= 1 and t.hidden ~= 2 then
						start.f_drawCursor(v.pn, x, y, '_cursor_done')
					end
				end
			end
		end
		--team and select menu
		if blinkCount < motif.select_info.p2_cursor_switchtime then
			blinkCount = blinkCount + 1
		else
			blinkCount = 0
		end
		for side = 1, 2 do
			if not start.p[side].teamEnd then
				start.f_teamMenu(side, t_teamMenu[side])
			elseif not start.p[side].selEnd then
				--for each player with active controls
				for k, v in ipairs(start.p[side].t_selCmd) do
					local member = main.f_tableLength(start.p[side].t_selected) + k
					if main.coop and (side == 1 or gamemode('versuscoop')) then
						member = k
					end
					--member selection
					v.selectState = start.f_selectMenu(side, v.cmd, v.player, member, v.selectState)
					--draw active cursor
					--[[if side == 2 and motif.select_info.p2_cursor_blink == 1 then
						local sameCell = false
						for _, v2 in ipairs(start.p[1].t_selCmd) do							
							if start.c[v.player].cell == start.c[v2.player].cell and v.selectState == 0 and v2.selectState == 0 then
								if blinkCount == 0 then
									start.c[v.player].blink = not start.c[v.player].blink
								end
								sameCell = true
								break
							end
						end
						if not sameCell then
							start.c[v.player].blink = false
						end
					end
					if v.selectState < 4 and start.f_selGrid(start.c[v.player].cell + 1).hidden ~= 1 and not start.c[v.player].blink then
						start.f_drawCursor(v.player, start.c[v.player].selX, start.c[v.player].selY, '_cursor_active')
					end
					]]--
				end
			end
			--delayed screen transition for the duration of face_done_anim or selection sound
			if start.p[side].screenDelay > 0 then
				if main.f_input(main.t_players, {'pal', 's'}) then
					start.p[side].screenDelay = 0
				else
					start.p[side].screenDelay = start.p[side].screenDelay - 1
				end
			end
		end
		--exit select screen
		if not escFlag and (esc() or main.f_input(main.t_players, {'m'})) then
			main.f_fadeReset('fadeout', motif.select_info)
			escFlag = true
		end
		--draw names
		for side = 1, 2 do
			if #start.p[side].t_selTemp > 0 then
				for i = 1, #start.p[side].t_selTemp do
					if i <= motif.select_info['p' .. side .. '_name_num'] or main.coop then
						local name = ''
						if motif.select_info['p' .. side .. '_name_num'] == 1 then
							name = start.f_getName(start.p[side].t_selTemp[#start.p[side].t_selTemp].ref, side)
						else
							name = start.f_getName(start.p[side].t_selTemp[i].ref, side)
						end
						t_txt_name[side]:update({
							font =   motif.select_info['p' .. side .. '_name_font'][1],
							bank =   motif.select_info['p' .. side .. '_name_font'][2],
							align =  motif.select_info['p' .. side .. '_name_font'][3],
							text =   name,
							x =      motif.select_info['p' .. side .. '_name_offset'][1] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][1],
							y =      motif.select_info['p' .. side .. '_name_offset'][2] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][2],
							scaleX = motif.select_info['p' .. side .. '_name_scale'][1],
							scaleY = motif.select_info['p' .. side .. '_name_scale'][2],
							r =      motif.select_info['p' .. side .. '_name_font'][4],
							g =      motif.select_info['p' .. side .. '_name_font'][5],
							b =      motif.select_info['p' .. side .. '_name_font'][6],
							height = motif.select_info['p' .. side .. '_name_font'][7],
						})
						t_txt_name[side]:draw()
					end
				end
			end
		end
		--team and character selection complete
		if start.p[1].selEnd and start.p[2].selEnd and start.p[1].teamEnd and start.p[2].teamEnd then
			restoreCursor = true
			if main.stageMenu and not stageEnd then --Stage select
				start.f_stageMenu()
			elseif start.p[1].screenDelay <= 0 and start.p[2].screenDelay <= 0 and main.fadeType == 'fadein' then
				main.f_fadeReset('fadeout', motif.select_info)
			end
			--draw stage portrait
			if main.stageMenu then
				--draw stage portrait background
				main.f_animPosDraw(motif.select_info.stage_portrait_bg_data)
				--draw stage portrait (random)
				if stageListNo == 0 then
					main.f_animPosDraw(motif.select_info.stage_portrait_random_data)
				--draw stage portrait loaded from stage SFF
				else
					main.f_animPosDraw(
						main.t_selStages[main.t_selectableStages[stageListNo]].anim_data,
						motif.select_info.stage_pos[1] + motif.select_info.stage_portrait_offset[1],
						motif.select_info.stage_pos[2] + motif.select_info.stage_portrait_offset[2]
					)
				end
				if not stageEnd then
					if main.f_input(main.t_players, {'pal', 's'}) or timerSelect == -1 then
						sndPlay(motif.files.snd_data, motif.select_info.stage_done_snd[1], motif.select_info.stage_done_snd[2])
						stageActiveType = 'stage_done'
						stageEnd = true
					elseif stageActiveCount < motif.select_info.stage_active_switchtime then --delay change
						stageActiveCount = stageActiveCount + 1
					else
						if stageActiveType == 'stage_active' then
							stageActiveType = 'stage_active2'
						else
							stageActiveType = 'stage_active'
						end
						stageActiveCount = 0
					end
				end
				--draw stage name
				local t_txt = {}
				if stageListNo == 0 then
					t_txt[1] = motif.select_info.stage_random_text
				else
					t = motif.select_info.stage_text:gsub('%%i', tostring(stageListNo))
					t = t:gsub('\n', '\\n')
					t = t:gsub('%%s', main.t_selStages[main.t_selectableStages[stageListNo]].name)
					for i, c in ipairs(main.f_strsplit('\\n', t)) do --split string using "\n" delimiter
						t_txt[i] = c
					end
				end
				for i = 1, #t_txt do
					txt_selStage:update({
						font =   motif.select_info[stageActiveType .. '_font'][1],
						bank =   motif.select_info[stageActiveType .. '_font'][2],
						align =  motif.select_info[stageActiveType .. '_font'][3],
						text =   t_txt[i],
						x =      motif.select_info.stage_pos[1] + motif.select_info[stageActiveType .. '_offset'][1],
						y =      motif.select_info.stage_pos[2] + motif.select_info[stageActiveType .. '_offset'][2] + main.f_ySpacing(motif.select_info, stageActiveType) * (i - 1),
						scaleX = motif.select_info[stageActiveType .. '_scale'][1],
						scaleY = motif.select_info[stageActiveType .. '_scale'][2],
						r =      motif.select_info[stageActiveType .. '_font'][4],
						g =      motif.select_info[stageActiveType .. '_font'][5],
						b =      motif.select_info[stageActiveType .. '_font'][6],
						height = motif.select_info[stageActiveType .. '_font'][7],
					})
					txt_selStage:draw()
				end
			end
		end
		--draw timer
		if motif.select_info.timer_count ~= -1 and (not start.p[1].teamEnd or not start.p[2].teamEnd or not start.p[1].selEnd or not start.p[2].selEnd or (main.stageMenu and not stageEnd)) and counter >= 0 then
			timerSelect = main.f_drawTimer(timerSelect, motif.select_info, 'timer_', txt_timerSelect)
		end
		--draw record text
		for i = 1, #t_recordText do
			txt_recordSelect:update({
				text = t_recordText[i],
				y = motif.select_info.record_offset[2] + main.f_ySpacing(motif.select_info, 'record') * (i - 1),
			})
			txt_recordSelect:draw()
		end
		-- hook
		hook.run("start.f_selectScreen")
		--draw layerno = 1 backgrounds
		bgDraw(motif.selectbgdef.bg, 1)
		--draw fadein / fadeout
		main.f_fadeAnim(motif.select_info)
		--frame transition
		if not main.f_frameChange() then
			selScreenEnd = true
			break --skip last frame rendering
		end
		main.f_refresh()
	end
	return not escFlag
end

--;===========================================================
--; STAGE MENU
--;===========================================================
function start.f_stageMenu()
	local n = stageListNo
	if timerSelect == -1 then
		stageEnd = true
		return
	elseif main.f_input(main.t_players, {'$B'}) then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		stageListNo = stageListNo - 1
		if stageListNo < 0 then stageListNo = #main.t_selectableStages end
	elseif main.f_input(main.t_players, {'$F'}) then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		stageListNo = stageListNo + 1
		if stageListNo > #main.t_selectableStages then stageListNo = 0 end
	elseif main.f_input(main.t_players, {'$U'}) then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		for i = 1, 10 do
			stageListNo = stageListNo - 1
			if stageListNo < 0 then stageListNo = #main.t_selectableStages end
		end
	elseif main.f_input(main.t_players, {'$D'}) then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		for i = 1, 10 do
			stageListNo = stageListNo + 1
			if stageListNo > #main.t_selectableStages then stageListNo = 0 end
		end
	end
	if n ~= stageListNo and stageListNo > 0 then
		animReset(main.t_selStages[main.t_selectableStages[stageListNo]].anim_data)
		animUpdate(main.t_selStages[main.t_selectableStages[stageListNo]].anim_data)
	end
end


--sets stage
function start.f_setStage(num, assigned)
	if main.stageMenu then
		num = main.t_selectableStages[stageListNo]
		if stageListNo == 0 then
			num = main.t_selectableStages[math.random(1, #main.t_selectableStages)]
			stageListNo = num -- comment out to randomize stage after each fight in survival mode, when random stage is chosen
			stageRandom = true
		else
			num = main.t_selectableStages[stageListNo]
		end
		assigned = true
	end
	if not assigned then
		if main.charparam.stage and start.f_getCharData(start.p[2].t_selected[1].ref).stage ~= nil then --stage assigned as character param
			num = math.random(1, #start.f_getCharData(start.p[2].t_selected[1].ref).stage)
			num = start.f_getCharData(start.p[2].t_selected[1].ref).stage[num]
		elseif main.stageOrder and main.t_orderStages[start.f_getCharData(start.p[2].t_selected[1].ref).order] ~= nil then --stage assigned as stage order param
			num = math.random(1, #main.t_orderStages[start.f_getCharData(start.p[2].t_selected[1].ref).order])
			num = main.t_orderStages[start.f_getCharData(start.p[2].t_selected[1].ref).order][num]
		else --stage randomly selected
			num = main.t_includeStage[1][math.random(1, #main.t_includeStage[1])]
		end
	end
	selectStage(num)
	return num
end


function start.f_cellMovement(selX, selY, cmd, side, snd, dir)
	local tmpX = selX
	local tmpY = selY
	local found = false
	--[[if main.f_input({cmd}, {'$U'}) or dir == 'U' then
		for i = 1, motif.select_info.rows do
			selY = selY - 1
			if selY < 0 then
				if motif.select_info.wrapping == 1 or dir ~= nil then
					selY = motif.select_info.rows - 1
				else
					selY = tmpY
				end
			end
			if dir ~= nil then
				found, selX = start.f_searchEmptyBoxes(selX, selY, side, -1)
			elseif (start.t_grid[selY + 1][selX + 1].char ~= nil or motif.select_info.moveoveremptyboxes == 1) and start.t_grid[selY + 1][selX + 1].skip ~= 1 and (config.TeamDuplicates or start.t_grid[selY + 1][selX + 1].char == 'randomselect' or not t_reservedChars[side][start.t_grid[selY + 1][selX + 1].char_ref]) and start.t_grid[selY + 1][selX + 1].hidden ~= 2 then
				break
			elseif motif.select_info.searchemptyboxesup ~= 0 then
				found, selX = start.f_searchEmptyBoxes(selX, selY, side, motif.select_info.searchemptyboxesup)
			end
			if found then
				break
			end
		end
	elseif main.f_input({cmd}, {'$D'}) or dir == 'D' then
		for i = 1, motif.select_info.rows do
			selY = selY + 1
			if selY >= motif.select_info.rows then
				if motif.select_info.wrapping == 1 or dir ~= nil then
					selY = 0
				else
					selY = tmpY
				end
			end
			if dir ~= nil then
				found, selX = start.f_searchEmptyBoxes(selX, selY, side, 1)
			elseif (start.t_grid[selY + 1][selX + 1].char ~= nil or motif.select_info.moveoveremptyboxes == 1) and start.t_grid[selY + 1][selX + 1].skip ~= 1 and (config.TeamDuplicates or start.t_grid[selY + 1][selX + 1].char == 'randomselect' or not t_reservedChars[side][start.t_grid[selY + 1][selX + 1].char_ref]) and start.t_grid[selY + 1][selX + 1].hidden ~= 2 then
				break
			elseif motif.select_info.searchemptyboxesdown ~= 0 then
				found, selX = start.f_searchEmptyBoxes(selX, selY, side, motif.select_info.searchemptyboxesdown)
			end
			if found then
				break
			end
		end
	elseif main.f_input({cmd}, {'$B'}) or dir == 'B' then
		if dir ~= nil then
			found, selX = start.f_searchEmptyBoxes(selX, selY, side, -1)
		else
			for i = 1, motif.select_info.columns do
				selX = selX - 1
				if selX < 0 then
					if motif.select_info.wrapping == 1 then
						selX = motif.select_info.columns - 1
					else
						selX = tmpX
					end
				end
				if (start.t_grid[selY + 1][selX + 1].char ~= nil or motif.select_info.moveoveremptyboxes == 1) and start.t_grid[selY + 1][selX + 1].skip ~= 1 and (config.TeamDuplicates or start.t_grid[selY + 1][selX + 1].char == 'randomselect' or not t_reservedChars[side][start.t_grid[selY + 1][selX + 1].char_ref]) and start.t_grid[selY + 1][selX + 1].hidden ~= 2 then
					break
				end
			end
		end
	elseif main.f_input({cmd}, {'$F'}) or dir == 'F' then
		if dir ~= nil then
			found, selX = start.f_searchEmptyBoxes(selX, selY, side, 1)
		else
			for i = 1, motif.select_info.columns do
				selX = selX + 1
				if selX >= motif.select_info.columns then
					if motif.select_info.wrapping == 1 then
						selX = 0
					else
						selX = tmpX
					end
				end
				if (start.t_grid[selY + 1][selX + 1].char ~= nil or motif.select_info.moveoveremptyboxes == 1) and start.t_grid[selY + 1][selX + 1].skip ~= 1 and (config.TeamDuplicates or start.t_grid[selY + 1][selX + 1].char == 'randomselect' or not t_reservedChars[side][start.t_grid[selY + 1][selX + 1].char_ref]) and start.t_grid[selY + 1][selX + 1].hidden ~= 2 then
					break
				end
			end
		end
	end]]--
	if (tmpX ~= selX or tmpY ~= selY) then
		if dir == nil then
			sndPlay(motif.files.snd_data, snd[1], snd[2])
		end
	end
	return selX, selY
end


--Extra data needed due to selScreenEnd being local

--resets various data
function start.f_selectReset(hardReset)
	esc(false)
	setMatchNo(1)
	setConsecutiveWins(1, 0)
	setConsecutiveWins(2, 0)
	setContinue(false)
	main.f_cmdInput()
	local col = 1
	local row = 1
	for i = 1, #main.t_selGrid do
		if i > motif.select_info.columns * row then
			row = row + 1
			col = 1
		end
		if main.t_selGrid[i].slot ~= 1 then
			main.t_selGrid[i].slot = 1
			start.t_grid[row][col].char = start.f_selGrid(i).char
			start.t_grid[row][col].char_ref = start.f_selGrid(i).char_ref
			start.t_grid[row][col].hidden = start.f_selGrid(i).hidden
			start.t_grid[row][col].skip = start.f_selGrid(i).skip
		end
		col = col + 1
	end
	if hardReset then
		stageListNo = 0
		restoreCursor = false
		--cursor start cell
		for i = 1, config.Players do
			if start.f_getCursorData(i, '_cursor_startcell')[1] < motif.select_info.rows then
				start.c[i].selY = start.f_getCursorData(i, '_cursor_startcell')[1]
			else
				start.c[i].selY = 0
			end
			if start.f_getCursorData(i, '_cursor_startcell')[2] < motif.select_info.columns then
				start.c[i].selX = start.f_getCursorData(i, '_cursor_startcell')[2]
			else
				start.c[i].selX = 0
			end
			start.c[i].cell = -1
			start.c[i].randCnt = 0
			start.c[i].randRef = nil
		end
	end
	if stageRandom then
		stageListNo = 0
		stageRandom = false
	end
	for side = 1, 2 do
		if hardReset then
			start.p[side].numSimul = math.max(2, config.NumSimul[1])
			start.p[side].numTag = math.max(2, config.NumTag[1])
			start.p[side].numTurns = math.max(2, config.NumTurns[1])
			start.p[side].numRatio = 1
			start.p[side].teamMenu = 1
			start.p[side].t_cursor = {}
			start.p[side].teamMode = 0
		end
		start.p[side].numSimul = math.min(start.p[side].numSimul, main.numSimul[2])
		start.p[side].numTag = math.min(start.p[side].numTag, main.numTag[2])
		start.p[side].numTurns = math.min(start.p[side].numTurns, main.numTurns[2])
		start.p[side].numChars = 1
		start.p[side].teamEnd = main.cpuSide[side] and (side == 2 or not main.cpuSide[1]) and main.forceChar[side] == nil
		start.p[side].selEnd = not main.selectMenu[side]
		start.p[side].ratio = false
		start.p[side].t_selected = {}
		start.p[side].t_selTemp = {}
		start.p[side].t_selCmd = {}
	end
	for _, v in ipairs(start.c) do
		v.cell = -1
	end
	selScreenEnd = false
	stageEnd = false
	t_reservedChars = {{}, {}}
	start.winCnt = 0
	start.loseCnt = 0
	if start.challenger == 0 then
		start.t_savedData = {
			win = {0, 0},
			lose = {0, 0},
			time = {total = 0, matches = {}},
			score = {total = {0, 0}, matches = {}},
			consecutive = {0, 0},
			debugflag = {false, false},
		}
		start.t_roster = {}
		start.reset = true
	end
	t_recordText = start.f_getRecordText()
	menu.movelistChar = 1
	hook.run("start.f_selectReset")
end

function launchFight(data)
	local t = {}
	if continue() then -- on rematch all arguments are ignored and values are restored from last match
		t = main.f_tableCopy(start.launchFightSav)
		start.p[2].t_selTemp = {} -- in case it's not cleaned already (preserved p2 side during select screen)
	else -- otherwise take all arguments and settings into account
		t.p1numchars = start.p[1].numChars
		t.p1teammode = start.p[1].teamMode
		t.p2numchars = start.p[2].numChars
		t.p2teammode = start.p[2].teamMode
		t.challenger = main.f_arg(data.challenger, false)
		t.continue = main.f_arg(data.continue, main.continueScreen)
		t.quickcontinue = (not main.selectMenu[1] and not main.selectMenu[2]) or main.f_arg(data.quickcontinue, main.quickContinue or config.QuickContinue)
		t.order = data.order or 1
		t.orderselect = {main.f_arg(data.p1orderselect, main.orderSelect[1]), main.f_arg(data.p2orderselect, main.orderSelect[2])}
		t.p1char = data.p1char or {}
		t.p1numratio = data.p1numratio or {}
		t.p1rounds = data.p1rounds or nil
		t.p2char = data.p2char or {}
		t.p2numratio = data.p2numratio or {}
		t.p2rounds = data.p2rounds or nil
		t.exclude = data.exclude or {}
		t.musicData = {}
		-- Parse musicX / musicfinal / musiclife / musicvictory arguments
		for k, v in pairs(data) do
			if k:match('^music') then
				-- old syntax with only string argument maintained for backward compatibility with previous builds
				if type(v) == "string" then
					v = {v}
				end
				local bgtype, round = k:match('^(music[a-z]*)([0-9]*)$')
				if t.musicData[bgtype] == nil then
					t.musicData[bgtype] = {}
				end
				local t_ref = t.musicData[bgtype]
				-- musicX parameters are nested using round numbers as table keys
				if bgtype == 'music' or round ~= '' then
					round = tonumber(round) or 1
					if t.musicData[bgtype][round] == nil then t.musicData[bgtype][round] = {} end
					t_ref = t.musicData[bgtype][round]
				end
				table.insert(t_ref, {bgmusic = (v[1] or ''), bgmvolume = (v[2] or 100), bgmloopstart = (v[3] or 0), bgmloopend = (v[4] or 0)})
			end
		end
		t.stage = data.stage or ''
		t.ai = data.ai or nil
		t.vsscreen = main.f_arg(data.vsscreen, main.versusScreen)
		t.victoryscreen = main.f_arg(data.victoryscreen, main.victoryScreen)
		--t.frames = data.frames or framespercount()
		t.roundtime = data.time or nil
		t.lua = data.lua or ''
		t.stageNo = start.f_getStageRef(t.stage)
		start.p[1].numChars = data.p1numchars or math.max(start.p[1].numChars, #t.p1char)
		start.p[1].teamMode = start.f_stringToTeamMode(data.p1teammode) or start.p[1].teamMode
		start.p[2].numChars = data.p2numchars or math.max(start.p[2].numChars, #t.p2char)
		start.p[2].teamMode = start.f_stringToTeamMode(data.p2teammode) or start.p[2].teamMode
		t.p1numchars = start.f_matchPersistence()
		-- add P1 chars forced via function arguments (ignore char param restrictions)
		local reset = false
		local cnt = 0
		for _, v in main.f_sortKeys(t.p1char) do
			if not reset then
				start.p[1].t_selected = {}
				start.p[1].t_selTemp = {}
				reset = true
			end
			cnt = cnt + 1
			local ref = start.f_getCharRef(v)
			table.insert(start.p[1].t_selected, {
				ref = ref,
				pal = start.f_selectPal(ref),
				pn = start.f_getPlayerNo(1, #start.p[1].t_selected + 1),
				--cursor = {},
				ratioLevel = start.f_getRatio(1, t.p1numratio[cnt]),
			})
			main.t_availableChars = start.f_excludeChar(main.t_availableChars, ref)
		end
		if #start.p[1].t_selected == 0 then
			panicError("\n" .. "launchFight(): no valid P1 characters\n")
			start.exit = true
			return false -- return to main menu
		end
		-- add P2 chars forced via function arguments (ignore char param restrictions)
		local onlyme = false
		cnt = 0
		for _, v in main.f_sortKeys(t.p2char) do
			cnt = cnt + 1
			local ref = start.f_getCharRef(v)
			table.insert(start.p[2].t_selected, {
				ref = ref,
				pal = start.f_selectPal(ref),
				pn = start.f_getPlayerNo(2, #start.p[2].t_selected + 1),
				--cursor = {},
				ratioLevel = start.f_getRatio(2, t.p2numratio[cnt]),
			})
			main.t_availableChars = start.f_excludeChar(main.t_availableChars, ref)
			if not onlyme then onlyme = start.f_getCharData(ref).single end
		end
		-- add remaining P2 chars of particular order if there are still free slots in the selected team mode
		if main.cpuSide[2] and #start.p[2].t_selected < start.p[2].numChars and not onlyme then
			-- get list of available chars
			local t_chars = main.f_tableCopy(main.t_availableChars)
			-- remove chars temporary excluded from this match
			for _, v in ipairs(t.exclude) do
				t_chars = start.f_excludeChar(t_chars, start.f_getCharRef(v))
			end
			-- remove chars with 'single' param if some characters are forced into team
			if #start.p[2].t_selected > 0 then
				for _, v in ipairs(t_chars[t.order]) do
					if start.f_getCharData(v).single then
						t_chars = start.f_excludeChar(t_chars, v)
					end
				end
			end
			-- fill free slots
			local t_remaining = main.f_tableCopy(t_chars)
			local t_tmp = {}
			for i = #start.p[2].t_selected, start.p[2].numChars - 1 do
				if t_chars[t.order] ~= nil and #t_chars[t.order] > 0 then
					local rand = math.random(1, #t_chars[t.order])
					local ref = t_chars[t.order][rand]
					if not start.f_getCharData(ref).single then
						table.remove(t_chars[t.order], rand)
						table.insert(t_tmp, ref)
					else --one entry if 'single' param is detected on any opponent
						t_tmp = {ref}
						onlyme = true
						break
					end
				end
			end
			-- not enough unique characters of particular order, take into account only if skiporder parameter = false
			while not t.skiporder and #t_tmp + #start.p[2].t_selected < start.p[2].numChars and not onlyme and t_remaining[t.order] ~= nil and #t_remaining[t.order] > 0 do
				table.insert(t_tmp, t_remaining[t.order][math.random(1, #t_remaining[t.order])])
			end
			-- append remaining characters
			for _, v in ipairs(t_tmp) do
				table.insert(start.p[2].t_selected, {
					ref = v,
					pal = start.f_selectPal(v),
					pn = start.f_getPlayerNo(2, #start.p[2].t_selected + 1),
					--cursor = {},
					ratioLevel = start.f_getRatio(2, t.p2numratio[cnt]),
				})
				main.t_availableChars = start.f_excludeChar(main.t_availableChars, v)
			end
			-- team conversion if 'single' param is set on randomly added chars
			if onlyme and #start.p[2].t_selected > 1 then
				panicError("Unexpected launchFight state.\nPlease write down everything that lead to this error and report it to K4thos.\n")
				--[[for i = 1, #start.p[2].t_selected do
					if not start.f_getCharData(start.p[2].t_selected[i].ref).single then
						table.insert(main.t_availableChars[t.order], start.p[2].t_selected[i].ref)
						table.remove(start.p[2].t_selected, k)
					end
				end]]
			end
		end
		if onlyme then
			start.p[2].numChars = #start.p[2].t_selected
		end
		-- skip match if needed
		if #start.p[2].t_selected < start.p[2].numChars then
			start.p[2].t_selected = {}
			start.p[2].t_selTemp = {}
			printConsole("launchFight(): not enough P2 characters, skipping execution")
			setMatchNo(matchno() + 1)
			return true --continue lua code execution
		end
	end
	--TODO: fix config.BackgroundLoading setting
	--if config.BackgroundLoading then
	--	selectStart()
	--else
		clearSelected()
	--end
	local ok = false
	local saveData = false
	local loopCount = 0
	while true do
		-- fight initialization
		setTeamMode(1, start.p[1].teamMode, start.p[1].numChars)
		setTeamMode(2, start.p[2].teamMode, start.p[2].numChars)
		start.f_remapAI(t.ai)
		start.f_setRounds(t.roundtime, {t.p1rounds, t.p2rounds})
		t.stageNo = start.f_setStage(t.stageNo, t.stage ~= '' or continue() or loopCount > 0)
		start.f_setMusic(t.stageNo, t.musicData)
		if not start.f_selectVersus(t.vsscreen, t.orderselect) then break end
		start.f_selectLoading()
		start.f_overrideCharData()
		saveData = true
		local continueScreen = main.continueScreen
		local victoryScreen = main.victoryScreen
		main.continueScreen = t.continue
		main.victoryScreen = t.victoryscreen
		hook.run("launchFight")
		_, t_gameStats = start.f_game(t.lua)
		main.continueScreen = continueScreen
		main.victoryScreen = victoryScreen
		clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
		-- here comes a new challenger
		if start.challenger > 0 then
			saveData = false
			if t.challenger then -- end function called by f_arcadeChallenger() regardless of outcome
				ok = not start.exit and not esc()
				break
			elseif not start.f_selectChallenger() then
				start.challenger = 0
				break
			end
		-- player exit the game via ESC
		elseif winnerteam() == -1 then
			if not main.selectMenu[1] and not main.selectMenu[2] then
				setMatchNo(-1)
			end
			break
		-- player lost in modes that ends after 1 lose
		elseif winnerteam() ~= 1 and main.elimination then
			setMatchNo(-1)
			break
		-- player won or continuing is disabled
		elseif winnerteam() == 1 or not t.continue then
			start.p[2].t_selected = {}
			start.p[2].t_selTemp = {}
			setMatchNo(matchno() + 1)
			setContinue(false)
			ok = true -- continue lua code execution
			break
		-- continue = no
		elseif not continue() then
			setMatchNo(-1)
			break
		-- continue = yes
		elseif not t.quickcontinue then -- if 'Quick Continue' is disabled
			start.p[1].t_selected = {}
			start.p[1].t_selTemp = {}
			start.p[1].selEnd = false
			start.launchFightSav = main.f_tableCopy(t)
			--start.p[2].t_selTemp = {} -- uncomment to disable enemy team showing up in select screen
			selScreenEnd = false
			start.f_saveData()
			return
		else
			start.f_saveData()
		end
		start.challenger = 0
		loopCount = loopCount + 1
	end
	if saveData then
		start.f_saveData()
	end
	-- restore original values
	start.p[1].numChars = t.p1numchars
	start.p[1].teamMode = t.p1teammode
	start.p[2].numChars = t.p2numchars
	start.p[2].teamMode = t.p2teammode
	return ok
end


--save data between matches
start.t_savedData = {}
function start.f_saveData()
	if main.debugLog then main.f_printTable(t_gameStats, 'debug/t_gameStats.txt') end
	if winnerteam() == -1 then
		return
	end
	--win/lose matches count, total score
	if winnerteam() == 1 then
		start.t_savedData.win[1] = start.t_savedData.win[1] + 1
		start.t_savedData.lose[2] = start.t_savedData.lose[2] + 1
		start.t_savedData.score.total[1] = t_gameStats.p1score
	else --if winnerteam() == 2 then
		start.t_savedData.win[2] = start.t_savedData.win[2] + 1
		start.t_savedData.lose[1] = start.t_savedData.lose[1] + 1
		if main.resetScore and matchno() ~= -1 then --loosing sets score for the next match to lose count
			start.t_savedData.score.total[1] = start.t_savedData.lose[1]
			start.t_savedData.debugflag[1] = false
		else
			start.t_savedData.score.total[1] = t_gameStats.p1score
		end
	end
	start.t_savedData.score.total[2] = t_gameStats.p2score
	--total time
	start.t_savedData.time.total = start.t_savedData.time.total + t_gameStats.matchTime
	--time in each round
	table.insert(start.t_savedData.time.matches, t_gameStats.timerRounds)
	--score in each round
	table.insert(start.t_savedData.score.matches, t_gameStats.scoreRounds)
	--max consecutive wins
	for side = 1, 2 do
		if getConsecutiveWins(side) > start.t_savedData.consecutive[side] then
			start.t_savedData.consecutive[side] = getConsecutiveWins(side)
		end
	end
	if main.debugLog then main.f_printTable(start.t_savedData, 'debug/t_savedData.txt') end
end

function start.f_matchPersistence()
	-- checked only after at least 1 match
	if matchno() >= 2 then
		-- set 'existed' flag (decides if var/fvar should be persistent between matches)
		for _, v in ipairs(t_gameStats.match) do
			for _, t in pairs(v) do
				if start.p[t.teamside + 1].t_selected[t.memberNo + 1] ~= nil then
					start.p[t.teamside + 1].t_selected[t.memberNo + 1].existed = true
				end
			end
		end
		-- if defeated members should be removed from team, or if life should be maintained
		if main.dropDefeated or main.lifePersistence then
			local t_removeMembers = {}
			-- Turns
			if start.p[1].teamMode == 2 then
				--for each round in the last match
				for _, v in ipairs(t_gameStats.match) do
					-- if defeated
					if v[1].ko and v[1].life <= 0 then
						-- remove character from team
						if main.dropDefeated then
							t_removeMembers[v[1].memberNo + 1] = true
						-- or resurrect and recover character's life
						elseif main.lifePersistence then
							start.p[1].t_selected[v[1].memberNo + 1].life = math.max(1, f_lifeRecovery(v[1].lifeMax, v[1].ratiolevel))
						end
					-- otherwise maintain character's life
					elseif main.lifePersistence then
						start.p[1].t_selected[v[1].memberNo + 1].life = v[1].life
					end
				end
			-- Single / Simul / Tag
			else
				-- for each player data in the last round
				for _, v in pairs(t_gameStats.match[#t_gameStats.match]) do
					-- only check player controlled characters
					if not main.cpuSide[v.teamside + 1] then
						-- if defeated
						if v.ko and v.life <= 0 then
							-- remove character from team
							if main.dropDefeated then
								t_removeMembers[v.memberNo + 1] = true
							-- or resurrect and recover character's life
							elseif main.lifePersistence then
								start.p[1].t_selected[v.memberNo + 1].life = math.max(1, f_lifeRecovery(v.lifeMax, v.ratiolevel))
							end
						-- otherwise maintain character's life
						elseif main.lifePersistence then
							start.p[1].t_selected[v.memberNo + 1].life = v.life
						end
					end
				end
			end
			-- drop defeated characters
			for i = #start.p[1].t_selected, 1, -1 do
				if t_removeMembers[i] then
					table.remove(start.p[1].t_selected, i)
					table.remove(start.p[1].t_selTemp, i)
					start.p[1].numChars = start.p[1].numChars - 1
				end
			end
		end
	end
	return start.p[1].numChars
end
