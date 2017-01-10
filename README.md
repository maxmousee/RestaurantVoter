# RestaurantVoter

# How to Run: 
# 1 - Clone repo
# 2 - git submodule update --init
# 3 - run on simulator (or real device)


# - Why I used iOS/SWIFT?
# Swift is fast and can be very optimized by the compiler. It is also the recommended language by Apple for new iOS/macOS projects.
# iOS is also the platform that I have most knowledge.
# I used foursquare API for searching nearby restaurants because I use Swarm and Foursquare a lot.
# it has a simple developer API that is easy to implement, has a native SWIFT lib and it is very complete, showing users 
# ratings and tips for different venues. It is also very fast.
# for the backend, I just needed some simple and fast API that is easy to implement in the given time
# One weakness of this design choice is that I'm limited to iOS 9 or newer [due to SWIFT and Foursquare framework limitations]
# But the app is very fast even on slower devices thanks to simple and clean SWIFT code, very optimized by the compiler using some LLVM
# flags
# Having simple and clean code also makes the app easier to debug
# Todo: Identify users and having different groups voting separately, maybe in the next version ;) 
# How to use: Open the app, look the nearby food venues in the FEATURED section. Click on the desired restaurant, then click VOTE
# The other section of the app show the current votes for nearby restaurants.
