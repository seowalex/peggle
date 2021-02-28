import SwiftUI

struct LevelPlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LevelPlayerViewModel

    let parentView: String

    var body: some View {
        VStack(spacing: 0) {
            Main()
            GameBar()
        }
        .navigationTitle(viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.keyboard),
            alignment: .leading
        )
        .alert(isPresented: $viewModel.alertIsPresented) {
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.alertMessage),
                  dismissButton: .default(Text("Return to \(parentView)")) {
                    presentationMode.wrappedValue.dismiss()
                  })
        }
    }

    private func Main() -> some View {
        GeometryReader { geometry in
            ZStack {
                Board()
                    .frame(width: geometry.size.height / 1.4, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }

    private func Board() -> some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxX)

            ZStack {
                ForEach(viewModel.components, id: \.self) { component in
                    Drawable(component: component, frame: frame)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.onDrag(position: value.location.applying(normalize))
                    }
                    .onEnded { value in
                        viewModel.onDragEnd(position: value.location.applying(normalize))
                    }
            )
        }
    }

    private func Drawable(component: RenderComponent, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxX)

        return Image(component.imageName)
            .resizable()
            .rotationEffect(.radians(Double(component.rotation)))
            .frame(width: component.size.applying(denormalize).width,
                   height: component.size.applying(denormalize).height)
            .position(component.position.applying(denormalize))
            .opacity(component.opacity)
            .transition(component.transition)
            .zIndex(component.zIndex)
            .clipped()
    }

    private func GameBar() -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Score")
                    .foregroundColor(.accentColor)
                Text("\(viewModel.gameState.score)")
                    .font(.system(size: 60))
                    .fontWeight(.thin)
            }
            Spacer()
            VStack {
                HStack {
                    Image("ball")
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("\(viewModel.gameState.ballsCount) / 10")
                }
                HStack {
                    Image("peg-orange")
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("\(viewModel.gameState.orangePegsRemainingCount) / \(viewModel.gameState.orangePegsCount)")
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 10))
    }
}

struct LevelPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        LevelPlayerView(viewModel: LevelPlayerViewModel(level: Level(), power: .spaceBlast), parentView: "")
    }
}
