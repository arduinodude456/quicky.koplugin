--[[
-- This is the notes widget which is going to do the drawing
--]]

local BD = require("ui/bidi")
-- local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local ButtonProgressWidget = require("ui/widget/buttonprogresswidget")
local ButtonTable = require("ui/widget/buttontable")
local Cache = require("cache")
local ColorWheelWidget = require("widgets/colorwheelwidget")
local Device = require("device")
local DictQuickLookup = require("ui/widget/dictquicklookup")
local Event = require("ui/event")
local FileManager = require("apps/filemanager/filemanager")
local FrameContainer = require("ui/widget/container/framecontainer")
-- local Geom = require("ui/geometry")
local HtmlBoxWidget = require("ui/widget/htmlboxwidget")
local IconWidget = require("ui/widget/iconwidget")
local ImageWidget = require("ui/widget/imagewidget")
local InputDialog = require("ui/widget/inputdialog")
local InputText = require("ui/widget/inputtext")
local LineWidget = require("ui/widget/linewidget")
local ProgressWidget = require("ui/widget/progresswidget")
local ReaderFooter = require("apps/reader/modules/readerfooter")
local ReaderUI = require("apps/reader/readerui")
local ReaderView = require("apps/reader/modules/readerview")
local RenderImage = require("ui/renderimage")
local Screen = Device.screen
local ScreenSaverWidget = require("ui/widget/screensaverwidget")
local Setting = require("lib/setting")
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local ToggleSwitch = require("ui/widget/toggleswitch")
-- local UIManager = require("ui/uimanager")
local UnderlineContainer = require("ui/widget/container/underlinecontainer")
local VirtualKeyboard = require("ui/widget/virtualkeyboard")
local common = require("lib/common")
local logger = require("logger")
local userpatch = require("userpatch")
local util = require("util")
local logger = require("logger")

local Blitbuffer = require("ffi/blitbuffer")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local Widget = require("ui/widget/widget")
local Screen = require("device").screen
local InputListener = require("./inputlistener")
local RenderImage = require("ui/renderimage")
local _ = require("gettext")
local LuaSettings = require("luasettings")

---@class BlitBuffer
---@field paintRect fun(x: integer, y: integer, w: integer, h:integer, value: any, setter: any)
---@field paintRectRGB32 fun(x: integer, y: integer, w: integer, h:integer, value: any, setter: any)
---@field free fun()

local PEN_COLOR = Blitbuffer.colorFromName("red")
local WHITE = Blitbuffer.colorFromString("#ffffff")
local TRANSPARENT_ALPHA = Blitbuffer.colorFromString("#00000000")
local PEN_BRUSH_SIZE = 6
local ERASER_BRUSH_SIZE = 40

---@class Dimension
---@field x int
---@field y int
---@field w int
---@field h int
---@field offsetBy  fun(x, y)

---@class Page
---@field _bb BlitBuffer
---@field templatePath string
---@field templateEnabled boolean
---

---@class NotesWidget
---@field dimen Dimension
---@field touchEvents TouchEvent[][]
---@field brushSize integer
---@field penColor integer
---@field backgroundColor integer
---@field strokeTime integer
---@field strokeDelay integer
---@field isRunning boolean
---@field pages Page[]
---@field currentPage integer
---@field saveToDir func(path)
---@field loadNotes func(path)
---@field setDirty fun()
---@field toggleTemplate fun()
---@field removeTemplate fun()
---@field fingerInputEnabled boolean
---@field eraserEnabled boolean
---@field toggleEraserEnabled fun()

---@type map<string,BlitBuffer>
local TEMPLATES = {
}

---@type NotesWidget
local NotesWidget = Widget:extend {
}

local BLANK_TEMPLATE_PATH = "::BLANK::";

---@param templatePath string
---@param templateEnabled boolean
---@return BlitBuffer
function NotesWidget:get_template_bb(templatePath, templateEnabled)
  if not (templatePath and templateEnabled) then
    templatePath = BLANK_TEMPLATE_PATH
  end

  if not TEMPLATES[templatePath] then
    local bb

    if BLANK_TEMPLATE_PATH == templatePath then
      bb = Blitbuffer.new(self.dimen.w, self.dimen.h, Blitbuffer.TYPE_BBRGB32);
      bb:paintRectRGB32(0, 0, self.dimen.w, self.dimen.h, self.backgroundColor);
    else
      bb = RenderImage:renderImageFile(templatePath, false, self.dimen.w, self.dimen.h);
    end

    TEMPLATES[templatePath] = bb
  end
  return TEMPLATES[templatePath]
