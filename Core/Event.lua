-- Event.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2018, 2:06:08 PM
--
local ns = select(2, ...)
local Event = ns.Frame.Event

function Event:OnLoad()
    self.isRunning = false
    self.timelines = {}
    self.ignores = {}

    self.eventsHash = {}
    self.eventsTree = {}

    self.TimelineList = self.Timeline.ScrollFrame
    self.ArgumentsList = self.Arguments.ScrollFrame
    self.EventsList = self.Events.ScrollFrame

    ns.ListViewSetup(self.TimelineList, {
        itemList = self.timelines,
        buttonTemplate = 'tdDevToolsTimelineItemTemplate',
        pinBottom = true,
        OnItemFormatting = function(button, item)
            return self:OnTimelineItemFormatting(button, item)
        end,
    })

    ns.ListViewSetup(self.ArgumentsList, {
        itemList = {},
        buttonTemplate = 'tdDevToolsArgumentItemTemplate',
        OnItemFormatting = function(button, item)
            return self:OnArgumentItemFormatting(button, item)
        end,
    })

    ns.TreeViewSetup(self.EventsList, {
        depth = 2,
        itemTree = self.eventsTree,
        buttonTemplate = 'tdDevToolsEventsItemTemplate',
        OnItemFormatting = {
            function(button, item)
                return self:OnEventsItemFormatting1(button, item)
            end, function(button, item)
                return self:OnEventsItemFormatting2(button, item)
            end,
        },
    })

    self.Updater = CreateFrame('Frame')
    self.Updater:Hide()
    self.Updater:SetScript('OnUpdate', function()
        return self:OnFrame()
    end)

    self:SetScript('OnShow', self.Refresh)
    self:SetScript('OnEvent', self.OnEvent)
    self:SetScript('OnSizeChanged', self.OnSizeChanged)
end

function Event:OnSizeChanged()
    local width = self:GetWidth() / 3
    self.Events:SetWidth(width)
    self.Timeline:SetWidth(width)
end

function Event:Start()
    self.isRunning = true
    self.ignores = {}
    self.lastEventTime = nil
    self.lastFrames = 0

    self:RegisterAllEvents()
    self.Updater:Show()
end

function Event:Stop()
    self.isRunning = false
    self:UnregisterAllEvents()
    self.Updater:Hide()
end

function Event:Clear()
    wipe(self.timelines)
    wipe(self.eventsTree)
    wipe(self.eventsHash)
    self.args = {}
    self:Refresh()
end

function Event:Toggle()
    if self.isRunning then
        self.Timeline.ToggleButton:SetText('Start')
        self:Stop()
    else
        self.Timeline.ToggleButton:SetText('Stop')
        self:Start()
    end
end

function Event:OnFrame()
    self.lastFrames = self.lastFrames + 1
end

