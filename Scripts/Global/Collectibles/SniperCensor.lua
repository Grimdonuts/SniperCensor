function SniperCensor(Ob)
	if ( not Ob ) then
		Ob = CreateObject("Global.Props.HeldObject")

		Ob.meshName = 'characters/censorlevel2.plb'

		Ob.displayName = "/GLSNIPCEN/"

		Ob.pickupSpriteName = 'censorsniper'

		Ob.clutchAnim = 'Anims/DartNew/BodyParts/Hold_FistLoosePalmIn_ArmLf.jan'

		Ob.collSphereRadius = 30

		Ob.bAutoSelect = 1

		Ob.bPutAwayOnMelee = 0

		Ob.level = 'all'

		Ob.HeldPosX = -10
		Ob.HeldPosY = 20
		Ob.HeldPosZ = 0
		Ob.HeldRotX = 0
		Ob.HeldRotY = 180
		Ob.HeldRotZ = 60
		Ob.scaleX = 0.25
		Ob.scaleY = 0.25
		Ob.scaleZ = 0.25

		Ob.bUseOnly = 1

		Ob.bUseRangedState = 0
		
		Ob.bCanShoot = 0
		Ob.rangedCheckNoLineOfSight = -1
		Ob.projectileType = 'Global.Collectibles.SniperProjectile'
		Ob.projectilePool = nil
		Ob.shotFrequency = 0
		Ob.shotFrequencyDeviance = 0
		Ob.queuedProjectile = nil
		Ob.projectileRangeMax = 1800
		Ob.projectileRangeMin = nil
		Ob.rangedAttackAngle = 10
		Ob.rangedCheckLineOfSight = 1
		Ob.rangedIgnoreMinRangeWhenNoPath = 0
		Ob.canShootNo = 1
		Ob.TIMER_ID = '6999'
		Ob.timerDuration = 500
	end

	function Ob:onBeginLevel()
		%Ob.Parent.onBeginLevel(self)
		self.projectilePool = Global.levelScript:getPool(self.projectileType)
		self:setScale(self.scaleX,self.scaleY,self.scaleZ, 1)
	end

	function Ob:setupProjectile(projectile)
		SetPhysicsFlag(projectile, PHYSICS_CHECKTRIGGERS, 0)
		projectile.areaEffect = 0
		projectile.bApplyGravity = 0
	end

	function Ob:getProjectile()
        local projectile = nil
		projectile = self.projectilePool:get()
		if (projectile) then
			projectile.censor = self
		end
	
		if (self.setupProjectile) then
			self:setupProjectile(projectile)
		end

		return projectile
	end

	function Ob:queueProjectiles()
		self.queuedProjectile = self:getProjectile()
		if (self.queuedProjectile) then
			return 1
		end
		return 0
	end

	function Ob:launchProjectiles()
		if (self.queuedProjectile) then
			self.queuedProjectile:launchAt(Global.player:getPosInFrontOf(140, 120, -35))
		end
		self.queuedProjectile = nil
	end

	function Ob:onFireProjectile(event)
		self.canShootNo = 0
		self:createTimer(self.timerDuration, self.TIMER_ID)
		self:queueProjectiles()
		self:launchProjectiles()
	end

	function Ob:onActivateFromInventory()
		if (self.canShootNo == 1) then self:onFireProjectile() end
	end

	-- If you add any timer stuff, make sure to pass unhandled ids to parent.
	function Ob:onTimer(id)
		if(id == self.TIMER_ID) then
			self.canShootNo = 1
			self:killTimer(self.TIMER_ID)
		end
		%Ob.Parent.onTimer(self, id)
	end
	
	return Ob
end