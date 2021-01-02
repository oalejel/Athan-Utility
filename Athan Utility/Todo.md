#  Todo list 
Before updating 
- change "left til " to "until"
- switch siri response accofrding to mohsen
- solar view progress not accurately reflected in first 5th of the day when we are before fajr time 
- test bad input to location search
- show acivity indicator on location search 

- must understand time zone constraint. seems that you can only guarantee ability to use app given coordinates and without wifi IFF the user has the right time zone set on their devices
    - location settings should store the time zone of a location, defaulting to cupertino's 
    - when the user enters the name of a location or gets the name of a location from a coordinate lookup, they will get a resulting time zone to use on the data
    - the time zone that is spit out should be used to adjust the components for the "current date" in the locations gradient view, which will then reconstruct a new offset date 
        - get time zone -> get components from Date() using time zone 
- finish privacy info view

- run with breakpoints everywhere to confirm control flow 
- keep swiftui from updating literally everything when the qibla view rotates. some states should not update everything 
- if custom alert time is longer than interval between two prayers, then use 15 minutse instead
- make sure notifications are always recalcualted when locations are changed
- get timezone of custom locations OR just tell user that the times they see are according to their iphone's timezone
- confirm that entry of coordinates when locations or maps arent allowed still works
- ios 13 color preview should change to current prayer when changing color modes
- find out why main ui is refreshed every second
- fix thing where location re-pans on the first try in custom mode 
- find the use of every .constant() to make sure its intentional
- test everything in dark and light mode, including the non ios 13+ version
- localize widgets
- monitor transition between every prayer time and end of solar midnight
- check that on fresh installation, moon animates
- add siri button to settings
- test on ios 13 
- test on ios 12 
- test on iphone X and Xr and mini 
- test on iphone 7 ios 14, 13, and 12
- add review request after foreground in ios (ensure not widget) is opened for the third time
- athan should play when we open the app within 1 minute of athan starting 
- athan should be stopped whenever we modify any settings 
- user should be able to stop athan playing 
- solar view does not reset when i reopen app after changing time. sus?
- consider switching row buttons to use a longpress gesture that scales intead, that way we wont have incorrect long press measurements that case them to scale unnecessarily

For later 
- dragging up on times table should bring up a monthly times table instead of just tomorrow times. nobody cares about tomorrow's times!
- allow users to add additional locations, and set one of the options as the "my location" for notifications and stuff
- be more efficent with notifications by not wasting notification budget on notifications from earlier in the day 
- consider matching baseline for prayer anme and time left in main interface
- tapping qibla brings it into focus by switching with the moon, and shows a degrees label or something


- get moon to load earlier 