function Event:OnEvent(event, ...)
    if self.ignores[event] then
        return
    end

    local currentTime = self:GetTime()
    local timelines = self.timelines
    local eventsHash = self.eventsHash
    local eventsTree = self.eventsTree

    if self.lastEventTime and currentTime ~= self.lastEventTime then
        timelines[#timelines + 1] = {
            event = 'ELAPSED',
            frames = self.lastFrames,
            long = currentTime - self.lastEventTime,
        }
    end

    local item
    if event == 'COMBAT_LOG_EVENT' or event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        item = self:PackItem(event, currentTime, CombatLogGetCurrentEventInfo())
    else
        item = self:PackItem(event, currentTime, ...)
    end

    timelines[#timelines + 1] = item

    if not eventsHash[event] then
        local treeInfo = {event = event, count = 1}
        eventsHash[event] = treeInfo
        table.insert(eventsTree, treeInfo)
        table.sort(eventsTree, function(lhs, rhs)
            return lhs.event < rhs.event
        end)
    end
    table.insert(eventsHash[event], item)

    self.lastEventTime = currentTime
    self.lastFrames = 0
    self:Refresh()
end

function Event:PackItem(event, currentTime, ...)
    return { --
        event = event,
        time = currentTime,
        args = {count = select('#', ...), ...},
        argsCount = select('#', ...),
    }
end

function Event:OnTimelineItemFormatting(button, item)
    local right, left = self:GetEventText(item)
    button.Time:SetText(item.time)
    button.Text:SetText(item.text)
    button.Time:SetText(left)
    button.Text:SetText(right)
    button.Selected:SetShown(item.args and item.args == self.args)

    if item.event == 'ELAPSED' then
        button.IgnoreButton:Hide()
        button.Time:SetTextColor(GRAY_FONT_COLOR:GetRGB())
        button.Text:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    else
        button.IgnoreButton:Show()
        button.Time:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        button.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end
end

function Event:OnTimelineItemIgnoreClick(button)
    local item = button.item
    local event = item.event
    local timelines = {}
    local lastElapsed

    local events = self.eventsHash[event]

    tDeleteItem(self.eventsTree, events)
    self.eventsHash[event] = nil

    for i, item in ipairs(self.timelines) do
        if item.event == 'ELAPSED' then
            if lastElapsed then
                lastElapsed.frames = lastElapsed.frames + item.frames
                lastElapsed.long = lastElapsed.long + item.long
            else
                lastElapsed = item
            end
        else
            if item.event ~= event then
                if lastElapsed then
                    timelines[#timelines + 1] = lastElapsed
                    lastElapsed = nil
                end

                timelines[#timelines + 1] = item
            end
        end
    end

    if lastElapsed then
        timelines[#timelines + 1] = lastElapsed
    end

    self.ignores[event] = true
    self.timelines = timelines
    self:Refresh()
end

function Event:OnTimelineItemClick(button)
    if button.item.args then
        self.args = button.item.args
        self:Refresh()
    end
end

local Render = ns.Util.Render

function Event:OnArgumentItemFormatting(button, item)
    button.Text:SetText(Render(item))
    button.Index:SetText(format('[%d] =', button:GetID()))
end

function Event:OnArgumentItemClick(button)
    if type(button.item) == 'table' then
        inspect(button.item)
    end
end

function Event:OnEventsItemFormatting1(button, item)
    local expend = self.EventsList:IsItemExpend(item)
    button.Text:SetText(item.event)
    button.Count:SetText(#item)
    button.Count:SetFontObject('tdDevToolsFontImportant')
    button.Expend:SetShown(not expend)
    button.Fold:SetShown(expend)
    button.Selected:Hide()
    button.IgnoreButton:Show()
    button.depth = 1
end

function Event:OnEventsItemFormatting2(button, item)
    button.Text:SetText('')
    button.Count:SetText(self:FormatFullTime(item.time))
    button.Count:SetFontObject('tdDevToolsFontDisabled')
    button.Expend:Hide()
    button.Fold:Hide()
    button.Selected:SetShown(item.args == self.args)
    button.IgnoreButton:Hide()
    button.depth = 2
end

function Event:OnEventsItemClick(button)
    if button.depth == 1 then
        self.EventsList:ToggleItem(button.item)
    elseif button.depth == 2 then
        self.args = button.item.args
        self.TimelineList:JumpToItem(button.item)
        self:Refresh()
    end
end

function Event:GetTime()
    return GetTime() % 1 + time()
end

function Event:FormatTime(time)
    local mseconds = time * 1000 % 1000
    return format('%s.%03d', date('%H:%M:%S', time), mseconds)
end

function Event:FormatFullTime(time)
    local mseconds = time * 1000 % 1000
    return format('%s.%03d', date('%Y/%m/%d %H:%M:%S', time), mseconds)
end

function Event:GetEventText(item)
    if item.event == 'ELAPSED' then
        return format('%.03f sec - %d frame(s)', item.long, item.frames), 'ELAPSED'
    else
        return item.event, self:FormatTime(item.time)
    end
end

function Event:Refresh()
    self.TimelineList:SetItemList(self.timelines)
    self.ArgumentsList:SetItemList(self.args)
    self.EventsList:Refresh()
end

Event:OnLoad()
