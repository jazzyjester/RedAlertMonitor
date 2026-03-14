.PHONY: build app run install clean debug

APP_NAME     = RedAlertMonitor
PLIST        = Sources/RedAlertMonitor/Resources/Info.plist
DEMO_JSON    = demo_alert.json

# ── Release build + .app bundle ─────────────────────────────────────────────

build:
	swift build -c release

app: build
	@rm -rf $(APP_NAME).app
	@mkdir -p $(APP_NAME).app/Contents/MacOS
	@mkdir -p $(APP_NAME).app/Contents/Resources
	@cp .build/release/$(APP_NAME)   $(APP_NAME).app/Contents/MacOS/
	@cp $(PLIST)                     $(APP_NAME).app/Contents/
	@[ -f $(DEMO_JSON) ]   && cp $(DEMO_JSON)   $(APP_NAME).app/Contents/Resources/ || true
	@[ -f AppIcon.icns ]   && cp AppIcon.icns   $(APP_NAME).app/Contents/Resources/ || true
	@echo "Built $(APP_NAME).app"

run: app
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.3
	@open $(APP_NAME).app

install: app
	@cp -r $(APP_NAME).app /Applications/
	@echo "Installed /Applications/$(APP_NAME).app"

# ── Debug build (faster compile, no optimisations) ──────────────────────────

debug:
	swift build
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.3
	@rm -rf $(APP_NAME).app
	@mkdir -p $(APP_NAME).app/Contents/MacOS
	@mkdir -p $(APP_NAME).app/Contents/Resources
	@cp .build/debug/$(APP_NAME)     $(APP_NAME).app/Contents/MacOS/
	@cp $(PLIST)                     $(APP_NAME).app/Contents/
	@[ -f $(DEMO_JSON) ]   && cp $(DEMO_JSON)   $(APP_NAME).app/Contents/Resources/ || true
	@[ -f AppIcon.icns ]   && cp AppIcon.icns   $(APP_NAME).app/Contents/Resources/ || true
	@open $(APP_NAME).app

# ── Cleanup ──────────────────────────────────────────────────────────────────

clean:
	@rm -rf .build $(APP_NAME).app
	@echo "Cleaned"
