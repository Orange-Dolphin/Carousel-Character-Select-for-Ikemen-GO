enableCharacterSelect = true
enableStageSelect = false

--Set stages per row here
if enableStageSelect == true then
	NumStages = {}
	NumStages[1] = 5
	NumStages[2] = 1
	--NumStages[3] = 4
	--NumStages[4] = 4
	--NumStages[4] = 3
	--NumStages[5] = 3
	--NumStages[6] = 3
end

if enableCharacterSelect == true then
	function charSelectInitalize() 
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
		slideHor = 0
		slideVer = 0
		slideHorDir = 0
		slideVerDir = 0
		slideTimeHor = {}
		slideTimeVer = {}
		motif.select_info['pos'] = {25000, 25000}
		for side = 1, 2 do
			slideTimeHor[side] = 0
			slideTimeVer[side] = 0
			for k = 1, 4 do
				if motif.select_info['p' .. side .. '_fp_' .. directions[k] .. '_spacing'] ~= nil then
					spacing[k] = motif.select_info['p' .. side .. '_fp_' .. directions[k] .. '_spacing']
				end	
			end

			if motif.select_info['p' .. side .. '_fp_slide_time'] == nil then
				motif.select_info['p' .. side .. '_fp_slide_time'] = 1
			end
			start.c[side].trueX = 1
			start.c[side].trueY = 1
		end

		newGrid = {}
		newGrid[1] = {}
		row = 1
		col = 1
		cellNum = 0
		for i = 1, #main.t_selGrid do
			if start.f_selGrid(i).char ~= nil then
				table.insert(newGrid[row], {char = start.f_selGrid(i).char, char_ref = start.f_selGrid(i).char_ref, hidden = start.f_selGrid(i).hidden, skip = start.f_selGrid(i).skip, cell = cellNum})
				cellNum = cellNum + 1
			elseif main.t_selGrid[i].slot ~= 1 then
			else
				if #newGrid[row] > 0 then
					row = row + 1
					newGrid[row] = {}
				end
				cellNum = cellNum + 1
			end

		end


		numberOfRows = 0
		charsPerRow = {}
		charsInRow = {}
		charsRows = {}
		for i = 1, #newGrid do
			charsInRow[i] = {}
			rowChars = 0
			for v = 1, #newGrid[i] do
				local t = newGrid[i][v]
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
		hoverCharacters = {}
		for side = 1, 2 do
			hoverCharacters[side] = {}
			for i = 1, #newGrid do
				hoverCharacters[side][i] = 1
			end
		end

		prefix = {}
		for side = 1, 2 do
			prefix[side] = 'p' .. side .. '_cursor_active'
			-- create spr/anim data, if not existing yet
			if motif.select_info['p' .. side .. '_cursor_active' .. '_data'] == nil then
				-- if cell based variants are not defined we're defaulting to standard pX parameters
				for _, v in ipairs({'_anim', '_spr', '_offset', '_scale', '_facing'}) do
					if motif.select_info[prefix[side] .. v] == nil then
						motif.select_info[prefix[side] .. v] = start.f_getCursorData(pn, param .. v)
					end
				end
				motif.f_loadSprData(motif.select_info, {s = prefix[side] .. '_'})
			end
		end
		

	end
	
	function start.f_cellMovement(selX, selY, cmd, side, snd, dir)
		
		moved = false
		if main.f_input({cmd}, {'$U'}) or dir == 'U' then
			start.c[side].trueY = ((start.c[side].trueY - 2) % numberOfRows) + 1
			start.c[side].trueX = hoverCharacters[side][start.c[side].trueY]
			slideVer = -1
			slideTimeVer[side] = motif.select_info['p' .. side .. '_fp_slide_time']
			moved = true
		elseif main.f_input({cmd}, {'$D'}) or dir == 'D' then
			start.c[side].trueY = (start.c[side].trueY % numberOfRows) + 1
			while #charsInRow[start.c[side].trueY] == 0 do
				start.c[side].trueY = (start.c[side].trueY % numberOfRows) + 1
			end
			start.c[side].trueX = hoverCharacters[side][start.c[side].trueY]
			print(#charsInRow[start.c[side].trueY])
			slideVer = 1
			slideTimeVer[side] = motif.select_info['p' .. side .. '_fp_slide_time']
			moved = true
		elseif main.f_input({cmd}, {'$F'}) or dir == 'F' then
			start.c[side].trueX = ((start.c[side].trueX) % charsPerRow[start.c[side].trueY] - 1) + 2
			hoverCharacters[side][start.c[side].trueY] = start.c[side].trueX
			slideHor = 1
			slideTimeHor[side] = motif.select_info['p' .. side .. '_fp_slide_time']
			moved = true
		elseif main.f_input({cmd}, {'$B'}) or dir == 'B' then
			start.c[side].trueX = ((start.c[side].trueX - 2) % charsPerRow[start.c[side].trueY]) + 1
			hoverCharacters[side][start.c[side].trueY] = start.c[side].trueX		
			slideHor = -1
			slideTimeHor[side] = motif.select_info['p' .. side .. '_fp_slide_time']
			moved = true
		end
		if moved == true then
			sndPlay(motif.files.snd_data, motif.select_info['p' .. side .. '_cursor_move_snd'][1], motif.select_info['p' .. side .. '_cursor_move_snd'][2])
		end
		
		start.needUpdateDrawList = true
		testVariable = newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][start.c[side].trueX]].cell
		return (testVariable % motif.select_info.columns ), math.floor(testVariable / motif.select_info.columns)
	end
	
	function start.updateDrawList()
		drawList = {}
		for side = 1, 2 do
			if motif.select_info['p' .. side .. '_fp_main_pos'] ~= nil then
				if start.p[side].teamEnd == true and (((start.p[side].selEnd == false) and (start.p[side].teamEnd == true)) or (motif.select_info.hideoncompleteselection == 0)) and (((start.p[1].selEnd and main.cpuSide[2]) or side == 1) or main.cpuSide[2] == false) then
					if slideTimeHor[side] > 0 then
						slideTimeHor[side] = slideTimeHor[side] - 1
					end
					if slideTimeVer[side] > 0 then
						slideTimeVer[side] = slideTimeVer[side] - 1
					end
					--vertical showcase
					for n = 1, motif.select_info['p' .. side .. '_fp_up'] or 0 do
						table.insert(drawList, {
							anim = motif.select_info.cell_bg_data,
							x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n),
							y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
							facing = 1
						})
						local t = newGrid[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]][charsInRow[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]][hoverCharacters[side][charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]]]]
						table.insert(drawList, {
							anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
							x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n),
							y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
							facing = 1
						})
						for h = 1, motif.select_info['p' .. side .. '_fp_up_' .. n .. '_right'] or 0 do
							if charsPerRow[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]] > h then
								table.insert(drawList, {
									anim = motif.select_info.cell_bg_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[4][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[4][2] * h),
									facing = 1
								})
								precalc = charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]
								local t = newGrid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] + h - 1) % charsPerRow[precalc]) + 1]]
								table.insert(drawList, {
									anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[4][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[4][2] * h),
									facing = 1
								})
							end
						end
						for h = 1, motif.select_info['p' .. side .. '_fp_up_' .. n .. '_left'] or 0 do
							if charsPerRow[charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]] > h then
								table.insert(drawList, {
									anim = motif.select_info.cell_bg_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[3][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[3][2] * h),
									facing = 1
								})
								precalc = charsRows[((start.c[side].trueY - n - 1) % numberOfRows) + 1]
								local t = newGrid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] - h - 1) % charsPerRow[precalc]) + 1]]
								table.insert(drawList, {
									anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[1][1] * n) + (spacing[3][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[1][2] * n) + (spacing[3][2] * h),
									facing = 1
								})
							end
						end
					end
					for n = 1, motif.select_info['p' .. side .. '_fp_down'] or 0 do
						table.insert(drawList, {
						anim = motif.select_info.cell_bg_data,
							x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n),
							y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
							facing = 1
						})
						local t = newGrid[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]][charsInRow[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]][hoverCharacters[side][charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]]]]
						table.insert(drawList, {
						anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
							x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n),
							y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
							facing = 1
						})
						for h = 1, motif.select_info['p' .. side .. '_fp_down_' .. n .. '_right'] or 0 do
							if charsPerRow[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]] > h then
								table.insert(drawList, {
									anim = motif.select_info.cell_bg_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[4][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[4][2] * h),
									facing = 1
								})
								precalc = charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]
								local t = newGrid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] + h - 1) % charsPerRow[precalc]) + 1]]
								
								table.insert(drawList, {
									anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[4][1] * h),
									y =motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[4][2] * h),
									facing = 1
								})
							end
						end
						for h = 1, motif.select_info['p' .. side .. '_fp_down_' .. n .. '_left'] or 0 do
							if charsPerRow[charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]] > h then
								table.insert(drawList, {
									anim = motif.select_info.cell_bg_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[3][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[3][2] * h),
									facing = 1
								})
								precalc = charsRows[((start.c[side].trueY + n - 1) % numberOfRows) + 1]
								local t = newGrid[precalc][charsInRow[precalc][((hoverCharacters[side][precalc] - h - 1) % charsPerRow[precalc]) + 1]]
								table.insert(drawList, {
									anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
									x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (spacing[2][1] * n) + (spacing[3][1] * h),
									y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (spacing[2][2] * n) + (spacing[3][2] * h),
									facing = 1
								})
							end
						end
					end
					--=================================================================================
					--=================================================================================
					--=================================================================================
					--=================================================================================
					--horizontal displays
					for n = 1, motif.select_info['p' .. side .. '_fp_main_right'] or 0 do
						if charsPerRow[start.c[side].trueY] > n then
							table.insert(drawList, {
								anim = motif.select_info.cell_bg_data,
								x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[4][1])  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
								y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[4][2]),
								facing = 1
							})
							local t = newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX + n - 1) % charsPerRow[start.c[side].trueY]) + 1]]
							table.insert(drawList, {
								anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
								x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[4][1])  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
								y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[4][2]),
								facing = 1
							})		
						end
					end
					for n = 1, motif.select_info['p' .. side .. '_fp_main_left'] or 0 do
						if charsPerRow[start.c[side].trueY] > n then
							table.insert(drawList, {
								anim = motif.select_info.cell_bg_data,
								x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[3][1])   + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
								y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[3][2]),
								facing = 1
							})		
							local t = newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX - n - 1) % charsPerRow[start.c[side].trueY]) + 1]]
							table.insert(drawList, {
								anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
								x = motif.select_info['p' .. side .. '_fp_main_pos'][1] + (n * spacing[3][1]) + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
								y = motif.select_info['p' .. side .. '_fp_main_pos'][2] + (n * spacing[3][2]),
								facing = 1
							})			
						end
					end
					--=================================================================================
					--=================================================================================
					--=================================================================================
					--=================================================================================
					--main display
					local t = newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX - 1) % charsPerRow[start.c[side].trueY]) + 1]]
					scaleToUse = {}
					scaleToUse[1] = 1
					scaleToUse[2] = 1
					table.insert(drawList, {
						anim = motif.select_info['cell_bg' .. '_data'],
						x = motif.select_info['p' .. side .. '_fp_main_pos'][1] - (((motif.select_info['cell_size'][1] * scaleToUse[1]) - motif.select_info['cell_size'][1]) / 2) + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
						y = motif.select_info['p' .. side .. '_fp_main_pos'][2] - (((motif.select_info['cell_size'][2] * scaleToUse[2]) - motif.select_info['cell_size'][2]) / 2) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
						facing = 1
					})
					table.insert(drawList, {
						anim = start.f_getCharData(t.char_ref).cell_data or motif.select_info.cell_random_data,
						x = motif.select_info['p' .. side .. '_fp_main_pos'][1] - (((motif.select_info['cell_size'][1] * scaleToUse[1]) - motif.select_info['cell_size'][1]) / 2)  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
						y = motif.select_info['p' .. side .. '_fp_main_pos'][2] - (((motif.select_info['cell_size'][2] * scaleToUse[2]) - motif.select_info['cell_size'][2]) / 2) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
						facing = 1
					})	
					
					
					
					
					if motif.select_info['p' .. side .. '_fp_cursor'] ~= 0 then
						if motif.select_info['p' .. side .. '_fp_slide_cursor'] == 1 then
							-- draw
							table.insert(drawList, {
								anim = motif.select_info[prefix[side] .. '_data'],
								x = motif.select_info['p' .. side .. '_fp_main_pos'][1] - (((motif.select_info['cell_size'][1] * scaleToUse[1]) - motif.select_info['cell_size'][1]) / 2)  + (slideHor * ((spacing[4][1]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeHor[side])),
								y = motif.select_info['p' .. side .. '_fp_main_pos'][2] - (((motif.select_info['cell_size'][2] * scaleToUse[2]) - motif.select_info['cell_size'][2]) / 2) + (slideVer * ((spacing[2][2]) / motif.select_info['p' .. side .. '_fp_slide_time'] * slideTimeVer[side])),
								facing = 1
							})	
						else
							-- draw
							table.insert(drawList, {
								anim = motif.select_info[prefix[side] .. '_data'],
								x = motif.select_info['p' .. side .. '_fp_main_pos'][1],
								y = motif.select_info['p' .. side .. '_fp_main_pos'][2],
								facing = 1
							})	
						end
						animUpdate(motif.select_info[prefix[side] .. '_data'])
					end
				end
			end
		end
			
		return drawList
	end

	function start.f_slotSelected(cell, side, cmd, player, x, y)
		if cmd == nil then
			return false
		end
		if #main.t_selGrid[cell].chars > 0 then
			-- select.def 'slot' parameter special keys detection
			for _, cmdType in ipairs({'select', 'next', 'previous'}) do
				if main.t_selGrid[cell][cmdType] ~= nil then
					for k, v in pairs(main.t_selGrid[cell][cmdType]) do
						if main.f_input({cmd}, main.f_extractKeys(k)) then
							if cmdType == 'next' then
								local ok = false
								for i = main.t_selGrid[cell].slot + 1, #v do
									if start.f_getCharData(start.f_selGrid(cell, v[i]).char_ref).hidden < 2 then
										main.t_selGrid[cell].slot = v[i]
										ok = true
										break
									end
								end
								if not ok then
									for i = 1, main.t_selGrid[cell].slot - 1 do
										if start.f_getCharData(start.f_selGrid(cell, v[i]).char_ref).hidden < 2 then
											main.t_selGrid[cell].slot = v[i]
											ok = true
											break
										end
									end
								end
								if ok then
									sndPlay(motif.files.snd_data, motif.select_info['p' .. side .. '_swap_snd'][1], motif.select_info['p' .. side .. '_swap_snd'][2])
								end
							elseif cmdType == 'previous' then
								local ok = false
								for i = main.t_selGrid[cell].slot -1, 1, -1 do
									if start.f_getCharData(start.f_selGrid(cell, v[i]).char_ref).hidden < 2 then
										main.t_selGrid[cell].slot = v[i]
										ok = true
										break
									end
								end
								if not ok then
									for i = #v, main.t_selGrid[cell].slot + 1, -1 do
										if start.f_getCharData(start.f_selGrid(cell, v[i]).char_ref).hidden < 2 then
											main.t_selGrid[cell].slot = v[i]
											ok = true
											break
										end
									end
								end
								if ok then
									sndPlay(motif.files.snd_data, motif.select_info['p' .. side .. '_swap_snd'][1], motif.select_info['p' .. side .. '_swap_snd'][2])
								end
							else --select
								main.t_selGrid[cell].slot = v[math.random(1, #v)]
								start.c[player].selRef = start.f_selGrid(cell).char_ref
							end
							newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX - 1) % charsPerRow[start.c[side].trueY]) + 1]].char = start.f_selGrid(cell).char
							newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX - 1) % charsPerRow[start.c[side].trueY]) + 1]].char_ref = start.f_selGrid(cell).char_ref
							newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX - 1) % charsPerRow[start.c[side].trueY]) + 1]].hidden = start.f_selGrid(cell).hidden
							newGrid[start.c[side].trueY][charsInRow[start.c[side].trueY][((start.c[side].trueX - 1) % charsPerRow[start.c[side].trueY]) + 1]].skip = start.f_selGrid(cell).skip
							return cmdType == 'select'
						end
					end
				end
			end
		end
		return main.f_btnPalNo(cmd) > 0
	end

	charSelectInitalize()
