---@param name string
---@param message string
---@param formatting Formatting
function PrintToChat(name, message, formatting)
	formatting = formatting or {}

	formatting = formatting or {}
	if type(formatting.type) == "string" then
		if RpChatColorCodes[formatting.type] then
			local type = formatting.type
			formatting = RpChatColorCodes[formatting.type]
			formatting.type = type
		end
	end

	local style = ""
	formatting.r = formatting.r or 41
	formatting.g = formatting.g or 41
	formatting.b = formatting.b or 41
	formatting.a = formatting.a or 0.6

	if formatting.type then
		style = ""
	else
		style = string.format("background-color: rgba(%s, %s, %s, %s);", formatting.r, formatting.g, formatting.b, formatting.a)
	end

	--For styling of message see chat-theme-civlifechat
	local template = ('<div class="bubble-message %s" style="%s"><b>{0}:</b> {1}</div>'):format(formatting.type or "", style)

	TriggerEvent('chat:addMessage', {
		template = template,
		args = { name, message },
		important = formatting and formatting.important or nil
	})
end

PrintFancyMessage = PrintToChat

---@param message string|{ resource?: string, formatting?: Formatting, message: string }
---@param resource string|nil
---@param formatting Formatting|nil
---@return nil
function SendReply(message, resource, formatting)
    if type(message) == "table" then
        resource = message.resource
        formatting = message.formatting
        message = message.message
        ---@cast message string
    end

	if type(resource) == "table" then
		local tempFormatting = resource
        if type(formatting) == "string" then
            resource = formatting
        else
            resource = nil
        end
		formatting = tempFormatting
	end

	formatting = formatting or {}
	if type(formatting) == "table" then
		formatting.important = true
	end

    resource = resource or GetInvokingResource() or GetCurrentResourceName()

    PrintToChat(resource, message, formatting)
end