require_relative 'datapack'

def send_keep_alive(fields = {})
	puts 'Sending Keep Alive (0x00)' if !fields.has_key?(:squelch) 
	@socket.write(byte(0x00) + int(0))
end

def send_login_request(fields = {})
	puts "Sending Login Request (0x01) #{fields.inspect}"
	@socket.write(byte(0x01) + int(fields[:protocol_version]) + string(fields[:username]) + long(0) + string('') + int(0) + byte(0) + byte(0) + unsigned_byte(0) + unsigned_byte(0))
end

def send_handshake(fields = {})
	puts "Sending Handshake (0x02) #{fields.inspect}"
	@socket.write(byte(0x02) + string(fields[:username]))
end

def send_chat_message(fields = {})
	puts "Sending Chat Message (0x03) #{fields.inspect}"
	@socket.write(byte(0x03) + string(fields[:message]))
end

def send_respawn(fields = {dimension: 0, difficulty: 1, game_mode: 0, world_height: 128, map_seed: 0, level_type: 'DEFAULT'})
	puts "Sending Respawn (0x09) #{fields.inspect}"
	@socket.write(byte(0x09) + byte(fields[:dimension]) + byte(fields[:difficulty]) + byte(fields[:game_mode]) + short(fields[:world_height]) + long(fields[:map_seed]) + string(fields[:level_type]))
end

def send_player_position_and_look(fields = {})
	puts "Sending Player Position & Look (0x0D) #{fields.inspect}" if !fields.has_key?(:squelch) 
	@socket.write(byte(0x0D) + double(fields[:x]) + double(fields[:y]) + double(fields[:stance]) + double(fields[:z]) + float(fields[:yaw]) + float(fields[:pitch]) + byte(fields[:on_ground]))
end

@prev_packet_hex = nil

