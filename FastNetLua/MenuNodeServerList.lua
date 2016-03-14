function MenuNodeServerList:_setup_columns()
	self:_add_column({
		text = string.upper(""),
		proportions = 1.38,
		align = "left"
	})
	self:_add_column({
		text = string.upper(""),
		proportions = 1.81,
		align = "right"
	})
	self:_add_column({
		text = string.upper(""),
		proportions = 1.15,
		align = "right"
	})
	self:_add_column({
		text = string.upper(""),
		proportions = 0.225,
		align = "right"
	})
    self:_add_column({
		text = string.upper(""),
		proportions = 0.105,
		align = "center"
	})
end