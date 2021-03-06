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
                NoLevelsView()
            } else {
                LevelsView(frame: frame)
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
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                .opacity(0.2)
                .blur(radius: 10)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        )
    }

    private func NoLevelsView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.bin")
                .font(.system(size: 60))
            Text("No levels found")
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .foregroundColor(.secondary)
    }

    private func LevelsView(frame: CGRect) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(viewModel.levels, id: \.name) { level in
                    NavigationLink(destination: LazyView {
                        LevelPlayerView(viewModel: LevelPlayerViewModel(level: level, power: settings.power),
                                        parentView: "Level Select")
                    }) {
                        VStack(spacing: 16) {
                            PreviewView(elements: level.elements, frame: frame)
                            Text(level.name)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding([.top, .bottom])
        }
    }

    private func PreviewView(elements: [Element], frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX / 4, y: frame.maxX / 4)

        return ZStack {
            ForEach(elements, id: \.self) { element in
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
    }
}

struct LevelSelectView_Previews: PreviewProvider {
    static var previews: some View {
        LevelSelectView(viewModel: LevelSelectViewModel(database: .empty()))
    }
}
