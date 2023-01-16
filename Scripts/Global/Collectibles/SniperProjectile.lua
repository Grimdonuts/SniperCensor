function SniperProjectile(Ob)
	if (not Ob) then
		Ob = CreateObject('Prop')
		Ob.meshname = 'GlobalModels/GO_GlobalObjects/CensorBlast.plb'
		Ob.collideRadius = 30
		Ob.collideOffsetZ = -10
		Ob.damage = 4
		Ob.areaDamage = 1
		Ob.areaDamageRadius = 350
		Ob.bReflect = 0
		Ob.areaEffect = 1
		Ob.velocity = 2000
		Ob.bApplyGravity = 0
		Ob.showExplosionEffect = 1
		Ob.explosionFXName = 'Global.Effects.Censor2BlastFX'
		Ob.bCanKnockBackCensors = 1
		Ob.trailFXName = 'Global.Effects.CensorProjectileFX'
		Ob.knockBackDamage = 0.5
		Ob.TIMER_EXPIRE = '3000'	-- timer of how long the projectile will last
		Ob.timerLength = 6000		-- projectile will live this many millis after being launched
	end
	
--************************************************************************************************* 
-- GAME STATES
--*************************************************************************************************

	function Ob:onSpawn()
		self.sounds = {}
		self.sounds.launch = 'CensorSonicAttack'	
		self.sounds.hit = 'CensorProjectileHit'
		self.sounds.reflect = 'wrestler_block'
		%Ob.Parent.onSpawn(self)
	end

	function Ob:onBeginLevel()
		%Ob.Parent.onBeginLevel(self)
		self:loadMesh(self.meshname)
		if self.areaEffect == 1 then 
			self:createExplosion()
		end
		SetMeshIsBackwards(self,1)
		SetEntityCollideSphere(self, self.collideRadius, 0, 0 ,self.collideOffsetZ)
		SetEntityInterestLevel(self,0)
        self.sounds.launch = LoadSound(self.sounds.launch)
		self.sounds.hit = LoadSound(self.sounds.hit)
		self.sounds.reflect = LoadSound(self.sounds.reflect)
		
		-- projectiles should ignore each other
		SetCollideLayer(self, Global.CL_PROJECTILES, 1)
		IgnoreCollideLayer(self, Global.CL_PROJECTILES, 1)
		
		-- FX: get the pools and preload
		self.explosionFXPool = Global.levelScript:getPool(self.explosionFXName)
		self.explosionFXPool:setLowerLimit(1)

		self.trailFXPool = Global.levelScript:getPool(self.trailFXName)
		self.trailFXPool:setLowerLimit(1)
		
		self:resetEntity()
	end

	function Ob:resetEntity()
		self.bReflect = 0
		SetPhysicsFlag(self, PHYSICS_APPLYGRAVITY, 0)
		SetEntityInterestLevel(self,0)
		self.showExplosionEffect = 1
		self:disable()
	end	

	function Ob:createExplosion()
		self.explosion = SpawnScript('Global.Props.Geometry', self.Name..'Explosion', 'self.meshName = \'GlobalModels/GO_GlobalObjects/CensorBlast_explosion.plb\' self.collidee = 0', 1) 
		SetEntityVisible(self.explosion, 0)
	end

