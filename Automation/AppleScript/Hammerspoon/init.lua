function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.launched) then
        if (appName == "Royal TSX") then
            local applescriptCode = [[
                tell application "Royal TSX"
                    -- Replace 'Terminal' with the name of the connection you want to open
                    set targetName to "Terminal"
                    
                    -- Get the ID of the connection whose name matches the target name
                    set conIds to id of every connection whose name is equal to targetName
                    
                    -- If there's a matching ID, connect
                    if (count of conIds) > 0 then
                        set conId to item 1 of conIds
                        connect conId
                    else
                        display dialog "No connection found with the name: " & targetName
                    end if
                end tell
            ]]
            local ok, result = hs.osascript.applescript(applescriptCode)
            if not ok then
                hs.notify.show("AppleScript Error", "Failed to run the script", result)
            end
        end
    end
end

appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()
