if script.active_mods["gvv"] then require("__gvv__.gvv")() end
-- Setup tables and stuff for new/existing saves ----
script.on_init(
	require("script.event.init")
)

-- game version changes, prototypes change, startup mod settings change, and any time mod versions change including adding or removing mods
script.on_configuration_changed(
	require("script.event.config_changed")
)

---- Add new players to the AllPlayers table ----
script.on_event(
	defines.events.on_player_created,
	require("script.event.player_created")
)

-- On Built/Copy/Stuff

---- adds new thrower inserters to the list of throwers to check.
---- Make player launchers (reskinned inserters) to be inoperable
---- and inactive ----
script.on_event(
	{
		defines.events.on_built_entity, --| built by hand ----
		defines.events.on_robot_built_entity, --| built by robot ----
		defines.events.script_raised_built, --| built by script ----
		defines.events.on_entity_cloned, -- | cloned by script ----
		defines.events.script_raised_revive, -- | ghost revived by script
	},
	require("script.event.entity_built")
)


-- On Rotate
script.on_event(
	defines.events.on_player_rotated_entity,
	require("script.event.rotate")
)


-- Thrower Range blueprint auto build cancel
script.on_event(defines.events.on_player_cursor_stack_changed, -- only has .player_index
function(event)
if (global.AllPlayers[event.player_index].RangeAdjusting == true) then
	global.AllPlayers[event.player_index].RangeAdjusting = nil
end
end)


-- Clear invalid things
script.on_nth_tick(300,
function(event)
	for unitID, ItsStuff in pairs(global.BouncePadList) do
		if (ItsStuff.TheEntity and ItsStuff.TheEntity.valid) then
			-- it's good
		else
			global.BouncePadList[unitID] = nil
		end
	end

	for unitID, ItsStuff in pairs(global.MagnetRamps) do
		if (ItsStuff.entity and ItsStuff.entity.valid) then
			-- it's good
		else
			global.MagnetRamps[unitID] = nil
		end
	end

	for each, world in pairs(game.surfaces) do
		for every, ZiplinePart in pairs(world.find_entities_filtered{name = {"RTZipline", "RTZiplinePowerDrain"}}) do
			local owned = false
			for all, player in pairs(global.AllPlayers) do
				if ((player.ChuggaChugga and ZiplinePart.unit_number == player.ChuggaChugga.unit_number)
				or  (player.succ and ZiplinePart.unit_number == player.succ.unit_number)
				) then
					owned = true
				end
			end
			if (owned == false) then
				ZiplinePart.destroy()
			end
		end
	end
end)

