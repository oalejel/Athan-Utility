#  Todo list 
Next version priorities 
- confirm that moving to a new location with iphone closed causes both WIDGET and watch to update when using current loc 

- BIG ISUEE: make sure watch does not show tomorrow times if we are on yesterday's isha. reuse today times 
- test if using `transferCurrentComplicationUserInfo` from phone when watch is disconnected causes watch to update complications upon reconnection
- see if only sending updates package to watch when location settings run didset is enough
- have watch tell user to open app to set location
- if user opens watch app before phone app, maybe have watch ask user for permission to set location automatically and THEN tell phone that the location has been set --> only do this if we are still on default settings
        

- improve arabic translation
- watch app should syncrhonize with iphone when the location is changed===> cant have bad complications when user changes loc
- consider issue where location is changed while watch is not connected. will it get the update?
- add stars behind moon during isha

- need an intro screen to prod users to set location on start
- force dividers to be Color.white
- make all ipad sizes somewhat nice and usable
- add detailed descriptions under each calculation method so that they dont seem like black boxes 
- consider changing sunrise to Shurooq so that people are less confused about how its not sunrise for hours


- fajr athan should be different
- allow ppl who dont use apple mail to send feedback
- ensure notifications use the correct minute symbol

- MUST check: ensure that notifications run for as long as expected WITHOUT widgets enabled

- keep swiftui from updating literally everything when the qibla view rotates. some states should not update everything 
- confirm that entry of coordinates when locations or maps arent allowed still works
- ios 13 color preview should change to current prayer when changing color modes
- find out why main ui is refreshed every second
- find the use of every .constant() to make sure its intentional
- test everything in dark and light mode, including the non ios 13+ version
- localize widgets
- check that on fresh installation, moon animates
- add siri button to settings
- add review request after foreground in ios (ensure not widget) is opened for the third time


For later 
- localize siri intents
- allow users to add additional locations, and set one of the options as the "my location" for notifications and stuff
- be more efficent with notifications by not wasting notification budget on notifications from earlier in the day 
- consider matching baseline for prayer anme and time left in main interface
- tapping qibla brings it into focus by switching with the moon, and shows a degrees label or something
- show acivity indicator on location search 
- athan should be stopped whenever we modify any settings 
- consider switching row buttons to use a longpress gesture that scales intead, that way we wont have incorrect long press measurements that case them to scale unnecessarily



- get moon to load earlier 