-- *****************************************************************************************

	function Ob:disable()
		SetPhysicsFlag(self, PHYSICS_COLLIDEE, 0)
		SetPhysicsFlag(self, PHYSICS_COLLIDER, 0)
		SetPhysicsFlag(self, PHYSICS_NOPHYSICS, 1)
		SetEntityVisible(self, 0)
	end

	function Ob:killSelf()
		self:killTimer(self.TIMER_EXPIRE)
		SetPhysicsFlag(self, PHYSICS_COLLIDEE, 0)
		SetPhysicsFlag(self, PHYSICS_COLLIDER, 0)
		SetEntityVisible(self, 0)
		
		if (self.explosion) then
			SetEntityVisible(self.explosion, 0)
		end

		if (self.trail) then
			self.trail:stop(0, 0, 1)
			self.trail = nil
		end
		
		if (self.areaEffect ~= 1) and (self.showExplosionEffect == 1) then
			self.explosionFXPool:get():runThenPool(self:getPosition())
			self:sendWorldMessage2('NewMoveMelee', 300, self.knockBackDamage, nil)
		end

		self:setState(nil)
		%Ob.Parent.killSelf(self)
	end

	function Ob:sendWorldMessage2(Message,Radius,Data,Priority)
		local x, y, z = self:getPosition()
		local me = self
		
		local splosion = function(ent)
			local x,y,z = %me:getPosition()
			local tx,ty,tz = ent:getPosition()
			local dist = GetDistance(x,y,z,tx,ty,tz)
			local enttype = ent.Type
			--if (dist < 301) then
				%me:sendMessageEx(ent, 'NewMoveMelee', 1, 'sf', nil, %me.knockBackDamage)
		--	end
		end
		ForEachEntityInRadius(x, y, z, Radius, splosion)

	end

	-- Pool API: called when object is put into pool
	function Ob:onPool()
		SetPhysicsFlag(self,PHYSICS_NOPHYSICS, 1)
		SetPhysicsFlag(self,PHYSICS_APPLYGRAVITY, 0)	-- skips gravity interpolation
	end

	-- Pool API: called when object is taken from pool
	function Ob:onUnpool()
		SetPhysicsFlag(self,PHYSICS_NOPHYSICS, 0)
		SetPhysicsFlag(self,PHYSICS_APPLYGRAVITY, 1)
		self:resetEntity()
	end

-- ****************************************************************************
-- MESSAGE HANDLERS
-- ****************************************************************************

	function Ob:onCollide(data, from)
		if from ~= Global then
			local name = strlower(from.Name)
			self:sendMessageEx(from, 'NewMoveMelee', 1, 'sf', nil, self.knockBackDamage)
		end
		self:killSelf()
		
	end

-- ****************************************************************************

	-- If you add any timer stuff, make sure to pass unhandled ids to parent.
	function Ob:onTimer(id)
		if(id == self.TIMER_EXPIRE) then
			self:killSelf()
		end
		%Ob.Parent.onTimer(self, id)
	end


	function Ob:launchAt(xOrEnt, y, z)
		local sx, sy, sz = Global.player:getHead()
		self:setPosition(xOrEnt, y, z)
		SetEntityCollideIgnoreEntity(self, Global.player, 1)

		-- turn on collison and show projectile
		SetPhysicsFlag(self, PHYSICS_COLLIDER, 1)
		SetPhysicsFlag(self, PHYSICS_COLLIDEE, 1)
		SetPhysicsFlag(self, PHYSICS_NOPHYSICS, 0)
		
		local ux, uy, uz = GetEntityUp(Global.player)
		
		-- aim the projectile towards the target
		local fx,fy,fz = GetEntityForwardVector(Global.player)
		local ox, oy, oz = VectorToEuler(-fx,-fy,-fz, ux, uy, uz)
		self:setOrientation(ox, oy, oz)

		local pitch, yaw, ox, oy, oz
		local lookTarg = Global.player:getLookTarget()
		if (lookTarg) then 
			local cx, cy, cz = lookTarg:getPosition()
			cy = cy + 80
			pitch, yaw = FindTrajectory(sx, sy, sz, cx, cy, cz, self.velocity, self.bApplyGravity, ux, uy, uz)
		else
			pitch, yaw = FindTrajectory(sx, sy, sz, xOrEnt, y, z, self.velocity, self.bApplyGravity, ux, uy, uz)
		end
		LaunchEntity(self, xOrEnt, y, z, pitch, yaw, 0, self.velocity, 0)

		PlaySound(self,self.sounds.launch,0,0)
		if (self.trail) then
			self.trail:stop(0, 0, 1)
		end
		self.trail = self.trailFXPool:get()
		self.trail:attach(self, nil, 1)
		self.trail:setPosition(0, -50, 0)
		self:createTimer(self.timerLength, self.TIMER_EXPIRE)
		SetEntityVisible(self, 1)
	end
	
	return Ob
end