-- Thrower Check
---- checks if thrower inserters have something in their hands and it's in the throwing position, then creates the approppriate projectile ----
script.on_nth_tick(3,
function(event)
	if (global.CatapultList ~= {}) then
		for catapultID, properties in pairs(global.CatapultList) do

			local catapult = properties.entity

			BurnerSelfRefuelCompensation = 0.2
			if (catapult.valid and catapult.burner == nil and catapult.fluidbox == nil and catapult.energy/catapult.electric_buffer_size >= 0.9) then
				catapult.active = true
				BurnerSelfRefuelCompensation = 0
			elseif (catapult.valid and catapult.burner == nil and catapult.fluidbox == nil) then
				catapult.active = false
				rendering.draw_sprite
					{
						sprite = "utility.electricity_icon_unplugged",
						x_scale = 0.5,
						y_scale = 0.5,
						target = catapult,
						surface = catapult.surface,
						time_to_live = 4
					}
			end

			if (catapult.valid and catapult.held_stack.valid_for_read) then
				if (settings.global["RTOverflowComp"].value == true) then
					-- pointing at some entity
					if (properties.target ~= "nothing" and properties.target.valid and global.OnTheWay[properties.target.unit_number]) then
					 	if (properties.target.type ~= "transport-belt" and global.OnTheWay[properties.target.unit_number][catapult.held_stack.name]) then
							local total = global.OnTheWay[properties.target.unit_number][catapult.held_stack.name] + catapult.held_stack.count
							local inserted = properties.target.insert({name=catapult.held_stack.name, count=total})
							if (inserted < total) then
								catapult.active = false
							else
								catapult.active = true
							end
							if (inserted > 0) then -- when the destination is full. Have to check otherwise there's an error
								properties.target.remove_item({name=catapult.held_stack.name, count=inserted})
							end

						elseif (properties.target.type == "transport-belt"
					 	and (properties.target.get_transport_line(1).can_insert_at_back() == true
					 		 or properties.target.get_transport_line(2).can_insert_at_back() == true)
					 	) then
					 		local incomming = 0
							for name, count in pairs(global.OnTheWay[properties.target.unit_number]) do
								incomming = incomming + count
							end
					 		local total = incomming + properties.target.get_transport_line(1).get_item_count() + properties.target.get_transport_line(2).get_item_count()
					 		if (total <= 6) then
					 			catapult.active = true
					 		else
					 			catapult.active = false
					 		end
					 	end
					-- pointing at nothing/the ground
					elseif (properties.target == "nothing") then
					 	catapult.active = true
					end
				else
					catapult.active = true
				end

				if (catapult.active == true) then
					if (catapult.orientation == 0    and catapult.held_stack_position.y >= catapult.position.y+BurnerSelfRefuelCompensation)
					or (catapult.orientation == 0.25 and catapult.held_stack_position.x <= catapult.position.x-BurnerSelfRefuelCompensation)
					or (catapult.orientation == 0.50 and catapult.held_stack_position.y <= catapult.position.y-BurnerSelfRefuelCompensation)
					or (catapult.orientation == 0.75 and catapult.held_stack_position.x >= catapult.position.x+BurnerSelfRefuelCompensation)
					then
						local sprite = rendering.draw_sprite
							{
								sprite = "item/"..catapult.held_stack.name,
								x_scale = 0.5,
								y_scale = 0.5,
								target = catapult.held_stack_position,
								surface = catapult.surface
							}
						local shadow = rendering.draw_sprite
							{
								sprite = "item/"..catapult.held_stack.name,
								tint = {0,0,0,0.5},
								x_scale = 0.5,
								y_scale = 0.5,
								target = catapult.held_stack_position,
								surface = catapult.surface
							}
						local	x = catapult.drop_position.x
						local y = catapult.drop_position.y
						local start=catapult.held_stack_position
						local distance = math.sqrt((x-catapult.held_stack_position.x)^2 + (y-catapult.held_stack_position.y)^2)
						local vector = {x=x-catapult.held_stack_position.x, y=y-catapult.held_stack_position.y}
						local speed = 0.18
						if (catapult.name == "RTThrower-EjectorHatchRT") then
							distance = math.sqrt((x-catapult.position.x)^2 + (y-catapult.position.y)^2)
							vector = {x=x-catapult.position.x, y=y-catapult.position.y}
							start=catapult.position
							speed = 0.25
							rendering.set_target(sprite, catapult.position)
							rendering.set_target(shadow, catapult.position)
						end
						local arc = -(0.3236*distance^-0.404)-- closer to 0 = higher arc
						local AirTime = math.floor(distance/speed)
						local spin = math.random(-10,10)*0.01
						local destination = nil
						if (settings.global["RTOverflowComp"].value == true) then
							if (properties.target ~= "nothing" and properties.target.valid) then
								destination = properties.target.unit_number
								if (global.OnTheWay[properties.target.unit_number] == nil) then
									global.OnTheWay[properties.target.unit_number] = {}
									global.OnTheWay[properties.target.unit_number][catapult.held_stack.name] = catapult.held_stack.count
								elseif (global.OnTheWay[properties.target.unit_number][catapult.held_stack.name] == nil) then
									global.OnTheWay[properties.target.unit_number][catapult.held_stack.name] = catapult.held_stack.count
								else
									global.OnTheWay[properties.target.unit_number][catapult.held_stack.name] = global.OnTheWay[properties.target.unit_number][catapult.held_stack.name] + catapult.held_stack.count
								end
							end
						end
						global.FlyingItems[global.FlightNumber] =
							{sprite=sprite,
							shadow=shadow,
							speed=speed,
							arc=arc,
							spin=spin,
							item=catapult.held_stack.name,
							amount=catapult.held_stack.count,
							target={x=x, y=y},
							start=start,
							AirTime=AirTime,
							StartTick=game.tick,
							LandTick=game.tick+AirTime,
							vector=vector,
							destination=destination}
						global.FlightNumber = global.FlightNumber + 1
						catapult.held_stack.clear()
					end
				end
			elseif (catapult.valid and catapult.held_stack.valid_for_read == false) then
				catapult.active = true
			elseif (catapult.valid == false) then
				global.CatapultList[catapultID] = nil

			end
		end
	end
end)