end

function NotesWidget:init()
  logger.info("NotesWidget:init()")
  self.dimen = Geom:new {
    w = Screen:getSize().w * 0.95,
    h = Screen:getSize().h * 0.95,
  };
  self.touchEvents = { {} }
  self.allTouchX = { 0 }
  self.allTouchY = { 0 }
  self.brushSize = 3
  self.backgroundColor = WHITE
  self.penColor = PEN_COLOR
  self.strokeDelay =  10 * 1000
  self.strokeTime = 60 * 1000
  self.pages = {}
  self.eraserEnabled = false
  self.markerEnabled = false
  self:newPage()
end

function NotesWidget:getSize()
  return self.dimen;
end

function NotesWidget:paintTo(bb, x, y)
  self.dimen.x = x;
  self.dimen.y = y;
  if not self.dimen or self.dimen.x == 0 or self.dimen.y == 0 then
    return
  end
  if #self.pages == 0 then
    self:newPage();
  end
  logger.dbg("NotesWidget:paintTo", x, y);
  local page = self.pages[self.currentPage];

  if page.templatePath then
    bb:blitFrom(self:get_template_bb(page.templatePath, page.templateEnabled), x, y, 0, 0, self.dimen.w, self.dimen.h)
  end
  if not page._bb then
    logger.warn("NotesWidget:paintTo didn't have bb in page: ", page, self.pages, self.currentPage);
    return
  end
  bb:alphablitFrom(page._bb, x, y, 0, 0, self.dimen.w, self.dimen.h)
  logger.dbg("NotesWidget:paintTo dimen: ", self.dimen);
end

---comment
---@param p1 TouchEvent
---@param p2 TouchEvent
function NotesWidget:interPolate(p1, p2)
  if not p1 or not p2 then
    return
  end

  local bb = self.pages[self.currentPage]._bb

  bb:paintRectRGB32(p1.x, p1.y, self.brushSize, self.brushSize, self.penColor);
  bb:paintRectRGB32(p2.x, p2.y, self.brushSize, self.brushSize, self.penColor);
  if p1.x == p2.x and p1.y == p2.y then
    return
  end
  local x0 = p1.x < p2.x and p1.x or p2.x
  local x1 = p1.x > p2.x and p1.x or p2.x
  local y0 = p1.x < p2.x and p1.y or p2.y
  local y1 = p1.x > p2.x and p1.y or p2.y

  local xDiff = x1 - x0

  for x = x0 + 1, x1, 1 do
    local y = math.floor(((y0 * (x1 - x)) + (y1 * (x - x0))) / xDiff)
    if x == 0 or y == 0 then return end
    bb:paintRectRGB32(x, y, self.brushSize, self.brushSize, self.penColor);
  end

  x0 = p1.y < p2.y and p1.x or p2.x
  x1 = p1.y > p2.y and p1.x or p2.x
  y0 = p1.y < p2.y and p1.y or p2.y
  y1 = p1.y > p2.y and p1.y or p2.y

  local yDiff = y1 - y0
  for y = y0 + 1, y1, 1 do
    local x = math.floor(((x0 * (y1 - y)) + (x1 * (y - y0))) / yDiff)
    if x == 0 or y == 0 then return end
    bb:paintRectRGB32(x, y, self.brushSize, self.brushSize, self.penColor);
  end
end


---@param enabled boolean
function NotesWidget:toggleEraserEnabled(enabled)
  self.eraserEnabled = not self.eraserEnabled
end

---@param tEvent TouchEvent
---@param hook_params any
function NotesWidget:touchEventListener(tEvent, hook_params)
  if not self.isRunning or not tEvent then
if self:isLine() then
  local bb = self.pages[self.currentPage]._bb;
     bb:paintRectRGB32(0, self.allTouchY[1], 1300, self.brushSize, self.penColor);
