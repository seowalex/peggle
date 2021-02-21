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
            MainView()
            ToolbarView()
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
                fetchLevel: viewModel.fetchLevel
            )
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }

    private func MainView() -> some View {
        GeometryReader { geometry in
            ZStack {
                BoardView()
                    .frame(width: geometry.size.width, height: geometry.size.width)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }

    private func BoardView() -> some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

            ZStack {
                ForEach(viewModel.pegs, id: \.self) { peg in
                    PegView(peg: peg, frame: frame)
                }

                if let state = dragState {
                    PlaceholderView(state: state, frame: frame)
                }

                if let element = viewModel.selectedElement {
                    ElementTransformView(element: element, frame: frame)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onDrag(position: value.location.applying(normalize))
                    }
                    .onEnded { value in
                        viewModel.onDragEnd(position: value.location.applying(normalize))
                    }
            )
        }
    }

    private func PegView(peg: Peg, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        return Image(peg.imageName)
            .resizable()
            .opacity(dragState?.element === peg ? 0.4 : 1)
            .rotationEffect(.radians(Double(peg.rotation)))
            .frame(width: peg.size.applying(denormalize).width, height: peg.size.applying(denormalize).height)
            .position(peg.position.applying(denormalize))
            .gesture(
                ExclusiveGesture(LongPressGesture(), DragGesture(minimumDistance: 0))
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onDrag(value: value, peg: peg, frame: frame)
                    }
                    .onEnded { value in
                        viewModel.onDragEnd(value: value, peg: peg, frame: frame)
                    }
            )
    }

    private func PlaceholderView(state: LevelEditorViewModel.DragState, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        return Image(state.element.imageName)
            .resizable()
            .rotationEffect(.radians(Double(state.rotation)))
            .frame(width: state.size.applying(denormalize).width,
                   height: state.size.applying(denormalize).height)
            .position(state.position.applying(denormalize))
            .colorMultiply(state.isValid ? .white : .gray)
    }

    private func ElementTransformView(element: Element, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        let position = dragState?.position ?? element.position
        let size = dragState?.size ?? element.size
        let rotation = dragState?.rotation ?? element.rotation

        let topHandle = CGPoint(x: position.x, y: position.y - size.height / 2)
            .rotate(around: position, by: rotation)
        let bottomHandle = CGPoint(x: position.x, y: position.y + size.height / 2)
            .rotate(around: position, by: rotation)
        let leftHandle = CGPoint(x: position.x - size.width / 2, y: position.y)
            .rotate(around: position, by: rotation)
        let rightHandle = CGPoint(x: position.x + size.width / 2, y: position.y)
            .rotate(around: position, by: rotation)

        let rotateHandle = (CGPoint(x: position.x, y: position.y - size.height / 2)
                        - CGVector(dx: 0, dy: min(size.height, 0.1)))
            .rotate(around: position, by: rotation)
        let rotateLine = (CGPoint(x: position.x, y: position.y - size.height / 2)
                        - CGVector(dx: 0, dy: min(size.height / 2, 0.05)))
            .rotate(around: position, by: rotation)

        return ZStack {
            Rectangle()
                .stroke()
                .rotation(.radians(Double(rotation)))
                .frame(width: size.applying(denormalize).width,
                       height: size.applying(denormalize).height)
                .position(position.applying(denormalize))
                .allowsHitTesting(false)
            ResizeHandleView(element: element, frame: frame, position: topHandle)
            ResizeHandleView(element: element, frame: frame, position: bottomHandle)
            ResizeHandleView(element: element, frame: frame, position: leftHandle)
            ResizeHandleView(element: element, frame: frame, position: rightHandle)
            RotateHandleView(element: element, frame: frame, position: rotateHandle)
            Rectangle()
                .rotation(.radians(Double(rotation)))
                .frame(width: 1,
                       height: CGSize(width: size.width, height: min(size.height, 0.1)).applying(denormalize).height)
                .position(rotateLine.applying(denormalize))
                .foregroundColor(.white)
                .allowsHitTesting(false)
        }
    }

    private func ResizeHandleView(element: Element, frame: CGRect, position: CGPoint) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        var size = dragState?.size ?? element.size
        size.width = min(size.width, 0.1)
        size.height = min(size.height, 0.1)

        return Circle()
            .foregroundColor(.white)
            .frame(width: size.applying(denormalize).width / 2,
                   height: size.applying(denormalize).height / 2)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onResize(length: value.location.applying(normalize)
                                                    .distance(to: element.position) * 2,
                                                   element: element)
                    }
                    .onEnded { value in
                        viewModel.onResizeEnd(length: value.location.applying(normalize)
                                                .distance(to: element.position) * 2,
                                              element: element)
                    }
            )
    }

    private func RotateHandleView(element: Element, frame: CGRect, position: CGPoint) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        var size = dragState?.size ?? element.size
        size.width = min(size.width, 0.1)
        size.height = min(size.height, 0.1)

        return Circle()
            .foregroundColor(.white)
            .frame(width: size.applying(denormalize).width / 2,
                   height: size.applying(denormalize).height / 2)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onRotate(position: value.location.applying(normalize), element: element)
                    }
                    .onEnded { value in
                        viewModel.onRotateEnd(position: value.location.applying(normalize), element: element)
                    }
            )
    }

    private func ToolbarView() -> some View {
        VStack(spacing: 20) {
            PaletteView()
            ActionBarView()
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 10))
        .disabled(dragState != nil)
    }

    private func PaletteView() -> some View {
        HStack(spacing: 16) {
            PaletteButtonView(selection: .addPeg(.blue), imageName: "peg-blue")
            PaletteButtonView(selection: .addPeg(.orange), imageName: "peg-orange")
            Spacer()
            PaletteButtonView(selection: .deletePeg, imageName: "delete")
        }
    }

    private func ActionBarView() -> some View {
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

    private func PaletteButtonView(selection: LevelEditorViewModel.PaletteSelection, imageName: String) -> some View {
        Button(action: {
            if case .deletePeg = selection {
                viewModel.selectedElement = nil
            }

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
