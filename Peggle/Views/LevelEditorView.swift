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
                ForEach(viewModel.elements, id: \.self) { element in
                    ElementView(element: element, frame: frame)
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

    private func ElementView(element: Element, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        return Image(element.imageName)
            .resizable()
            .opacity(dragState?.element === element ? 0.4 : 1)
            .rotationEffect(.radians(Double(element.rotation)))
            .frame(width: element.size.applying(denormalize).width, height: element.size.applying(denormalize).height)
            .position(element.position.applying(denormalize))
            .gesture(
                ExclusiveGesture(LongPressGesture(), DragGesture(minimumDistance: 0))
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onDrag(value: value, element: element, frame: frame)
                    }
                    .onEnded { value in
                        viewModel.onDragEnd(value: value, element: element, frame: frame)
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

        let rotateHandle = (CGPoint(x: position.x, y: position.y - size.height / 2)
                        - CGVector(dx: 0, dy: min(size.height, 0.1)))
            .rotate(around: position, by: rotation)
        let rotateLine = (CGPoint(x: position.x, y: position.y - size.height / 2)
                        - CGVector(dx: 0, dy: min(size.height / 2, 0.05)))
            .rotate(around: position, by: rotation)

        return ZStack {
            Rectangle()
                .rotation(.radians(Double(rotation)))
                .stroke(Color.white)
                .frame(width: size.applying(denormalize).width,
                       height: size.applying(denormalize).height)
                .position(position.applying(denormalize))
                .allowsHitTesting(false)
            ResizeHandleView(element: element, frame: frame, direction: .top)
            ResizeHandleView(element: element, frame: frame, direction: .bottom)
            ResizeHandleView(element: element, frame: frame, direction: .left)
            ResizeHandleView(element: element, frame: frame, direction: .right)
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

    private func ResizeHandleView(element: Element, frame: CGRect,
                                  direction: LevelEditorViewModel.Direction) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        let elementPosition = dragState?.position ?? element.position
        let elementSize = dragState?.size ?? element.size
        let elementRotation = dragState?.rotation ?? element.rotation

        var difference = CGVector.zero
        let size = CGSize(width: min(elementSize.width, Element.minimumSize.width) / 2,
                          height: min(elementSize.height, Element.minimumSize.height) / 2)
        let touchSize = CGSize(width: min(elementSize.width / 2, Element.minimumSize.width),
                               height: min(elementSize.height / 2, Element.minimumSize.height))

        switch direction {
        case .top:
            difference = CGVector(dx: 0, dy: -elementSize.height / 2)
        case .bottom:
            difference = CGVector(dx: 0, dy: elementSize.height / 2)
        case .left:
            difference = CGVector(dx: -elementSize.width / 2, dy: 0)
        case .right:
            difference = CGVector(dx: elementSize.width / 2, dy: 0)
        }

        let position = (elementPosition + difference).rotate(around: elementPosition, by: elementRotation)

        return Rectangle()
            .rotation(.radians(Double(elementRotation)))
            .stroke(Color.clear)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .rotation(.radians(Double(elementRotation)))
                    .foregroundColor(.white)
                    .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
            )
            .frame(width: touchSize.applying(denormalize).width, height: touchSize.applying(denormalize).height)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onResize(position: value.location.applying(normalize),
                                                   element: element, direction: direction)
                    }
                    .onEnded { value in
                        viewModel.onResizeEnd(position: value.location.applying(normalize),
                                              element: element, direction: direction)
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
            PaletteButtonView(selection: .addBlock, imageName: "block")
            Spacer()
            PaletteButtonView(selection: .delete, imageName: "delete")
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
                LevelPlayerView(viewModel: LevelPlayerViewModel(elements: viewModel.elements))
            }) {
                Text("Start")
            }
        }
    }

    private func PaletteButtonView(selection: LevelEditorViewModel.PaletteSelection, imageName: String) -> some View {
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
