Config = {}

Config.StatusMax        = 600
Config.TickTime         = 1000
Config.TickTimeHurry    = 250
Config.UpdateInterval   = 10000
Config.Style            = 'vertical'

Config.vehicle = {
	speedUnit = 'KMH',
	maxSpeed = 380, 

	seatbelt = {
		playBuckleSound 	= true,
		playUnbuckleSound 	= true,
		playUnsafeSound 	= true
	},

	keys = {
		seatbelt 	= 23,
		cruiser		= 137,
		signalLeft	= 174,
		signalRight	= 175,
		signalBoth	= 173,
	}
}

-- Amount of Time to Blackout, in milliseconds
-- 2000 = 2 seconds
Config.BlackoutTime = 2000

-- Enable blacking out due to vehicle damage
-- If a vehicle suffers an impact greater than the specified value, the player blacks out
Config.BlackoutFromDamage = true
Config.BlackoutDamageRequired = 46

-- Enable blacking out due to speed deceleration
-- If a vehicle slows down rapidly over this threshold, the player blacks out
Config.BlackoutFromSpeed = true
Config.BlackoutSpeedRequired = 70 -- Speed in KPH

-- Enable the disabling of controls if the player is blacked out
Config.DisableControlsOnBlackout = true