end
 self.allTouchX = {0}
    self.allTouchY = {0}
    return
  end

  if tEvent.toolType == InputListener.ToolType.FINGER then
    if (not self.fingerInputEnabled) then
      return
    end
    if self.useFingerAsEraser then
      tEvent.type = InputListener.TouchEventType.ERASER_DOWN 
      logger.dbg("NW: Using finger as eraser for event: " .. tostring(tEvent))
    end
  end
  -- 1. DRUCKSKALIERUNG (Neu)
  -- Kobo liefert Werte bis ca. 4095. Wir rechnen das in eine sinnvolle Pixelbreite um (z.B. 2 bis 8 Pixel).
  local raw_pressure = InputListener:pressureV() 
  local min_brush = 2 -- PEN_BRUSH_SIZE             -- Deine Standardbreite (z.B. 2)
  local max_extra_brush = 100                    -- Wie viel dicker der Stift maximal werden darf
  local dynamic_brush_size = min_brush + math.floor((raw_pressure / 4095) * max_extra_brush)

  self.penColor = PEN_COLOR
  self.brushSize = PEN_BRUSH_SIZE          -- Standardmäßig dynamischen Druck nutzen

  if self.eraserEnabled or tEvent.type == InputListener.TouchEventType.ERASER_DOWN then
    self.penColor = TRANSPARENT_ALPHA
    self.brushSize = ERASER_BRUSH_SIZE
  end
  if tEvent.type == InputListener.TouchEventType.MARKER_DOWN then
    self.penColor = Blitbuffer.colorFromString("#ffff0088")
    self.brushSize = ERASER_BRUSH_SIZE + 5
  end
  if tEvent.type == not InputListener.TouchEventType.MARKER_DOWN then
    -- self.penColor = Blitbuffer.colorFromName("red")
    -- self.brushSize = ERASER_BRUSH_SIZE 
  end
  if tEvent.type == InputListener.TouchEventType.PEN_DOWN then
    self.penColor = PEN_COLOR
    self.brushSize = raw_pressure
    -- self.brushSize = PEN_BRUSH_SIZE
    -- self.brushSize = InputListener:pressureV()
