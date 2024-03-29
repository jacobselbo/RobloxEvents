return function()
	local Event = BaseClass:new("Event")
	local Connection = BaseClass:new("Connection")

	local LogClass = import("org.log4lua.Log")
	local Log = LogClass()
	local EventLogger = Log:getLogger(Event)

	local usingDebug = false

	Event.Event = function(self, debug)
		self.functions = { }
		self.threads = { }

		self.Log = Log
		self.EventLogger = Log:getLogger(self, {
			["Debug"] = debug or false	
		})

		return self
	end

	Event.new = function(self, debug)
		if (typeof(debug) ~= "boolean") then
			return EventLogger:atError()
				:addArgument("boolean")
				:addArgument(typeof(debug))
				:log("Expected {} got {}")
		end

		if (self.functions) then
			return EventLogger:atError()
				:log("Attempted to create a new event in a established event?")
		end

		return self(debug)
	end

	Event.connect = function(self, connectionFunction)
		if (not self.functions) then
			return EventLogger:atError()
				:log("Attempted to connect to a invalid event")
		end

		if (typeof(connectionFunction) ~= "function") then
			return EventLogger:atError()
				:addArgument("function")
				:addArgument(typeof(connectionFunction))
				:log("Expected {} got {}")
		end

		self.functions[connectionFunction] = connectionFunction

		self.EventLogger:atDebug()
			:addArgument(connectionFunction)
			:addArgument(tostring(self))
			:log("Connected {} to {}")

		return Connection(self, Connection)
	end

	Event.wait = function(self)
		--[[table.insert(self.threads, coroutine.running())

		self.EventLogger:atDebug()
			:addArgument(coroutine.running())
			:addArgument(tostring(self))
			:log("Now yielding {} in {}")

		return coroutine.yield()]] -- TODO

		return EventLogger:atError()
			:log(":wait() has not been implemented yet due to yielding across metamethods")
	end

	Event.fire = function(self, ...)
		if (not self.functions) then
			return EventLogger:atError()
				:log("Attempted to fire a invalid event")
		end

		self.EventLogger:atDebug()
			:addArgument({ ... })
			:log("Finishing yields and firing functions with {}")

		for _, thread in pairs(self.threads) do
			coroutine.resume(thread, ...)

			self.EventLogger:atDebug()
				:addArgument(thread)
				:log("Done yielding {}")
		end

		for _, connectionFunction in pairs(self.functions) do
			connectionFunction(...)

			self.EventLogger:atDebug()
				:addArgument(connectionFunction)
				:log("Fired function {}")
		end
	end

	Event.disconnectAll = function(self)
		if (not self.functions) then
			return EventLogger:atError()
				:log("Attempted to connect to a invalid event")
		end

		self.functions = { }

		self.EventLogger:atDebug()
			:log("Disconnecting all functions")

		return true
	end

	Event.destroy = function(self)
		if (not self.functions) then
			return EventLogger:atError()
				:log("Attempted to connect to a invalid event")
		end

		self:unregister()
		self.EventLogger:destroy()
		self.Log:destroy()

		return true
	end

	Connection.Connection = function(self, event, connectionFunction)
		self.event = event
		self.connectionFunction = connectionFunction

		self.ConnectionLogger = event.Log:getLogger(self)
		self.ConnectionLogger:atDebug()
			:addArgument(tostring(connectionFunction))
			:addArgument(tostring(event))
			:log("Creating connection with {} to {}")

		return self
	end

	Connection.disconnect = function(self)
		self.event.functions[self.connectionFunction] = nil

		self.ConnectionLogger:atDebug()
			:addArgument(tostring(self.connectionFunction))
			:addArgument(tostring(self.event))
			:log("Disconnecting {} to {}")

		self:unregister()
		self.ConnectionLogger:destroy()

		return true
	end

	return Event
end