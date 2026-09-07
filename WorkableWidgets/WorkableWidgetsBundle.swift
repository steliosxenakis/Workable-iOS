import WidgetKit
import SwiftUI

@main
struct WorkableWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayGlanceWidget()
        ClockInLiveActivityWidget()
    }
}