end

if enableStageSelect == true then
	backupPos = motif.select_info.stage_pos
	motif.select_info.stage_pos= {0, 0}
	backupStageBG = motif.select_info.stage_portrait_bg_data
	motif.select_info.stage_portrait_bg_data = nil
	txt_selStage = main.f_createTextImg(motif.select_info, 'stage_active')
	stageActiveType = 'stage_active'
	StartNumbers = {}
	hoverStages = {}
	x = 0
	totalRows = 0
	for i, stagesNumber in ipairs(NumStages) do
		StartNumbers[i] = x
		hoverStages[i] = x + 1
		totalRows = totalRows + 1
		x = x + stagesNumber
	end
	currentStageRow = 0
	stageSlideHor = 0
	stageSlideVer = 0
	slideHorDir = 0
	slideVerDir = 0
	if motif.select_info.stage_spacing == nil then
		motif.select_info.stage_spacing = {}
		for i = 1, 2 do
			motif.select_info.stage_spacing[i] = 0
		end
	end
	
	stageListNo = 0
	if motif.select_info.stage_fp_slide_time == nil then
		motif.select_info.stage_fp_slide_time = 1
	end
	--;===========================================================
	--; STAGE MENU
	--;===========================================================
	function start.f_stageMenu()
		if timerSelect == -1 then
			stageEnd = true
			return
		elseif main.f_input(main.t_players, {'$B'}) then
			if currentStageRow ~= 0 then
				sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
				stageListNo = ((stageListNo - 2 - StartNumbers[currentStageRow]) % (NumStages[currentStageRow])) + 1 + StartNumbers[currentStageRow]
				slideHorDir = -1
				stageSlideHor = motif.select_info.stage_fp_slide_time
				hoverStages[currentStageRow] = stageListNo
			end
		elseif main.f_input(main.t_players, {'$F'}) then
			if currentStageRow ~= 0 then
				sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
				stageListNo = ((stageListNo - StartNumbers[currentStageRow]) % (NumStages[currentStageRow])) + 1 + StartNumbers[currentStageRow]
				slideHorDir = 1
				stageSlideHor = motif.select_info.stage_fp_slide_time
				hoverStages[currentStageRow] = stageListNo
			end
		elseif main.f_input(main.t_players, {'$U'}) then
			sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
			currentStageRow = currentStageRow - 1
			if currentStageRow == 0 then
				stageListNo = 0
			elseif currentStageRow == -1 then
				currentStageRow = totalRows
				stageListNo = hoverStages[currentStageRow]
			else
				stageListNo = hoverStages[currentStageRow]
			end
			slideVerDir = -1
			stageSlideVer = motif.select_info.stage_fp_slide_time
		elseif main.f_input(main.t_players, {'$D'}) then
			sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
			currentStageRow = currentStageRow + 1
			if currentStageRow == totalRows + 1 then
				stageListNo = 0
				currentStageRow = 0
			else
				stageListNo = hoverStages[currentStageRow]
			end
			
			slideVerDir = 1
			stageSlideVer = motif.select_info.stage_fp_slide_time
		end
		if n ~= stageListNo and stageListNo > 0 then
			animReset(main.t_selStages[main.t_selectableStages[stageListNo]].anim_data)
			animUpdate(main.t_selStages[main.t_selectableStages[stageListNo]].anim_data)
		end
		
		
		
		
		--draw stage portrait background
		main.f_animPosDraw(motif.select_info.stage_portrait_bg_data)
		--draw stage portrait (random)
		if stageListNo == 0 then
			main.f_animPosDraw(
				motif.select_info.stage_portrait_random_data,
				(stageSlideHor / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[1] * slideHorDir,
				(stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir
			)
		--draw stage portrait loaded from stage SFF
		else
			main.f_animPosDraw(
				main.t_selStages[main.t_selectableStages[stageListNo]].anim_data,
				(backupPos[1] + motif.select_info.stage_portrait_offset[1])  + ( (stageSlideHor / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[1] * slideHorDir),
				(backupPos[2] + motif.select_info.stage_portrait_offset[2]) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
			)
			for n = 1, motif.select_info['stage_fp_main_right'] or 0 do
				main.f_animPosDraw(
					main.t_selStages[main.t_selectableStages[((stageListNo + n - 1 - StartNumbers[currentStageRow]) % (NumStages[currentStageRow])) + 1 + StartNumbers[currentStageRow]]].anim_data,
					(backupPos[1] + motif.select_info.stage_portrait_offset[1] + (n * motif.select_info.stage_spacing[1]))  + ( (stageSlideHor / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[1] * slideHorDir),
					backupPos[2] + motif.select_info.stage_portrait_offset[2]
				)
			end
			for n = 1, motif.select_info['stage_fp_main_left'] or 0 do
				main.f_animPosDraw(
					main.t_selStages[main.t_selectableStages[((stageListNo - n - 1 - StartNumbers[currentStageRow]) % (NumStages[currentStageRow])) + 1 + StartNumbers[currentStageRow]]].anim_data,
					(backupPos[1] + motif.select_info.stage_portrait_offset[1] - (n * motif.select_info.stage_spacing[1]))  + ( (stageSlideHor / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[1] * slideHorDir),
					backupPos[2] + motif.select_info.stage_portrait_offset[2]
				)
			end
		end
		for n = 1, motif.select_info['stage_fp_main_down'] or 0 do
			if currentStageRow + n > totalRows then
				if (currentStageRow + n) % (totalRows + 1) == 0 then
					main.f_animPosDraw(
						motif.select_info.stage_portrait_random_data,
						0,
						((n * motif.select_info.stage_spacing[2])) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
					)
				else
					main.f_animPosDraw(
						main.t_selStages[main.t_selectableStages[hoverStages[(currentStageRow - n) % #NumStages + 1]]].anim_data,
						backupPos[1] + motif.select_info.stage_portrait_offset[1],
						(backupPos[2] + motif.select_info.stage_portrait_offset[2] + (n * motif.select_info.stage_spacing[2])) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
					)
				end
			else
				main.f_animPosDraw(
					main.t_selStages[main.t_selectableStages[hoverStages[currentStageRow + n]]].anim_data,
					backupPos[1] + motif.select_info.stage_portrait_offset[1],
					(backupPos[2] + motif.select_info.stage_portrait_offset[2] + (n * motif.select_info.stage_spacing[2])) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
				)
			end
		end
		for n = 1, motif.select_info['stage_fp_main_up'] or 0 do
			if currentStageRow - n <= 0 then
				--print((currentStageRow - n) % (totalRows + 1))
				if (currentStageRow - n) % (totalRows + 1) == 0 then
					main.f_animPosDraw(
						motif.select_info.stage_portrait_random_data,
						0,
						(-(n * motif.select_info.stage_spacing[2])) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
					)
				else
					main.f_animPosDraw(
						main.t_selStages[main.t_selectableStages[hoverStages[(currentStageRow - n) % #NumStages + 1]]].anim_data,
						backupPos[1] + motif.select_info.stage_portrait_offset[1],
						(backupPos[2] + motif.select_info.stage_portrait_offset[2] - (n * motif.select_info.stage_spacing[2])) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
					)
				end
			else
				main.f_animPosDraw(
					main.t_selStages[main.t_selectableStages[hoverStages[currentStageRow - n]]].anim_data,
					backupPos[1] + motif.select_info.stage_portrait_offset[1],
					(backupPos[2] + motif.select_info.stage_portrait_offset[2] - (n * motif.select_info.stage_spacing[2])) + ( (stageSlideVer / motif.select_info.stage_fp_slide_time) * motif.select_info.stage_spacing[2] * slideVerDir)
				)
			end
		end
		--draw stage name
		local t_txt = {}
		if stageListNo == 0 then
			t_txt[1] = motif.select_info.stage_random_text
		else
			local t = motif.select_info.stage_text:gsub('%%i', tostring(stageListNo))
			t = t:gsub('\n', '\\n')
			t = t:gsub('%%s', main.t_selStages[main.t_selectableStages[stageListNo]].name)
			for i, c in ipairs(main.f_strsplit('\\n', t)) do --split string using "\n" delimiter
				t_txt[i] = c
			end
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
		for i = 1, #t_txt do
			txt_selStage:update({
				font =   motif.select_info[stageActiveType .. '_font'][1],
				bank =   motif.select_info[stageActiveType .. '_font'][2],
				align =  motif.select_info[stageActiveType .. '_font'][3],
				text =   t_txt[i],
				x =      backupPos[1] + motif.select_info[stageActiveType .. '_offset'][1],
				y =      backupPos[2] + motif.select_info[stageActiveType .. '_offset'][2] + main.f_ySpacing(motif.select_info, stageActiveType) * (i - 1),
				scaleX = motif.select_info[stageActiveType .. '_scale'][1],
				scaleY = motif.select_info[stageActiveType .. '_scale'][2],
				r =      motif.select_info[stageActiveType .. '_font'][4],
				g =      motif.select_info[stageActiveType .. '_font'][5],
				b =      motif.select_info[stageActiveType .. '_font'][6],
				a =      motif.select_info[stageActiveType .. '_font'][7],
				height = motif.select_info[stageActiveType .. '_font'][8],
				xshear = motif.select_info[stageActiveType .. '_xshear'],
				angle  = motif.select_info[stageActiveType .. '_angle'],
			})
			txt_selStage:draw()
		end
		if stageSlideHor > 0 then
			stageSlideHor = stageSlideHor - 1
		end
		if stageSlideVer > 0 then
			stageSlideVer = stageSlideVer - 1
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
end
