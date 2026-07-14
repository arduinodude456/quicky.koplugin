--[[
This plugin provides a Handwritten notes
]]

local logger = require("logger")
local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local Dispatcher = require("dispatcher")
local FrameContainer = require("ui/widget/container/framecontainer")
local Input = require("device").input
local PathChooser = require("ui/widget/pathchooser")
local TitleBar = require("ui/widget/titlebar")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local IconButton = require("ui/widget/iconbutton")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Size = require("ui/size")
local _ = require("gettext")
local Screen = require("device").screen
local LuaSettings = require("luasettings")
local DataStorage = require("datastorage")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
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
local Geom = require("ui/geometry")
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


local NotesWidget = require("./widget")
local InputListener = require("./inputlistener")
local home_dir = nil
local ffiutil = require("ffi/util")
local T = ffiutil.template


---@class NotesConfig
---@field last_opened_dir string
---@field templates_dir string
---@field finger_input_enabled boolean
---@field use_finger_as_eraser boolean

---@class Notes
---@field margin int
---@field notesWidget NotesWidget
---@field title_bar TitleBar
---@field currentPath string
---@field config NotesConfig

---@type Notes
local Notes = WidgetContainer:new {
  name = "quicky",
  is_doc_only = false,
}
local notesWidgetInstance = NotesWidget:new();
local popup = InfoMessage:new{
    -- m  text = _("Hello World
      text = _("---WILLKOMMEN BEI QUICKY---\n2026 Kobo Release, vO.2\n\nNeed help? Press (?)"),
  background = Blitbuffer.colorFromString("#00000000"),
    }
function Notes:chcl(P)
  self.notesWidget = notesWidgetInstance;
widget = self.notesWidget
widget.PEN_COLOR = P
widget:toggleRed(P)
end
local popup2 = InfoMessage:new{
  text = _("          Help\n\nUse the kobo stylus to paint\nYou can use the end of your stylus as rubber\nYou can touch the screen while painting it doesnt matter\nTouch the lines button to make the background collegeblock-like\nUse the second group of arrow keys to adjust width\nuse the first arrow key group to switch pages\nPress the stylus button to quick switch to marker whioe holding down the key\n\ntap me to continue"),
  background = Blitbuffer.colorFromName("pink"),
}
local PENmod 






    

    




            local wheel
















    


function Notes:init()
local popup = InfoMessage:new{
    -- m  text = _("Hello World
      text = _("---WILLKOMMEN BEI QUICKY---\n2026 Kobo Release, vO.2\n\nNeed help? Press (?)"),

    }
  logger.dbg("Notes:init");
  -- local popup = InfoMessage:new{
      -- text = _("---WILLKOMMEN BEI QUICKY---\n2026 Kobo Release, v0.2"),
    -- }
  local popup2 = InfoMessage:new{
  text = _("          Help\n\nUse the kobo stylus to paint\nYou can use the end of your stylus as rubber\nYou can touch the screen while painting it doesnt matter\nTouch the lines button to make the background collegeblock-like\nUse the second group of arrow keys to adjust width\nuse the first arrow key group to switch pages\nPress the stylus button to quick switch to marker while holding down the key\n\ntap me to continue"),

}
  home_dir = G_reader_settings:readSetting("home_dir")
  self.notesWidget = notesWidgetInstance;
  self.margin = 10;
  self.n_settings = self:readSetting()

  self.config = self.n_settings.data.notes;

  self.notesWidget.fingerInputEnabled = self.config.finger_input_enabled
  self.notesWidget.useFingerAsEraser = self.config.use_finger_as_eraser

  self.layout = {}
  self.width = self.width or math.floor(math.min(Screen:getWidth(), Screen:getHeight()) - self.margin * 2)
  self.name = "Quicky";
  self.title_bar = TitleBar:new {
    width = self.width - Size.border.window * 4,
    with_bottom_line = true,
    title = _("Quicky 0.2 " .. self.notesWidget:getPageName()),
    bottom_v_padding = 0,
    show_parent = self,
    right_icon = "close",
    left_icon = "appbar.menu",
    left_icon_tap_callback = function() self:showMenu() end,
    close_callback = function()
      self:onClose();
    end
  }

  local options = HorizontalGroup:new {
    IconButton:new {
      height = 100,
      icon = "chevron.left",
      callback = function()
        self.notesWidget:prevPage();
        self.title_bar:setTitle(_("Quicky 0.2 " .. self.notesWidget:getPageName()));
      end
    },
    IconButton:new {
      height = 100,
      icon = "chevron.right",
      callback = function()
        self.notesWidget:nextPage();
        self.title_bar:setTitle(_("Quicky 0.2 " .. self.notesWidget:getPageName()));
      end
    },
    IconButton:new {
      height = 100,
      icon = "exit",
      callback = function()
        self.notesWidget:clearPage();
        self.notesWidget:setDirty();
      end
    },
    IconButton:new {
      height = 100,
      icon ="align.center",
      callback = function()
        self.notesWidget:drawLines();
      end
    },
  IconButton:new {
      height = 100,
      icon ="column.three",
      callback = function()
        self.notesWidget:drawBoxes();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penRed",
      callback = function()
        self.notesWidget:colorRed();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penWhite",
      callback = function()
        self.notesWidget:colorWhite();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penBlack",
      callback = function()
        self.notesWidget:colorBlack();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penGreen",
      callback = function()
        self.notesWidget:colorGreen();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penBlue",
      callback = function()
        self.notesWidget:colorBlue();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penPink",
      callback = function()
        self.notesWidget:colorPink();
      end
    },
    IconButton:new {
      height = 100,
      icon ="penYellow",
      callback = function()
        self.notesWidget:colorYellow();
      end
    },
    -- ========================================================
    -- DIE KORREKTE STIFTDICKEN-STEUERUNG ÜBER DAS WIDGET
    -- ========================================================
    -- 1. Button: Stärke verringern
    IconButton:new {
      height = 100,
      icon = "chevron.left",
      callback = function()
        -- Wir greifen direkt in das Notiz-Widget ein:
        local widget = self.notesWidget
        -- Falls pen_width noch nil ist, setzen wir einen Standardwert (z.B. 2)
        local current = widget.PEN_BRUSH_SIZE or 10
        
        if current > 1 then
          local new_width = current - 1
          
          -- Wir schreiben den Wert auf allen denkbaren Variablenpfaden zurück:
          widget.PEN_BRUSH_SIZE = new_width
          self.notesWidget:applyThickness(new_width)
          
          
          
          self.title_bar:setTitle(_("Quicky 0.2 (Stärke: " .. new_width .. ")"))
        end
      end
    },

    -- 2. Button: Stärke erhöhen
    IconButton:new {
      height = 100,
      icon = "chevron.right",
      callback = function()
        local widget = self.notesWidget        local widget = self.notesWidget
        local current = widget.PEN_BRUSH_SIZE or 10
        
        if current <1000 then
          local new_width = current + 3
          
          widget.PEN_BRUSH_SIZE = new_width
          self.notesWidget:applyThickness(new_width)
          
          
          
          self.title_bar:setTitle(_("Quicky 0.2 (Stärke: " .. new_width .. ")"))
        end
      end
    },
    -- ========================================================
    IconButton:new {
      height = 100,
      icon = "notice-question",
      callback = function()
  local popup2 = InfoMessage:new{
  text = _("          Help\n\nUse the kobo stylus to paint\nYou can use the end of your stylus as rubber\nYou can touch the screen while painting it doesnt matter\nTouch the lines button to make the background collegeblock-like\nUse the second group of arrow keys to adjust width\nuse the first arrow key group to switch pages\nPress the stylus button to quick switch to marker whioe holding down the key\n\ntap me to continue"),
  background = Blitbuffer.colorFromName("pink"),
}
        UIManager:show(popup2)
      end
    },
    IconButton:new {
      height = 100,
      icon = "star.full",
      callback = function()
  wheel = ColorWheelWidget:new({
                title_text = "Pick background color",
                hue = 0,
                saturation = 0,
                value = 1,
                invert_in_night_mode = true,
                callback = function(hex)


Notes:chcl(hex)



                    UIManager:setDirty(nil, "ui")
                end,
                cancel_callback = function()
                    UIManager:setDirty(nil, "ui")
                end,
            })








input_dialog = InputDialog:new({
                title = "Enter custom color code",
                input = "#ffffff",
                input_hint = "#FFFFFFAA",
                buttons = {
                    {
                        {
                            text = "Cancel",
                            callback = function()

                            end,
                        },
                        {
                            text = "Save",
                            callback = function()
                                local text = input_dialog:getInputText()

                                if text ~= "" then
                                    if not text:match("^#%x%x%x%x%x%x%x%x$") then
                                        return
                                    end





Notes:chcl(text)


                                    UIManager:close(input_dialog)
                                end
                            end,
                        },
                    },
                },
            })

       UIManager:show(wheel)
     -- UIManager:show(input_dialog)
       --     input_dialog:onShowKeyboard()




      end
    },
    IconButton:new {
      height = 100,
      icon = "zoom.row",
      callback = function()
        self.notesWidget:toggleEraserEnabled()
      end
    },
  }

  self.dialog_frame = FrameContainer:new {
    radius = Size.radius.window,
    bordersize = Size.border.window,
    width = self.width + Size.border.window * 2,
    padding = 0,
    margin = self.margin,
    background = Blitbuffer.COLOR_WHITE,
    VerticalGroup:new {
      align = "left",
      self.title_bar,
      options,
      self.notesWidget,
    }
  }

  self:onDispatcherRegisterActions()

  self.ui.menu:registerToMainMenu(self)

  Input:registerEventAdjustHook(
    function(input, event, hook_params)
      InputListener:eventAdjustmentHook(input, event, hook_params)
    end,
    { name = "InputListener Hook Params" });

  InputListener:setListener(function(event, hook_params)
    self.notesWidget:touchEventListener(event, hook_params)
  end);
  logger.dbg("Notes:init registerd EventAdjustHook");

  logger.dbg("***********************Notes:init ***********************************");
end

function Notes:onClose()
  logger.dbg("Notes:onClose");
  self.isRunning = false
  self.notesWidget.isRunning = false
  UIManager:close(self.notesWidget);
  UIManager:close(self.dialog_frame);
  UIManager:setDirty("ui", "full");
  InputListener:cleanupGestureDetector();
end

local first_start = true
function Notes:onNotesStart()
  UIManager:show(popup)
  self.isRunning = true
  self.notesWidget.isRunning = true
  if self.config.last_opened_dir and first_start then
    first_start = false
    self.currentPath = self.config.last_opened_dir
    self.notesWidget:loadNotes(self.currentPath);
  end
  UIManager:show(self.notesWidget);
  UIManager:show(self.dialog_frame);
  UIManager:setDirty("ui", "full");
  InputListener:setupGestureDetector();
end

function Notes:onRunTest()
  logger.info("Running Tests");
  self.isRunning = true
  self.notesWidget.isRunning = true
  -- self:onNotesStart();
  InputListener:runTest(Input, {});
end

function Notes:onDispatcherRegisterActions()
  Dispatcher:registerAction("show_notes",
    { category = "none", event = "NotesStart", title = _("Show Notes"), general = true })
end

function Notes:addToMainMenu(menu_items)
  menu_items.notes = {
    text = _("Quicky"),
    sorting_hint = "tools",
    -- keep_menu_open = true,
    sub_item_table = {
      {
        text = _("Show Notes"),
        callback = function()
          self:onNotesStart()
        end,
      },
      {
        text = _("New Notes"),
        callback = function()
          self.config.last_opened_dir = nil
          self.currentPath = nil
          self:saveSetting()
          self.notesWidget:newNotes()
          self:onNotesStart()
        end,
      },
      {
        text = _("Load Notes"),
        separator = true,
        callback = function()
          self:onNotesStart()
          self:getLoadNotesDialog(nil)()
        end,
      },
      {
        text = _("Settings"),
        sub_item_table = {
          {
            text = T(_("Templates dir.: %1"), _(self.config.templates_dir or "not set")),
            callback = function()
              local path_chooser;
              path_chooser = PathChooser:new {
                path = home_dir,
                select_file = false,
                onConfirm = function(dirPath)
                  self.config.templates_dir = dirPath;
                  self:saveSetting()
                end,
              }
              UIManager:show(path_chooser)
            end,
          },
          {
            text = _("Finger input"),
            checked_func = function() return self.config.finger_input_enabled end,
            check_callback_updates_menu = true,
            callback = function(touchmenu_instance)
              self.config.finger_input_enabled = not self.config.finger_input_enabled
              self.notesWidget.fingerInputEnabled = self.config.finger_input_enabled
              self:saveSetting()
              touchmenu_instance:updateItems()
            end,
          },
          {
            text = _("Use Finger as Eraser "),
            checked_func = function() return self.config.use_finger_as_eraser end,
            check_callback_updates_menu = true,
            callback = function(touchmenu_instance)
              self.config.use_finger_as_eraser = not self.config.use_finger_as_eraser
              self.notesWidget.useFingerAsEraser = self.config.use_finger_as_eraser
              self:saveSetting()
              touchmenu_instance:updateItems()
            end,
          },
        }
      },
    }
  }
end

function Notes:readSetting()
  local n_settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/notes.lua")
  n_settings:readSetting("notes", {
    last_opened_dir = nil,
    templates_dir = nil,
    finger_input_enabled = true,
    use_finger_as_eraser = false,
  })
  if n_settings.data.notes.finger_input_enabled == nil then
    n_settings.data.notes.finger_input_enabled = true
  end

  if n_settings.data.notes.use_finger_as_eraser == nil then
    n_settings.data.notes.use_finger_as_eraser = false
  end
  return n_settings
end

function Notes:saveSetting()
  self.n_settings:saveSetting("notes", self.config)
  self.n_settings:flush()
end

function Notes:getLoadNotesDialog(dialog)
  return function()
    if dialog then
      UIManager:close(dialog)
    end
    logger.dbg("NW: Loading saved notes");
    self.notesWidget.isRunning = false;
    local path_chooser = PathChooser:new {
      select_file = false,
      path = home_dir,
      onConfirm = function(dirPath)
        logger.dbg("NW: Selected folder ", dirPath);
        self.currentPath = dirPath;
        self.notesWidget.isRunning = true;
        self.notesWidget:loadNotes(self.currentPath);
        self.config.last_opened_dir = self.currentPath;
        self:saveSetting()
      end,
      onCancel = function()
        self.notesWidget.isRunning = true;
      end
    }
    UIManager:show(path_chooser)
  end
end

function Notes:showMenu()
  local dialog
  local saveLoadButtons = {
    {
      text = _("Save"),
      callback = function()
        UIManager:close(dialog)
        logger.dbg("NW: Saving");
        if self.currentPath then
          self.notesWidget:saveToDir(self.currentPath);
        else
          self.notesWidget.isRunning = false;
          local path_chooser = PathChooser:new {
            select_file = false,
            path = home_dir,
            onConfirm = function(dirPath)
              logger.dbg("NW: Selected folder ", dirPath);
              self.currentPath = dirPath;
              self.notesWidget.isRunning = true;
              self.notesWidget:saveToDir(self.currentPath);
              self.config.last_opened_dir = self.currentPath;
              self:saveSetting()
            end,
            onCancel = function()
              self.notesWidget.isRunning = true;
            end
          }
          UIManager:show(path_chooser)
        end
      end,
    },
    {
      text = _("Load"),
      callback = self:getLoadNotesDialog(dialog)
    },
  }

  local selectTemplateButton = {
    {
      text = _("Select template"),
      callback = function()
        UIManager:close(dialog)
        local path_chooser;
        path_chooser = PathChooser:new {
          path = self.config.templates_dir or home_dir,
          select_file = true,
          onConfirm = function(dirPath)
            self.notesWidget:setTemplate(dirPath)
          end,
        }
        UIManager:show(path_chooser)
      end,
    },
  }

  dialog = ButtonDialog:new {
    shrink_unneeded_width = true,
    buttons = { saveLoadButtons, selectTemplateButton },
    anchor = function()
      return self.title_bar.left_button.image.dimen
    end,
    modal = true,
  }
  UIManager:show(dialog)
end

return Notes
