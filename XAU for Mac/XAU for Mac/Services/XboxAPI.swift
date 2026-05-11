import Foundation

struct XboxAPI {
    struct Hosts {
        static let achievements = "achievements.xboxlive.com"
        static let profile = "profile.xboxlive.com"
        static let peopleHub = "peoplehub.xboxlive.com"
        static let titleHub = "titlehub.xboxlive.com"
        static let telemetry = "v20.events.data.microsoft.com"
    }
    
    struct URLs {
        static let gamertag = "https://\(Hosts.profile)/users/me/profile/settings?settings=Gamertag"
        static let profile = "https://\(Hosts.peopleHub)/users/me/people/xuids(%@)/decoration/detail,preferredColor,presenceDetail,multiplayerSummary"
        static let title = "https://\(Hosts.titleHub)/users/xuid(%@)/titles/batch/decoration/GamePass,Achievement,Stats"
        static let titles = "https://\(Hosts.titleHub)/users/xuid(%@)/titles/titleHistory/decoration/Achievement,detail,scid?maxItems=10000"
        static let achievements = "https://\(Hosts.achievements)/users/xuid(%@)/achievements?titleId=%@&maxItems=1000"
        static let achievements360 = "https://\(Hosts.achievements)/users/xuid(%@)/titleachievements?titleId=%@&maxItems=1000"
        static let updateAchievements = "https://\(Hosts.achievements)/users/xuid(%@)/achievements/%@/update"
        static let heartbeat = "https://presence-heartbeat.xboxlive.com/users/xuid(%@)/devices/current/"
    }
    
    struct Auth {
        static let clientId = "000000004C12AE29" // Xbox App for Windows Client ID
        static let scope = "service::user.auth.xboxlive.com::MBI_SSL"
        static let redirectUri = "https://login.live.com/oauth20_desktop.srf"
    }
}