else

  end
  -- if tEvent.type == InputListener.TouchEventType.PRESSURE_DOWN then
    -- self.brushSize = InputListener:pressureV()
  -- end
  local tx = tEvent.x - self.dimen.x;
  local ty = tEvent.y - self.dimen.y;
  self.allTouchX[#self.allTouchX] = tEvent.x
  self.allTouchY[#self.allTouchY] = tEvent.y
  --- Boundary check
  if tx < 0 or tx > self.dimen.w or tx < 0 or ty > self.dimen.h then
    return;
  end

  tEvent.x = tx
  tEvent.y = ty

  if not self.touchEvents[tEvent.slot] then
    self.touchEvents[tEvent.slot] = {}

  end

  local touchEvents = self.touchEvents[tEvent.slot]
  local minX, minY, maxX, maxY = tEvent.x, tEvent.y, tEvent.x, tEvent.y

  local bb = self.pages[self.currentPage]._bb;
  table.insert(touchEvents, tEvent)
  if #touchEvents < 2 then
    -- bb:paintRectRGB32(tEvent.x, tEvent.y, self.brushSize, self.brushSize, self.penColor);
  else
    local prevTEvent = touchEvents[#touchEvents - 1]
    local tEvent = touchEvents[#touchEvents]

    minX, minY = math.min(tEvent.x, prevTEvent.x), math.min(tEvent.y, prevTEvent.y)
    maxX, maxY = math.max(tEvent.x, prevTEvent.x), math.max(tEvent.y, prevTEvent.y)

    if tEvent.time - prevTEvent.time < self.strokeTime and tEvent.toolType == prevTEvent.toolType then
      self:interPolate(prevTEvent, tEvent);




      bb:paintRectRGB32(tEvent.x, tEvent.y, self.brushSize, self.brushSize, self.penColor);

    else

    end
  end

  --- @type Dimension
  local affectedArea = Geom:new({
    x = minX,
    y = minY,
    w = maxX - minX,
    h = maxY - minY,
  })
  --- @type Dimension
  local screenCoords = affectedArea:offsetBy(self.dimen.x, self.dimen.y)
  screenCoords.x = screenCoords.x - self.brushSize
  screenCoords.y = screenCoords.y - self.brushSize

  if screenCoords.x < 0 then screenCoords.x = 0 end
  if screenCoords.y < 0 then screenCoords.y = 0 end
  screenCoords.w = screenCoords.w + (self.brushSize * 2)
  screenCoords.h = screenCoords.h + (self.brushSize * 2)

  self:setDirty(screenCoords)
end

function NotesWidget:paintToBB()
  if #self.touchEvents < 1 then


    return true
  end

  local page = self.pages[self.currentPage]._bb

  for _, slotTouchEvs in pairs(self.touchEvents) do
    for index, tEvent in ipairs(slotTouchEvs) do
      
      if index == 1 then

        bb:paintRect(tEvent.x, tEvent.y, self.brushSize, self.brushSize, self.penColor);
      else
        local prevTEvent = self.touchEvents[index - 1]
        if tEvent.time - prevTEvent.time < self.strokeTime and tEvent.toolType == prevTEvent.toolType then
          self:interPolate(prevTEvent, tEvent);
        else


          bb:paintRectRGB32(tEvent.x, tEvent.y, self.brushSize, self.brushSize, self.penColor);


        end
      end
    end
  end

  self:setDirty()
end

---@param template_path string
function NotesWidget:setTemplate(template_path)
  self.pages[self.currentPage].templatePath = template_path;
  self.pages[self.currentPage].templateEnabled = true;
  self:setDirty()
end

function NotesWidget:removeTemplate()
  self.pages[self.currentPage].templatePath = nil;
  self:setDirty()
end
-- Definiere die Farbpalette einmalig als Hex-Strings (erweiterbar!)
local NOTE_COLORS = {
    "#ff0000", -- Rot
    "#ffffff", -- Weiß (Radiergummi?)
    "#000000", -- Schwarz
    "#00ff00", -- Grün
    "#0000ff", -- Blau
    "#ff00ff", -- Magenta / Pink (Bonus für den Farbbildschirm)
    "#ffff00"  -- Gelb (Bonus)
}

function NotesWidget:toggleTemplate()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Finde heraus, welche Farbe aktuell aktiv ist (Standard: 1 = Rot)
    local currentIndex = 1
    for i, hex in ipairs(NOTE_COLORS) do
        if PEN_COLOR == Blitbuffer.colorFromString(hex) then
            currentIndex = i
            break
        end
    end
    
    -- 2. Berechne die nächste Farbe (wiederholt sich am Ende der Liste)
    local nextIndex = currentIndex % #NOTE_COLORS + 1
    local nextHex = NOTE_COLORS[nextIndex]
    
    -- 3. Setze die neue globale Stiftfarbe
    PEN_COLOR = Blitbuffer.colorFromString(nextHex)
    
    -- 4. Zeichne den Indikator-Balken (immer in RGB32 für satte Farben)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 5. UI-Refresh anfordern
    self:setDirty(self.dimen)
end
function NotesWidget:colorRed()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#ff0000")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
function NotesWidget:colorWhite()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#aaaaaa")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
function NotesWidget:colorBlack()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#000000")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
function NotesWidget:colorGreen()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#00ff00")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
function NotesWidget:colorBlue()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#0000ff")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
function NotesWidget:colorPink()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#ff00ff")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
function NotesWidget:colorYellow()
    local bb = self.pages[self.currentPage]._bb
    
    -- 1. Setze die globale Stiftfarbe direkt auf Rot
    PEN_COLOR = Blitbuffer.colorFromString("#ffff00")
    
    -- 2. Zeichne den farbigen Indikator-Balken oben (1000x100 Pixel)
    -- bb:paintRectRGB32(0, 0, 1000, 100, PEN_COLOR)
    
    -- 3. Signalisiere KOReader, dass der Bildschirm aktualisiert werden muss
    self:setDirty(self.dimen)
end
local RANGES = {
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25
}
local bb
function NotesWidget:drawLines()
bb = self.pages[self.currentPage]._bb
  for v, i in ipairs(RANGES) do
    bb:paintRectRGB32(20, i * 100, 1300,1, Blitbuffer.colorFromString("#999999"))
  end
  self:setDirty(self.dimen)
end
function NotesWidget:drawGrid()
bb = self.pages[self.currentPage]._bb
  for v, i in ipairs(RANGES) do 

if i%2 ==0 then
    bb:paintRectRGB32(1+i*100,1+i*120, 1500-i*200,1500-i*240, Blitbuffer.colorFromString("#999999"))
else
    bb:paintRectRGB32(1+i*100,1+i*120, 1500-i*200,1500-i*240, Blitbuffer.colorFromString("#99ff09"))
end

  end
  self:setDirty(self.dimen)
end

function NotesWidget:drawBoxes()
bb = self.pages[self.currentPage]._bb
  for v, i in ipairs(RANGES) do

    bb:paintRectRGB32(20, i * 50, 1300,1, Blitbuffer.colorFromString("#999999"))
    bb:paintRectRGB32(i * 50, 0, 1, 1300, Blitbuffer.colorFromString("#999999"))
  end
  self:setDirty(self.dimen)
end


function NotesWidget:isLine()
 local ln = false







  local xDiff = self.allTouchX[#self.allTouchX]-self.allTouchX[1]





  local yDiff = self.allTouchY[#self.allTouchY]-self.allTouchY[1]
 if yDiff < 100 then
  ln = true
 end

 return false
end



function NotesWidget:toggleRed(t)

    PEN_COLOR = Blitbuffer.colorFromString(t)

    self:setDirty(self.dimen)
end
function NotesWidget:appColor(c)
  PEN_COLOR = c
end
function NotesWidget:applyThickness(t)
PEN_BRUSH_SIZE = t
end
function NotesWidget:newNotes()
  self.currentPath = nil
  for i, v in ipairs(self.pages) do
    if v._bb then
      v._bb:free();
    end
  end
  self.pages = {}
  if #self.pages < 1 then
    self:newPage()
    return
  end
  self.currentPage = 1
  self:setDirty()
end

--- @param directory string
function NotesWidget:loadNotes(directory)
  local n_meta = LuaSettings:open(directory .. "/.notes_meta.lua")
  n_meta:readSetting("notes", { pages = {} })
  self.currentPath = directory
  for i, v in ipairs(self.pages) do
    if v._bb then
      v._bb:free();
    end
  end
  self.pages = {}
  local loadedAll = false
  local i = 1
  while not loadedAll do
    local filename = (self.currentPath .. '/page-' .. tostring(i) .. '.png')
    logger.dbg("NW: filename" .. filename)
    local bb = RenderImage:renderImageFile(filename, false, self.dimen.w, self.dimen.h);
    if not bb then
      loadedAll = true
    else
      table.insert(self.pages, { _bb = bb });
    end
    i = i + 1
  end
  if #self.pages < 1 then
    self:newPage()
    return
  else
    for i, v in ipairs(self.pages) do
      if n_meta.data.notes.pages[i] then
        self.pages[i].templatePath = n_meta.data.notes.pages[i].templatePath
        self.pages[i].templateEnabled = n_meta.data.notes.pages[i].templateEnabled
      end
    end
  end
  self.currentPage = 1
  self:setDirty()
end

function NotesWidget:newPage()
  logger.info("[NotesWidget] NewPage")

  local bb = Blitbuffer.new(self.dimen.w, self.dimen.h, Blitbuffer.TYPE_BBRGB32);
  bb:paintRectRGB32(0, 0, self.dimen.w, self.dimen.h, TRANSPARENT_ALPHA);

  ---@type Page
  local page = {
    _bb = bb,
    templatePath = nil,
    templateEnabled = false,
  };
  if self.pages[#self.pages] then
    page.templatePath = self.pages[#self.pages].templatePath
  end

  table.insert(self.pages, page);
  self.currentPage = #self.pages
  self.touchEvents = { {} };
  self:setDirty()
end

function NotesWidget:getPageName()
  return _("(" .. tostring(self.currentPage) .. " of " .. tostring(#self.pages) .. ")")
end

function NotesWidget:clearPage()
  self.pages[self.currentPage]._bb:paintRectRGB32(0, 0, self.dimen.w, self.dimen.h, TRANSPARENT_ALPHA);
end

function NotesWidget:nextPage()
  if self.currentPage == #self.pages then
    self:newPage();
  else
    self.currentPage = self.currentPage + 1
    self:setDirty()
  end
end

function NotesWidget:prevPage()
  if self.currentPage == 1 then
    return
  else
    self.currentPage = self.currentPage - 1
    self:setDirty()
  end
end

---
---@param dimen Dimension
function NotesWidget:setDirty(dimen)
  UIManager:setDirty(self, function()
    return "ui", dimen or self.dimen
  end);
end

---Saves the notes to a directory
---@param dirPath string
function NotesWidget:saveToDir(dirPath)
  logger.dbg("NW: Saving to ", dirPath);
  if not dirPath then
    logger.error("NW: dirPath is mandatory");
    return;
  end

  local n_meta = LuaSettings:open(dirPath .. "/.notes_meta.lua")
  n_meta:readSetting("notes", { pages = {} })
  local meta = {
    pages = {}
  }
  for i, v in ipairs(self.pages) do
    local filePath = dirPath .. "/page-" .. tostring(i) .. ".png";
    logger.dbg("NW: Writing file", filePath);
    if v._bb then
      v._bb:writePNG(filePath);
    end
    meta.pages[i] = {
      templatePath = v.templatePath,
      templateEnabled = v.templateEnabled
    }
  end
  n_meta:saveSetting("notes", meta)
  n_meta:flush()
end

return NotesWidget