def receive_packet(opts = {})
	fields = {}
	packet = read_unsigned_byte
	packet_hex = '0x%02X' % packet

	case packet
	when 0x00
		packet_name = 'Keep Alive'
		fields[:keep_alive_id] = read_int
	when 0x01
		packet_name = 'Login Request'
		fields[:eid] = read_int
		read_string
		fields[:map_seed] = read_long
		fields[:level_type] = read_string
		fields[:game_mode] = read_int
		fields[:dimension] = read_byte
		fields[:difficulty] = read_byte
		fields[:world_height] = read_unsigned_byte
		fields[:max_players] = read_unsigned_byte
	when 0x02
		packet_name = 'Handshake'
		fields[:connection_hash] = read_string
	when 0x03
		packet_name = 'Chat Message'
		fields[:message] = read_string
	when 0x04
		packet_name = 'Time Update'
		fields[:time] = read_long
	when 0x05
		packet_name = 'Entity Equipment'
		fields[:eid] = read_int
		fields[:slot] = read_short
		fields[:item_id] = read_short
		fields[:damage] = read_short
	when 0x06
		packet_name = 'Spawn Position'
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
	when 0x08
		packet_name = 'Update Health'
		fields[:health] = read_short
		fields[:food] = read_short
		fields[:food_saturation] = read_float
	when 0x09
		packet_name = 'Respawn'
		fields[:dimension] = read_byte
		fields[:difficulty] = read_byte
		fields[:game_mode] = read_byte
		fields[:world_height] = read_short
		fields[:map_seed] = read_long
		fields[:level_type] = read_string
	when 0x0D
		packet_name = 'Player Position & Look'
		fields[:x] = read_double
		fields[:stance] = read_double
		fields[:y] = read_double
		fields[:z] = read_double
		fields[:yaw] = read_float
		fields[:pitch] = read_float
		fields[:on_ground] = read_byte
	when 0x11
		packet_name = 'Use Bed'
		fields[:eid] = read_int
		read_byte
		fields[:x] = read_int
		fields[:y] = read_byte
		fields[:z] = read_int
	when 0x12
		packet_name = 'Animation'
		fields[:eid] = read_int
		fields[:animation] = read_byte
	when 0x14
		packet_name = 'Named Entity Spawn'
		fields[:eid] = read_int
		fields[:player_name] = read_string
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:rotation] = read_byte
		fields[:pitch] = read_byte
		fields[:current_item] = read_short
	when 0x15
		packet_name = 'Pickup Spawn'
		fields[:eid] = read_int
		fields[:item] = read_short
		fields[:count] = read_byte
		fields[:damage] = read_short
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:rotation] = read_byte
		fields[:pitch] = read_byte
		fields[:roll] = read_byte
	when 0x16
		packet_name = 'Collect Item'
		fields[:collected_eid] = read_int
		fields[:collector_eid] = read_int
	when 0x17
		packet_name = 'Add Object/Vehicle'
		fields[:eid] = read_int
		fields[:type] = read_byte
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:fireball_thrower_eid] = read_int
		if fields[:fireball_thrower_eid] != 0
			fields[:fireball_speed_x] = read_short
			fields[:fireball_speed_y] = read_short
			fields[:fireball_speed_z] = read_short
		end
	when 0x18
		packet_name = 'Mob Spawn'
		fields[:eid] = read_int
		fields[:type] = read_byte
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:yaw] = read_byte
		fields[:pitch] = read_byte
		fields[:metadata] = read_metadata
	when 0x19
		packet_name = 'Painting'
		fields[:eid] = read_int
		fields[:title] = read_string
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:direction] = read_int
	when 0x1A
		packet_name = 'Experience Orb'
		fields[:eid] = read_int
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:count] = read_short
	when 0x1C
		packet_name = 'Entity Velocity'
		fields[:eid] = read_int
		fields[:velocity_x] = read_short
		fields[:velocity_y] = read_short
		fields[:velocity_z] = read_short
	when 0x1D
		packet_name = 'Destroy Entity'
		fields[:eid] = read_int
	when 0x1F
		packet_name = 'Entity Relative Move'
		fields[:eid] = read_int
		fields[:dx] = read_byte
		fields[:dy] = read_byte
		fields[:dz] = read_byte
	when 0x20
		packet_name = 'Entity Look'
		fields[:eid] = read_int
		fields[:yaw] = read_byte
		fields[:pitch] = read_byte
	when 0x21
		packet_name = 'Entity Look and Relative Move'
		fields[:eid] = read_int
		fields[:dx] = read_byte
		fields[:dy] = read_byte
		fields[:dz] = read_byte
		fields[:yaw] = read_byte
		fields[:pitch] = read_byte
	when 0x22
		packet_name = 'Entity Teleport'
		fields[:eid] = read_int
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
		fields[:yaw] = read_byte
		fields[:pitch] = read_byte
	when 0x26
		packet_name = 'Entity Status'
		fields[:eid] = read_int
		fields[:status] = read_byte
	when 0x28
		packet_name = 'Entity Metadata'
		fields[:eid] = read_int
		fields[:metadata] = read_metadata
	when 0x2B
		packet_name = 'Experience'
		fields[:experience_bar] = read_float
		fields[:level] = read_short
		fields[:total_experience] = read_short
	when 0x32
		packet_name = 'Pre-Chunk'
		fields[:x] = read_int
		fields[:z] = read_int
		fields[:mode] = read_byte
	when 0x33
		packet_name = 'Map Chunk'
		fields[:x] = read_int
		fields[:y] = read_short
		fields[:z] = read_int
		fields[:size_x] = read_byte
		fields[:size_y] = read_byte
		fields[:size_z] = read_byte
		fields[:compressed_size] = read_int
		fields[:compressed_data] = @socket.read(fields[:compressed_size])
	when 0x34
		packet_name = 'Multi Block Change'
		fields[:chunk_x] = read_int
		fields[:chunk_z] = read_int
		fields[:count] = read_short
		fields[:coordinate_array] = []
		fields[:type_array] = []
		fields[:metadata_array] = []
		for i in 1..fields[:count]
			fields[:coordinate_array] << read_short
		end
		for i in 1..fields[:count]
			fields[:type_array] << read_byte
		end
		for i in 1..fields[:count]
			fields[:metadata_array] << read_byte
		end
	when 0x35
		packet_name = 'Block Change'
		fields[:x] = read_int
		fields[:y] = read_byte
		fields[:z] = read_int
		fields[:block_type] = read_byte
		fields[:block_metadata] = read_byte
	when 0x36
		packet_name = 'Block Action'
		fields[:x] = read_int
		fields[:y] = read_short
		fields[:z] = read_int
		fields[:byte_1] = read_byte
		fields[:byte_2] = read_byte
	when 0x3D
		packet_name = 'Sound/Particle Effect'
		fields[:effect_id] = read_int
		fields[:x] = read_int
		fields[:y] = read_byte
		fields[:z] = read_int
		fields[:data] = read_int	
	when 0x46
		packet_name = 'New/Invalid State'
		fields[:reason] = read_byte
		fields[:game_mode] = read_byte
	when 0x47
		packet_name = 'Thunderbolt'
		fields[:eid] = read_int
		read_byte
		fields[:x] = read_int
		fields[:y] = read_int
		fields[:z] = read_int
	when 0x67
		packet_name = 'Set Slot'
		fields[:window_id] = read_byte
		fields[:slot] = read_short
		fields[:slot_data] = read_slot
	when 0x68
		packet_name = 'Window Items'
		fields[:window_id] = read_byte
		fields[:count] = read_short
		fields[:slot_data_array] = []
		for i in 1..fields[:count]
			fields[:slot_data_array] << read_slot
		end
	when 0xC8
		packet_name = 'Increment Statistic'
		fields[:statistic_id] = read_int
		fields[:amount] = read_byte
	when 0xC9
		packet_name = 'Player List Item'
		fields[:player_name] = read_string
		fields[:online] = read_byte
		fields[:ping] = read_short
	when 0x82
		packet_name = 'Update Sign'
		fields[:x] = read_int
		fields[:y] = read_short
		fields[:z] = read_int
		fields[:text1] = read_string
		fields[:text2] = read_string
		fields[:text3] = read_string
		fields[:text4] = read_string
	when 0xFF
		packet_name = 'Disconnect/Kick'
		fields[:reason] = read_string
	else
		send_chat_message(message: "WHAT'S #{packet_hex} PRECIOUSSS")
		raise "Received unrecognized packet (#{packet_hex}); previous packet was #{@prev_packet_hex}"
		return
	end

	if (!opts.has_key?(:whitelist) || opts[:whitelist].include?(packet)) && (!opts.has_key?(:blacklist) || !opts[:blacklist].include?(packet))
		puts "Received #{packet_name} (#{packet_hex}) #{fields.inspect}"
	end

	handler_sym = "handler_#{packet_hex}".to_sym
	opts[handler_sym].call(fields) if opts.has_key?(handler_sym)

	@prev_packet_hex = packet_hex
end