--[[ 
 ==================================--
 Flats Mini-game (flatsMG) by CoreLogic 2015
 =================================--
  A simple game of shooting tires for $$. 
   - $100 each tire
   - $1000 all four
   
  This is a work in progress, there is a delay when registering a hit. I am working to resolve this issue and add new features. 
  
  I am new to Lua, any suggestions on performance, or code improvements are welcome. 
 
  This code is free to use and share, but please give credit and good will. (CoreLogic http://www.developer-me.com/forums/member.php?action=profile&uid=29)
  
  A big thanks to ZyDevs for all the help and support providing a direction and example code. 
    - Visit his Forum for modding info and download the  GTA V Mod Creator by ZyDevs http://www.developer-me.com/forums/index.php
	
 Github: https://github.com/adestefa/flatsMiniGame.git	
 
 
 Installation:
	1. Install Script Hook https://www.gta5-mods.com/tools/script-hook-v 
	2. Install the LUA script plugin for Scripthook https://www.gta5-mods.com/tools/lua-plugin-for-script-hook-v 
	3. Download the flatsMiniGame file
	4. Put the <b>flatsMiniGame.lua</b> file in your <install dir>\Grand Theft Auto V\scripts\addins folder. 
	5. Text will appear over the mini-map when installed correctly:  [F8] To start Flats mini-game

 
 -------------------------------
 version 0.7 7/17/2015
  - base version  
	

]]--
local flatsMG = {}
-- ============ --
-- Globals 
-- ============ --
local run = false;    -- run the mini-game
local range = 1000;   -- range of cars to check
local setup = false;  -- did we set up the player?
local seenFlats = {}  -- flats we counted (TODO)
local score = 0;     
-- =================== --
-- draw text to screen
-- =================== --
function flatsMG.draw_text(text, x, y, scale)
	UI.SET_TEXT_FONT(0);
	UI.SET_TEXT_SCALE(scale, scale);
	UI.SET_TEXT_COLOUR(255, 255, 255, 255);
	UI.SET_TEXT_WRAP(0.0, 1.0);
	UI.SET_TEXT_CENTRE(false);
	UI.SET_TEXT_DROPSHADOW(2, 2, 0, 0, 0);
	UI.SET_TEXT_EDGE(1, 0, 0, 0, 205);
	UI._SET_TEXT_ENTRY("STRING");
	UI._ADD_TEXT_COMPONENT_STRING(text);
	UI._DRAW_TEXT(y, x);
end
-- ========================== --
-- extra message display area
-- ========================== --
function flatsMG.displayHitText(txt)
	flatsMG.draw_text(txt, 0.5, 0.0005, 0.3);
end
-- ============================================== --
-- play a sound 
-- (where do we find a list of game sound hashes??)
-- ============================================== --
function flatsMG.playSound()
	AUDIO.PLAY_SOUND_FRONTEND(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true);
end
-- =============== --
-- Give player cash
-- =============== --
function flatsMG.giveMoney(amount)
  local playerPosition = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false);
  OBJECT.CREATE_AMBIENT_PICKUP(GAMEPLAY.GET_HASH_KEY("PICKUP_MONEY_VARIABLE"), playerPosition.x, playerPosition.y, playerPosition.z, 0, amount, 1, false, true);
end
-- ============================================================= --
-- set the player up on the map with abilities to play the game
-- ============================================================= --
function flatsMG.set()
	local spawnX = {209.620}
	local spawnY = {203.181}
	local spawnZ = {105.562}
	local spawnH = {225}
	local player = PLAYER.PLAYER_PED_ID(); 
	PLAYER.SET_PLAYER_MODEL(player, GAMEPLAY.GET_HASH_KEY(mp_m_niko_01));
	ENTITY.SET_ENTITY_COORDS(player, 209.620, 203.181, 105.562, true, true, true, true);
	PED.SET_PED_ARMOUR(player, 100);
	ENTITY.SET_ENTITY_MAX_SPEED(player, 500);
	ENTITY.SET_ENTITY_INVINCIBLE(player, true);
	ENTITY.SET_ENTITY_HEALTH(player, 200);
	PLAYER.CLEAR_PLAYER_WANTED_LEVEL(player);
	setup = true; -- remember if we set the player up
	seenFlats = {};
end
-- ===================================================================================== --
-- store each flat as (vehicleID + index) = vehicleID++
-- here we need to store 4 bits plus the vehicle ID to track each tire per car
-- to keep the data structure flat, simply apply
-- a rule of adding the tire position value to the ID
-- this gives us a unique new number "hash" for each flat we can check for during runtime
-- ======================================================================================= --
function flatsMG.isNewFlat(v, index) 
	local needle = v + index; -- add tire index position to v id value (increments)
	for i=1,#seenFlats do
	    -- does this value match v + tire index already stored?
		if(seenFlats[i] == needle) then
		   return true;
	    end  
	end
	return false;
end
-- ================================== --
-- Have we already counted this flat?
-- ================================== --
function checkSeen(vehicle, index)
	if (not flatsMG.isNewFlat(vehicle, index)) then
		flatsMG.playSound();
		local tmp = vehicle + 1;
		table.insert(seenFlats,tmp);
		flatsMG.giveMoney(1);
	end   

end
-- ======================================= --
-- print flat data to console for debugging
-- ======================================= --
function flatsMG.printSeenFlats()
	--for k,v in ipairs(seenFlats) do
		--print(k,v);
	--end
	for i=1,#seenFlats do
	  print(i,seenFlats[i])
	end
	flatsMG.displayHitText("Flats printed to console");
