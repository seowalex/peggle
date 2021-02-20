import SwiftUI

struct LevelEditorView: View {
    @ObservedObject var viewModel: LevelEditorViewModel

    @GestureState private var dragState: LevelEditorViewModel.DragState?

    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var levelEditorListIsPresented = false

    var body: some View {
        VStack(spacing: 0) {
            Main()
            Toolbar()
        }
        .navigationBarHidden(true)
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.keyboard),
            alignment: .leading
        )
        .sheet(isPresented: $levelEditorListIsPresented) {
            LevelEditorListView(
                viewModel: viewModel.levelEditorListViewModel,
                level: $viewModel.level,
                fetchLevel: viewModel.fetchLevel
            )
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }

    private func Main() -> some View {
        GeometryReader { geometry in
            ZStack {
                Board()
                    .frame(width: geometry.size.width, height: geometry.size.width)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }

    private func Board() -> some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

            ZStack {
                ForEach(viewModel.pegs, id: \.position) { peg in
                    PegView(peg: peg, frame: frame)
                }

                if let state = dragState {
                    PlaceholderPegView(state: state, frame: frame)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.draggingBoard(position: value.location.applying(normalize))
                    }
                    .onEnded { value in
                        viewModel.dragBoard(position: value.location.applying(normalize))
                    }
            )
        }
    }

    private func PegView(peg: Peg, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        return Image(peg.imageName)
            .resizable()
            .opacity(dragState?.peg == peg ? 0.4 : 1)
            .frame(width: peg.size.applying(denormalize).width, height: peg.size.applying(denormalize).height)
            .position(peg.position.applying(denormalize))
            .onLongPressGesture {
                viewModel.longPressPeg(peg: peg)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.draggingPeg(peg: peg, translation: value.translation.applying(normalize))
                    }
                    .onEnded { value in
                        viewModel.dragPeg(peg: peg, translation: value.translation.applying(normalize))
                    }
            )
    }

    private func PlaceholderPegView(state: LevelEditorViewModel.DragState, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        return Image(state.peg.imageName)
            .resizable()
            .frame(width: state.peg.size.applying(denormalize).width,
                   height: state.peg.size.applying(denormalize).height)
            .position(state.location.applying(denormalize))
            .colorMultiply(state.isValid ? .white : .gray)
    }

    private func Toolbar() -> some View {
        VStack(spacing: 20) {
            Palette()
            ActionBar()
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 10))
        .disabled(dragState != nil)
    }

    private func Palette() -> some View {
        HStack(spacing: 16) {
            PaletteButton(selection: .addPeg(.circle, .blue), imageName: "peg-blue")
            PaletteButton(selection: .addPeg(.circle, .orange), imageName: "peg-orange")
            Spacer()
            PaletteButton(selection: .deletePeg, imageName: "delete")
        }
    }

    private func ActionBar() -> some View {
        HStack(spacing: 16) {
            Button(action: {
                levelEditorListIsPresented = true
            }) {
                Text("Load")
            }
            Button(action: save) {
                Text("Save")
            }
            Button(action: viewModel.reset) {
                Text("Reset")
            }
            TextField("Level Name", text: $viewModel.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            NavigationLink(destination: LazyView {
                LevelPlayerView(viewModel: LevelPlayerViewModel(pegs: viewModel.pegs))
            }) {
                Text("Start")
            }
        }
    }

    private func PaletteButton(selection: LevelEditorViewModel.PaletteSelection, imageName: String) -> some View {
        Button(action: {
            viewModel.paletteSelection = selection
        }) {
            Image(imageName)
                .resizable()
                .frame(width: 100, height: 100)
                .opacity(viewModel.paletteSelection == selection ? 1 : 0.4)
        }
    }

    private func save() {
        do {
            try viewModel.saveLevel()

            alertTitle = "Level saved"
            alertMessage = ""
            alertIsPresented = true
        } catch {
            if let title = (error as? LocalizedError)?.errorDescription,
               let message = (error as? LocalizedError)?.recoverySuggestion {
                alertTitle = title
                alertMessage = message
            } else {
                alertTitle = "Database error"
                alertMessage = "\(error)"
            }

            alertIsPresented = true
        }
    }
}

struct LevelEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LevelEditorView(viewModel: LevelEditorViewModel(database: .empty()))
    }
}