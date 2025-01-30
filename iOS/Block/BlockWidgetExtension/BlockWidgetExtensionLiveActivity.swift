//
//  BlockWidgetExtensionLiveActivity.swift
//  BlockWidgetExtension
//
//  Created by Jeffrey Yao on 29/1/2025.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct BlockWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionAttributes.self) {
            context in
            // Lock screen/banner UI goes here
            LiveActivityView(startDate: context.attributes.startDate)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandLeadingView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandTrailingView(startDate: context.attributes.startDate)
                }
            } compactLeading: {
                BlockGlyph()
            } compactTrailing: {
                TimeElapsed(startDate: context.attributes.startDate)
            } minimal: {
                TimeElapsedMinimal(startDate: context.attributes.startDate)
            }
            .keylineTint(Color.blue)
        }
        .supplementalActivityFamilies([.small, .medium])
    }
}

struct SmartStackView: View {
    let startDate: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Block")
                    .bold()
                Text(
                    TimeDataSource<Date>.durationOffset(to: startDate),
                    format: .time(pattern: .hourMinuteSecond)
                )
                .fontWeight(.medium)
                .foregroundStyle(Color.blue)
            }
            Spacer()
            Image("block-icon-glyph")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.blue.gradient)
                .scaledToFit()
                .frame(maxHeight: 28)
                .padding(.trailing, 4)
        }
        .padding()
    }
}

struct MediumView: View {
    let startDate: Date
    
    var body: some View {
        HStack (alignment: .bottom) {
            Circle()
                .foregroundColor(Color.blue.opacity(0.5))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "lock.open.fill")
                        .foregroundColor(Color.blue)
                        .blendMode(.plusLighter)
                        .font(.system(size: 20))
                )
            Spacer()
            Text("Blocked for")
                .padding(.bottom, 3)
                .foregroundStyle(.secondary)
            Text(
                TimeDataSource<Date>.durationOffset(to: startDate),
                format: .time(pattern: .hourMinuteSecond)
            )
            .font(.title)
            .contentTransition(.numericText())
            .frame(maxWidth: 100)
        }
        .padding()
    }
}

struct LiveActivityView: View {
    @Environment(\.activityFamily) var activityFamily
    let startDate: Date
    
    
    var body: some View {
        switch activityFamily {
        case .small:
            SmartStackView(startDate: startDate)
        case .medium:
            MediumView(startDate: startDate)
        @unknown default:
            MediumView(startDate: startDate)
        }

    }
}

struct DynamicIslandLeadingView: View {
    var body: some View {
        // TODO: Use App Intent, refactor Session to use singleton pattern
        Circle()
            .foregroundColor(Color.blue.opacity(0.5))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "lock.open.fill")
                    .foregroundColor(Color.blue)
                    .blendMode(.plusLighter)
                    .font(.system(size: 20))
            )
    }
}

struct DynamicIslandTrailingView: View {
    let startDate: Date

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(
                TimeDataSource<Date>.durationOffset(to: startDate),
                format: .time(pattern: .hourMinuteSecond)
            )
            .font(.title)
            .contentTransition(.numericText())
            .frame(maxHeight: .minimum(50, 50))
            .foregroundStyle(Color.blue)
        }
        .frame(maxHeight: .minimum(50, 50))
    }
}

struct BlockGlyph: View {
    var body: some View {
        HStack(alignment: .center) {
            Image("block-icon-glyph")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.blue.gradient)
                .scaledToFit()
                .frame(maxWidth: 18, maxHeight: 16)
                .padding(.leading, 3)
            Spacer()
        }
    }
}

struct TimeElapsed: View {
    let startDate: Date

    var body: some View {
        Text(
            TimeDataSource<Date>.durationOffset(to: startDate),
            format: .units(
                allowed: [.days, .hours, .minutes], width: .narrow,
                maximumUnitCount: 1, valueLength: 2,
                fractionalPart: .hide(rounded: .down))
        )
        .contentTransition(.numericText())
        .frame(maxWidth: 31.1)
        .foregroundStyle(Color.blue)
    }
}

struct TimeElapsedMinimal: View {
    let startDate: Date

    var body: some View {
        HStack(alignment: .center) {
            Text(
                TimeDataSource<Date>.durationOffset(to: startDate),
                format: .units(
                    allowed: [.days, .hours, .minutes], width: .narrow,
                    maximumUnitCount: 1,
                    fractionalPart: .hide(rounded: .down))
            )
            .contentTransition(.numericText())
            .foregroundStyle(Color.blue)
        }
    }
}

#if DEBUG
    #Preview(
        "Live Activity", as: .content,
        using: SessionAttributes(startDate: Date().addingTimeInterval(-55))  // -55s from current time
    ) {
        BlockWidgetExtensionLiveActivity()
    } contentStates: {
        SessionAttributes.ContentState(isActive: true)
    }
#endif
