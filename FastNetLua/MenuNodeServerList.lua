function MenuNodeServerList:_setup_columns()
	self:_add_column({		-- Server Name
		text = string.upper(""),
		proportions = 1.4,
		align = "left"
	})
	self:_add_column({		-- level name
		text = string.upper(""),
		proportions = 1.7,
		align = "right"
	})
	self:_add_column({		-- Difficulty
		text = string.upper(""),
		proportions = 1.3,
		align = "right"
	})
	self:_add_column({		-- Players/Total
		text = string.upper(""),
		proportions = 0.2,
		align = "right"
	})
    self:_add_column({		-- Lobby Plan
		text = string.upper(""),
		proportions = 0.1,
		align = "center"
	})
end