script.on_nth_tick(120,
function(event)
	if (settings.global["RTOverflowComp"].value == true) then
		for catapultID, properties in pairs(global.CatapultList) do
			if (properties.ImAlreadyTracer == nil or properties.ImAlreadyTracer == "traced") then
				properties.ImAlreadyTracer = "tracing"
				local sprite = rendering.draw_sprite
					{
						sprite = "RTBlank",
						target = properties.entity.position,
						surface = properties.entity.surface
					}
				local shadow = rendering.draw_sprite
					{
						sprite = "RTBlank",
						target = properties.entity.position,
						surface = properties.entity.surface
					}
				local	x = properties.entity.drop_position.x
				local y = properties.entity.drop_position.y
				local speed = 999
				local arc = -5 -- lower number is higher arc
				local AirTime = 1
				local vector = {x=x-properties.entity.position.x, y=y-properties.entity.position.y}
				local spin = 0
				global.FlyingItems[global.FlightNumber] =
					{sprite=sprite,
					shadow=shadow,
					speed=speed,
					arc=arc,
					spin=spin,
					item="tracer",
					amount=420,
					target={x=x, y=y},
					start=properties.entity.position,
					AirTime=AirTime,
					StartTick=game.tick,
					LandTick=game.tick+AirTime,
					vector=vector,
					tracing = properties.entity.unit_number}
				global.FlightNumber = global.FlightNumber + 1
			end
		end
	else
	--dont
	end
end)

-- Projectile Lands
-- When a projectile lands and its effect_id is triggered, what to do ----
script.on_event(
	defines.events.on_script_trigger_effect,
	require("script.event.effect_triggered")
)

-- Animating/On Tick
script.on_nth_tick(
	1,
	require("script.event.on_tick")
)

-- On Damaged
script.on_event(
	defines.events.on_entity_damaged,
	require("script.event.entity_damaged")
)

-- On Interact
script.on_event(
	"RTInteract",
	require("script.event.interact")
)

-- On Click
script.on_event(
	"RTClick",
	require("script.event.click")
)

script.on_event(
	defines.events.on_entity_destroyed,
	require("script.event.entity_destroyed")
)


script.on_event(defines.events.on_player_changed_surface,
-- .player_index :: uint: The player who changed surfaces
-- .surface_index :: uint: The surface index the player was on
function(event)
local player = game.players[event.player_index]
	if (global.AllPlayers[event.player_index] and global.AllPlayers[event.player_index].sliding and global.AllPlayers[event.player_index].sliding == true and player.surface.name ~= global.AllPlayers[event.player_index].StartingSurface.name) then
		player.teleport(player.position, game.get_surface(event.surface_index))
	end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed,
-- player_index :: uint (optional): The player who changed the setting or nil if changed by script.
-- setting :: string: The setting name that changed.
-- setting_type :: string: The setting type: "runtime-per-user", or "runtime-global".
function(event)
	if (event.setting == "RTOverflowComp" and settings.global["RTOverflowComp"].value == false) then
		global.OnTheWay = {}
	end
end)

-- script.on_event(defines.events.on_player_driving_changed_state,
-- -- player_index :: uint
-- -- entity :: LuaEntity (optional): The vehicle if any.
-- function(event)
-- 	local player = game.players[event.player_index]
-- 	if (player.character and player.driving == false) then
-- 		for each, properties in pairs(global.FlyingTrains) do
-- 			if (properties.passenger and properties.passenger.unit_number == player.character.unit_number) then
-- 				properties.GuideCar.set_passenger(player)
-- 			end
-- 		end
-- 	end
-- end)
