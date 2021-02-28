import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var settings: GameSettings
    @ObservedObject var viewModel: LevelSelectViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)

            if viewModel.levels.isEmpty {
                EmptyLevelsList()
            } else {
                LevelsList(frame: frame)
            }
        }
        .navigationTitle("Level Select")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Text("Powerup:")
                    Picker(settings.power.rawValue, selection: $settings.power) {
                        ForEach(PowerComponent.Power.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }

    private func EmptyLevelsList() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.bin")
                .font(.system(size: 60))
            Text("No levels found")
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .foregroundColor(.secondary)
    }

    private func LevelsList(frame: CGRect) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(viewModel.levels, id: \.name) { level in
                    LevelTileView(level: level, frame: frame)
                }
            }
            .padding([.top, .bottom])
        }
    }

    private func LevelTileView(level: Level, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX / 4, y: frame.maxX / 4)

        return NavigationLink(destination: LazyView {
            LevelPlayerView(viewModel: LevelPlayerViewModel(level: level, power: settings.power))
        }) {
            VStack(spacing: 16) {
                ZStack {
                    ForEach(level.elements, id: \.self) { element in
                        Image(element.imageName)
                            .resizable()
                            .rotationEffect(.radians(Double(element.rotation)))
                            .frame(width: element.size.applying(denormalize).width,
                                   height: element.size.applying(denormalize).height)
                            .position(element.position.applying(denormalize))
                            .clipped()
                    }
                }
                .frame(width: frame.maxX / 4, height: frame.maxX / 4)
                .background(
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: frame.maxX / 4, height: frame.maxX / 4, alignment: .leading)
                        .clipped()
                )
                Text(level.name)
                    .lineLimit(1)
            }
        }
    }
}

struct LevelSelectView_Previews: PreviewProvider {
    static var previews: some View {
        LevelSelectView(viewModel: LevelSelectViewModel(database: .empty()))
    }
}
