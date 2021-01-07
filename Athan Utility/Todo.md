#  Todo list 
Before updating 
- fajr athan should be different
- allow ppl who dont use apple mail to send feedback
- loop through every key in strings.swift to confirm localizations match 
- bug where dragging fast gets us stuck in the last simulated pryaer gradient -- found that dragging in the same "current prayer" causes gradient to not change, meaning that the gradiennt view is the culprti
- add donation button
- ensure notifications use the correct minute symbol

- change th to dh in spanish adhan localizations

- MUST check: ensure that notifications run for as long as expected WITHOUT widgets enabled
- fix non-english time left string format

- must understand time zone constraint. seems that you can only guarantee ability to use app given coordinates and without wifi IFF the user has the right time zone set on their devices
- finish privacy info view



- run with breakpoints everywhere to confirm control flow 
- keep swiftui from updating literally everything when the qibla view rotates. some states should not update everything 
- confirm that entry of coordinates when locations or maps arent allowed still works
- ios 13 color preview should change to current prayer when changing color modes
- find out why main ui is refreshed every second
- find the use of every .constant() to make sure its intentional
- test everything in dark and light mode, including the non ios 13+ version
- localize widgets
- check that on fresh installation, moon animates
- add siri button to settings
- test on ios 13 
- test on ios 12 
- test on iphone 7 ios 14, 13, and 12
- add review request after foreground in ios (ensure not widget) is opened for the third time

- user should be able to stop athan playing 


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