end
-- ============ --
-- Do the work!
-- ============ --
function flatsMG.tick()
	local playerPed = PLAYER.PLAYER_PED_ID();
	local PedTab,PedCount = PED.GET_PED_NEARBY_PEDS(playerPed, 100, 100);
	local VehTab,VehCount = PED.GET_PED_NEARBY_VEHICLES(playerPed, 1);
 
	-- =============================================== --
	-- print seen flats table to console using 'p' key
	-- =============================================== --
	if(get_key_pressed(80)) then --p key	
		flatsMG.printSeenFlats()
		wait(1500);
	end	
	
	
	-- ============================ --
	-- toggle 'run' state with F8 key
	-- ============================ --
	if(get_key_pressed(119)) then --# F8 key
		if run then
		   run = false;
		else
		   run = true;
		end
		wait(1000)
	end
	
	
	-- ============== --
	-- let's do this!	
	-- ============== --
	if run then
		
		-- make sure we are in correct position and player init is complete
		if (not setup) then
			flatsMG.set()
		end
		
		-- this does most of the work here, and has limitations
		-- It finds only peds in cars (saving a sub query when getting just peds)
		-- but, the radius that it searches to get the list is small compared to PED.GET_PED_NEARBY_PEDS
		-- The challenge using PED.GET_PED_NEARBY_PEDS is it requires two queries to find the cars, then the 4 tires
		-- this has shown to crash the game after playing some time, especially when there is a lot of traffic. 
		-- To avoid this we stick with GET_PED_NEARBY_VEHICLES which is faster but limited to close range ;-(
		-- **any help here or suggestions would be welcome!**
		local Table,Count = PED.GET_PED_NEARBY_VEHICLES(playerPed, 1)
		
		-- ============================================================ --
		-- set a simple display UI above the mini-map. 
		flatsMG.draw_text("Flats mini-game v0.7", 0.7, 0.0005, 0.3);
		flatsMG.draw_text("======================", 0.72, 0.0005, 0.3);
		flatsMG.draw_text("$100 per flat", 0.74, 0.0005, 0.3);
		flatsMG.draw_text("$1000 all four", 0.76, 0.0005, 0.3);
		flatsMG.draw_text("Nearby Peds:"..Count, 0.78, 0.0005, 0.3);
		flatsMG.draw_text("Press [F8] to exit", 0.8, 0.0005, 0.3);
		-- ============================================================ --
		
		-- Initialize count for this search
		local totalFlatsThisCheck = 0
		
		-- ==================================== --	
		-- iterate over all nearby peds in cars
		-- ==================================== --	
		for k,vehicle in ipairs(Table)do 
				-- flats for this car
				local count = 0;
						
				-- check tire 1 
				if VEHICLE.IS_VEHICLE_TYRE_BURST(vehicle, 1, true) then
					count = count + 1;
					flatsMG.draw_text(vehicle.." Hit tire 1 $100!", 0.5, 0.0005, 0.3);
					--print(vehicle.." Hit tire 1 "..vehicle);
					
				end
						
				-- check tire 2 
				if VEHICLE.IS_VEHICLE_TYRE_BURST(vehicle, 2, true) then
					count = count + 1;
					flatsMG.draw_text(vehicle.." Hit tire 2 $100!", 0.54, 0.0005, 0.3);
					--print(vehicle.." Hit tire 2 "..vehicle);
				
			    end
						
				-- check tire 3 
				if VEHICLE.IS_VEHICLE_TYRE_BURST(vehicle, 3, true) then
					count = count + 1;
					flatsMG.draw_text(vehicle.." Hit tire 3 $100!", 0.56, 0.0005, 0.3);
					--print(vehicle.." Hit tire 3 "..vehicle);
					
				end
						
				-- check tire 4 
				if VEHICLE.IS_VEHICLE_TYRE_BURST(vehicle, 4, true) then
					count = count + 1;
					flatsMG.draw_text(vehicle.." Hit tire 4  $100!", 0.59, 0.0005, 0.3);	
					--print(vehicle.." Hit tire 4 "..vehicle);
					
				end
				
				-- ======================================= --		
				-- Scoring, we only care if we found flats
				-- ======================================= --	
				if (count > 0) then
					-- give player reward
					local playerPosition = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false);
					OBJECT.CREATE_AMBIENT_PICKUP(GAMEPLAY.GET_HASH_KEY("PICKUP_MONEY_VARIABLE"), playerPosition.x, playerPosition.y, playerPosition.z, 0, count*100, 1, false, true);
					flatsMG.playSound();	
							
					-- Give the player a grand and blow up the car if they pop all four tires
					if (count == 4) then
						VEHICLE.EXPLODE_VEHICLE(vehicle, true, true);
						flatsMG.draw_text(vehicle.." All 4 tires $1000!", 0.56, 0.0005, 0.3);
						local playerPosition = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false);
						OBJECT.CREATE_AMBIENT_PICKUP(GAMEPLAY.GET_HASH_KEY("PICKUP_MONEY_VARIABLE"), playerPosition.x, playerPosition.y, playerPosition.z, 0, 1000, 1, false, true);
					end
						
				end
				-- add to running total over all cars this check
				totalFlatsThisCheck = totalFlatsThisCheck + count;
		end
		-- save flat search results to score 
		if(totalFlatsThisCheck > 0) then
			score = score + totalFlatsThisCheck;
		end
		flatsMG.draw_text("SCORE:"..score, 0.0, 0.09, 0.3) 	
	
	
	-- ============================================================== --
	-- show game UI display above mini-map telling user how to start
	-- ============================================================== --
	else 
		flatsMG.draw_text("[F8] To start Flats mini-game v0.7", 0.8, 0.0005, 0.3);
	end
end

function flatsMG.unload()
end

return flatsMG