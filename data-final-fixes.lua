function MakeProjectile(ThingData)
  
if not (ThingData.icon) then
ThingData.icon = "__RenaiTransportation__/graphics/icon.png"
ThingData.icon_size = 32
end
  
TheProjectile = table.deepcopy(data.raw.stream["acid-stream-spitter-small"])
	TheProjectile.name = ThingData.name.."-projectileFromRenaiTransportation"
	TheProjectile.special_neutral_target_damage = {amount = 0, type = "acid"}
	--TheProjectile.scale = 5     --does nothing as far as i can tell
	--TheProjectile.particle_buffer_size = 90
    TheProjectile.particle_spawn_interval = 0
    TheProjectile.particle_spawn_timeout = 0
    TheProjectile.particle_vertical_acceleration = 0.0035 -- gravity, default 0.0045
    TheProjectile.particle_horizontal_speed = 0.18 -- speed, default 0.3375
    --TheProjectile.particle_horizontal_speed_deviation = 0.005 * 0.70
    --TheProjectile.particle_start_alpha = 0.5
    --TheProjectile.particle_end_alpha = 1
    --TheProjectile.particle_alpha_per_part = 0.8
    --TheProjectile.particle_scale_per_part = 0.8
    --TheProjectile.particle_loop_frame_count = 15
    --TheProjectile.particle_fade_out_duration = 2
    --TheProjectile.particle_loop_exit_threshold = 0.25
	
	TheProjectile.working_sound = nil
	
	TheProjectile.initial_action =
	  {
		type = "direct",
		action_delivery =
		{
		  type = "instant",
		  target_effects =
		  {
			{
			  type = "script",
			  effect_id = ThingData.name.."-LandedRT"
			}
		  }
		}
	  }

	TheProjectile.particle = {
      filename = ThingData.icon,
      line_length = 1,
      width = ThingData.icon_size,
      height = ThingData.icon_size,
      frame_count = 1,
      --shift = util.mul_shift(util.by_pixel(-2, 30), data.scale),
      --tint = data.tint,
      priority = "high",
      scale = 0.3,
      --animation_speed = 1,
      hr_version =
      {
        filename = ThingData.icon,
        line_length = 1,
        width = ThingData.icon_size,
        height = ThingData.icon_size,
        frame_count = 1,
        --shift = util.mul_shift(util.by_pixel(-2, 31), data.scale),
        --tint = data.tint,
        priority = "high",
        scale = 0.3,
        --animation_speed = 1,
      }
    }
	TheProjectile.spine_animation = nil
	

	data:extend({TheProjectile})
end

for Category, ThingsTable in pairs(data.raw) do
	for ThingID, ThingData in pairs(ThingsTable) do
		if (ThingData.stack_size) then
			MakeProjectile(ThingData)
		end
	end
end

MakeProjectile(
	{
		name = "test",
		icon = "__RenaiTransportation__/graphics/nothing.png",
		icon_size = 32
	}
)
