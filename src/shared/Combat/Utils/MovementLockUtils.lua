-- ReplicatedStorage/Combat/Shared/MovementLockService.lua
--[[
	MovementLockService (SHARED, but typically SERVER-USED)
	What this module is:
	- A stackable movement lock system for Humanoids.
	- Lets multiple systems "lock movement" and then safely restore it.

	Why it exists:
	- Without stacking, one script can restore WalkSpeed while another lock is still active.
	- This service prevents that common bug.

	How it works:
	- Each lock has an id (token) and optional duration.
	- When ALL locks are removed/expired, original movement values are restored.

	Recommended usage:
	- Server applies locks for gameplay authority (stun, heavy windup, etc.)
	- Client can mirror for feel, but server should enforce.

	Example:
		local token = MovementLockService:Lock(character, { walkSpeed = 0, jumpPower = 0, duration = 1.25 })
		-- optionally unlock early
		MovementLockService:Unlock(character, token)
]]

local RunService = game:GetService("RunService")

local MovementLockService = {}

type Lock = {
	id: string,
	expiresAt: number?,
	walkSpeed: number?,
	jumpPower: number?,
	jumpHeight: number?,
	autoRotate: boolean?,
}

type Snapshot = {
	walkSpeed: number,
	jumpPower: number?,
	jumpHeight: number?,
	autoRotate: boolean?,
}

-- [Model] = { original: Snapshot, locks: {Lock} }
local store: {[Model]: {original: Snapshot, locks: {Lock}}} = {}

local function now()
	return os.clock()
end

local function getHumanoid(model: Model): Humanoid?
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function takeSnapshot(hum: Humanoid): Snapshot
	-- JumpPower vs JumpHeight differs by game settings; snapshot both safely.
	local snap: Snapshot = {
		walkSpeed = hum.WalkSpeed,
		autoRotate = hum.AutoRotate,
	}
	-- these properties may exist depending on settings
	pcall(function() snap.jumpPower = hum.JumpPower end)
	pcall(function() snap.jumpHeight = hum.JumpHeight end)
	return snap
end

local function applyLockValues(hum: Humanoid, lock: Lock)
	if lock.walkSpeed ~= nil then hum.WalkSpeed = lock.walkSpeed end
	if lock.autoRotate ~= nil then hum.AutoRotate = lock.autoRotate end
	if lock.jumpPower ~= nil then pcall(function() hum.JumpPower = lock.jumpPower end) end
	if lock.jumpHeight ~= nil then pcall(function() hum.JumpHeight = lock.jumpHeight end) end
end

local function restoreSnapshot(hum: Humanoid, snap: Snapshot)
	hum.WalkSpeed = snap.walkSpeed
	hum.AutoRotate = snap.autoRotate
	if snap.jumpPower ~= nil then pcall(function() hum.JumpPower = snap.jumpPower end) end
	if snap.jumpHeight ~= nil then pcall(function() hum.JumpHeight = snap.jumpHeight end) end
end

local function makeId()
	return tostring(math.random(100000, 999999)) .. "-" .. tostring(now())
end

-- opts:
--   walkSpeed:number?
--   jumpPower:number?
--   jumpHeight:number?
--   autoRotate:boolean?
--   duration:number? (seconds)
function MovementLockService:Lock(model: Model, opts: table): string?
	local hum = getHumanoid(model)
	if not hum then return nil end
	opts = opts or {}

	local rec = store[model]
	if not rec then
		rec = {
			original = takeSnapshot(hum),
			locks = {},
		}
		store[model] = rec
	end

	local id = makeId()
	local lock: Lock = {
		id = id,
		walkSpeed = opts.walkSpeed,
		jumpPower = opts.jumpPower,
		jumpHeight = opts.jumpHeight,
		autoRotate = opts.autoRotate,
	}

	if opts.duration and opts.duration > 0 then
		lock.expiresAt = now() + opts.duration
	end

	table.insert(rec.locks, lock)

	-- Apply the strictest lock by simply applying the newest lock
	-- (If you want "lowest speed wins" logic later, we can compute aggregate.)
	applyLockValues(hum, lock)

	return id
end

function MovementLockService:Unlock(model: Model, lockId: string)
	local rec = store[model]
	if not rec then return end

	for i = #rec.locks, 1, -1 do
		if rec.locks[i].id == lockId then
			table.remove(rec.locks, i)
			break
		end
	end

	local hum = getHumanoid(model)
	if not hum then
		store[model] = nil
		return
	end

	if #rec.locks == 0 then
		restoreSnapshot(hum, rec.original)
		store[model] = nil
	else
		-- Re-apply last lock still active
		local last = rec.locks[#rec.locks]
		applyLockValues(hum, last)
	end
end

-- Cleanup expired locks
RunService.Heartbeat:Connect(function()
	for model, rec in pairs(store) do
		if not model.Parent then
			store[model] = nil
		else
			local hum = getHumanoid(model)
			if not hum then
				store[model] = nil
			else
				local changed = false
				for i = #rec.locks, 1, -1 do
					local lock = rec.locks[i]
					if lock.expiresAt and now() >= lock.expiresAt then
						table.remove(rec.locks, i)
						changed = true
					end
				end

				if changed then
					if #rec.locks == 0 then
						restoreSnapshot(hum, rec.original)
						store[model] = nil
					else
						applyLockValues(hum, rec.locks[#rec.locks])
					end
				end
			end
		end
	end
end)

return MovementLockService
